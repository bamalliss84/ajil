import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../data/local/mappers.dart';
import '../../data/repository.dart';
import '../../services/statement_pdf.dart';
import '../../services/whatsapp.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// كشف حساب الزبون: رصيد لكل عملة، إجمالي/تحليلي، حالة المزامنة لكل حركة، الوعد، الإلغاء
class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, required this.customerId});
  final String customerId;
  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  bool _detailed = true;
  String? _currency;
  DateTimeRange? _range;
  static final _dt = intl.DateFormat('d MMM · h:mm a', 'ar');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final customer = ref.watch(customerProvider(widget.customerId)).valueOrNull;
    final txs = ref.watch(customerTxsProvider(widget.customerId)).valueOrNull ?? const [];
    final promises = ref.watch(promisesProvider(widget.customerId)).valueOrNull ?? const [];
    final f = ref.watch(moneyFormatProvider);
    if (customer == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final balances = Ledger.balances(txs);
    final st = Statement.build(customer, txs, from: _range?.start, to: _range?.end.add(const Duration(days: 1)), onlyCurrency: _currency);
    final promise = promises.isEmpty ? null : promises.first;
    final cwb = CustomerWithBalance(customer, balances, false, null);
    final voided = Ledger.voidedIds(txs);

    return Scaffold(
      body: Column(children: [
        Material(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.headerBorder))),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.chevron_right_rounded, size: 30),
                      tooltip: 'رجوع',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                      if (customer.phone != null)
                        Text(customer.phone!,
                            textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
                    ]),
                  ),
                  SquareIconButton(
                    icon: Icons.calendar_today_outlined,
                    tooltip: 'تسجيل وعد سداد',
                    color: AjilColors.pendingIcon,
                    onPressed: () => context.push('/customers/${customer.id}/promise'),
                  ),
                  const SizedBox(width: 10),
                  SquareIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'إرسال الرصيد عبر واتساب',
                    color: AjilColors.paid,
                    onPressed: customer.phone == null ? null : () => Whatsapp.remind(ref, cwb),
                  ),
                  const SizedBox(width: 10),
                  SquareIconButton(
                    icon: Icons.description_outlined,
                    tooltip: 'الكشف والمزيد',
                    onPressed: () => _more(context, customer, st, balances, promise),
                  ),
                ]),
                const SizedBox(height: 14),
                if (balances.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AjilColors.background, borderRadius: BorderRadius.circular(12)),
                    child: const Text('لا توجد حركات بعد — سجّل أول دين أو سداد', textAlign: TextAlign.center,
                        style: TextStyle(color: AjilColors.textMuted, fontSize: 14)),
                  )
                else
                  Row(children: [
                    for (final b in balances.values) ...[
                      Expanded(child: _BalanceCard(b)),
                      if (b != balances.values.last) const SizedBox(width: 10),
                    ],
                  ]),
                if (promise != null) ...[
                  const SizedBox(height: 14),
                  InfoStrip(
                    icon: Icons.calendar_today_outlined,
                    bg: AjilColors.pendingBg,
                    fg: AjilColors.pendingText,
                    text: '${promise.isOverdue(DateTime.now()) ? 'وعد متأخر' : 'وعد بالسداد'}: ${intl.DateFormat('EEEE d MMMM', 'ar').format(promise.promisedDate)}'
                        '${promise.amount == null ? '' : ' · ${f.amount(promise.amount!, promise.currency ?? customer.defaultCurrency, withSymbol: true)}'}',
                    action: ('تعديل', () => context.push('/customers/${customer.id}/promise')),
                  ),
                ],
                const SizedBox(height: 14),
                AjilSegmented<bool>(
                  options: const [(false, 'إجمالي'), (true, 'تحليلي')],
                  value: _detailed,
                  onChanged: (v) => setState(() => _detailed = v),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: _detailed
              ? _Detailed(st: st, voided: voided, onTap: (t) => _txActions(context, t, voided, customer, balances), dt: _dt, range: _range)
              : _Summary(st: st),
        ),
        if (s.canWrite && customer.status == CustomerStatus.active)
          Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AjilColors.headerBorder))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
              child: DebtPayButtons(
                icons: false,
                onDebt: () => context.push('/customers/${customer.id}/tx/debt'),
                onPay: () => context.push('/customers/${customer.id}/tx/payment'),
              ),
            ),
          ),
      ]),
    );
  }

  /// قائمة «المزيد»: الكشف PDF/طباعة، الفترة والعملة، الحركات الأخرى، التعديل، رسائل الرصيد
  Future<void> _more(BuildContext context, Customer customer, Statement st, Map<String, CurrencyBalance> balances, PaymentPromise? promise) async {
    final s = ref.read(sessionProvider);
    final f = ref.read(moneyFormatProvider);
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('مشاركة الكشف PDF'), onTap: () => Navigator.pop(ctx, 'pdf')),
            ListTile(leading: const Icon(Icons.print_outlined), title: const Text('طباعة الكشف'), onTap: () => Navigator.pop(ctx, 'print')),
            ListTile(
              leading: Icon(Icons.date_range_outlined, color: _range == null ? null : AjilColors.primary),
              title: const Text('فترة الكشف'),
              subtitle: Text(_range == null
                  ? 'كل الحركات'
                  : '${intl.DateFormat('yyyy/MM/dd').format(_range!.start)} — ${intl.DateFormat('yyyy/MM/dd').format(_range!.end)}'),
              onTap: () => Navigator.pop(ctx, 'range'),
            ),
            if (balances.length > 1)
              ListTile(
                leading: Icon(Icons.currency_exchange, color: _currency == null ? null : AjilColors.primary),
                title: const Text('العملة'),
                subtitle: Text(_currency == null ? 'كل العملات' : Currency.of(_currency!).nameAr),
                onTap: () => Navigator.pop(ctx, 'currency'),
              ),
            if (s.canWrite && customer.status == CustomerStatus.active) ...[
              const Divider(),
              for (final k in [TxKind.paymentFx, TxKind.returned, TxKind.discount])
                ListTile(leading: const Icon(Icons.add_circle_outline), title: Text(k.labelAr), onTap: () => Navigator.pop(ctx, 'tx:${k.wire}')),
            ],
            const Divider(),
            if (customer.phone != null)
              ListTile(leading: const Icon(Icons.call_outlined), title: const Text('اتصال'), onTap: () => Navigator.pop(ctx, 'call')),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('تعديل البيانات'), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(leading: const Icon(Icons.mark_chat_read_outlined), title: const Text('رسائل الرصيد المرسلة'), onTap: () => Navigator.pop(ctx, 'notices')),
            if (promise != null)
              ListTile(
                leading: const Icon(Icons.event_busy_outlined, color: AjilColors.pendingText),
                title: const Text('إلغاء الوعد'),
                onTap: () => Navigator.pop(ctx, 'cancel_promise'),
              ),
          ]),
        ),
      ),
    );
    if (v == null || !context.mounted) return;
    if (v.startsWith('tx:')) {
      context.push('/customers/${customer.id}/tx/${v.substring(3)}');
      return;
    }
    switch (v) {
      case 'pdf':
      case 'print':
        final bytes = await StatementPdf.statement(session: s.session!, st: st, f: f, detailed: _detailed);
        if (s.pending > 0 && context.mounted) {
          showOk(context, 'تنبيه: توجد حركات غير متزامنة — الرصيد محسوب من هذا الجوال');
        }
        v == 'pdf' ? await StatementPdf.share(bytes, 'كشف-${customer.name}.pdf') : await StatementPdf.printDoc(bytes);
      case 'range':
        final r = await showDateRangePicker(context: context, firstDate: DateTime(2015), lastDate: DateTime.now(), initialDateRange: _range);
        setState(() => _range = r);
      case 'currency':
        final c = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(title: const Text('كل العملات'), onTap: () => Navigator.pop(ctx, '*')),
              for (final c in balances.keys) ListTile(title: Text(Currency.of(c).nameAr), onTap: () => Navigator.pop(ctx, c)),
            ]),
          ),
        );
        if (c != null) setState(() => _currency = c == '*' ? null : c);
      case 'call':
        await Whatsapp.call(customer.phone!);
      case 'edit':
        if (context.mounted) context.push('/customers/${customer.id}/edit');
      case 'cancel_promise':
        await repoOf(ref).setPromiseStatus(promise!.id, PromiseStatus.cancelled);
        s.kick();
      case 'notices':
        final rows = await repoOf(ref).noticesOf(customer.id);
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(shrinkWrap: true, children: [
              const ListTile(title: Text('رسائل الرصيد المرسلة', style: TextStyle(fontWeight: FontWeight.w600))),
              if (rows.isEmpty) const ListTile(title: Text('لم تُرسل له رسالة رصيد بعد')),
              for (final n in rows)
                ListTile(
                  leading: const Icon(Icons.mark_chat_read_outlined, color: AjilColors.paid),
                  title: Text(BalanceNotices.balancesText(n.balanceMap, f)),
                  subtitle: Text('الرصيد حتى ${BalanceNotices.date(n.asOf, f)} · أُرسلت ${intl.DateFormat('yyyy/MM/dd HH:mm').format(n.sentAt)}'),
                ),
            ]),
          ),
        );
    }
  }

  Future<void> _txActions(BuildContext context, LedgerTx t, Set<String> voided, Customer c, Map<String, CurrencyBalance> balances) async {
    final s = ref.read(sessionProvider);
    final w = s.session!;
    final denied = Ledger.canVoid(t, isOwner: w.isOwner, userId: w.appUserId, alreadyVoided: voided);
    final f = ref.read(moneyFormatProvider);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text('${t.kind.labelAr} · ${f.amount(t.amount, t.currency, withSymbol: true)}'),
            subtitle: Text([t.description, t.invoiceNo, if (t.syncError != null) 'سبب الرفض: ${t.syncError}']
                .whereType<String>()
                .join(' · ')),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: AjilColors.primary),
            title: const Text('عرض الإشعار ومشاركته'),
            subtitle: const Text('PDF أو صورة عبر واتساب وغيره، أو طباعة'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/customers/${c.id}/receipt/${t.id}');
            },
          ),
          if (t.sync == SyncState.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('إعادة المحاولة'),
              onTap: () {
                Navigator.pop(ctx);
                repoOf(ref).retry(t.id).then((_) => s.kick());
              },
            ),
          if (s.canWrite && t.sync != SyncState.failed)
            ListTile(
              enabled: denied == null,
              leading: const Icon(Icons.undo_rounded, color: AjilColors.debt),
              title: const Text('إلغاء الحركة (قيد عكسي)'),
              subtitle: denied == null ? null : Text(denied),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await _askReason(context);
                if (reason == null) return;
                try {
                  final v = await repoOf(ref).voidTx(t, reason, alreadyVoided: voided);
                  s.kick();
                  if (context.mounted) context.push('/customers/${c.id}/receipt/${v.id}');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
        ]),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الإلغاء'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'مثل: خطأ في المبلغ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          FilledButton(
            onPressed: () => c.text.trim().isEmpty ? null : Navigator.pop(ctx, c.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AjilColors.debt, minimumSize: const Size(90, 44)),
            child: const Text('إلغاء الحركة'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard(this.b);
  final CurrencyBalance b;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final owes = b.balance > Decimal.zero;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: owes ? AjilColors.debtBg : AjilColors.paidBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المتبقي · ${Currency.of(b.currency).nameAr}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: owes ? AjilColors.debtText : AjilColors.paidDark)),
        const SizedBox(height: 2),
        Text(f.amount(b.balance, b.currency),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: owes ? AjilColors.debt : AjilColors.paid)),
        const SizedBox(height: 2),
        Text('ديون ${f.amount(b.debit, b.currency)} · مسدد ${f.amount(b.credit, b.currency)}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: owes ? AjilColors.debtText : AjilColors.paidDark)),
      ]),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.st});
  final Statement st;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final cs in st.byCurrency.values)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(Currency.of(cs.currency).nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Divider(height: 20),
              if (st.from != null) _kv('رصيد ما قبل الفترة', f.amount(cs.openingBalance, cs.currency, withSymbol: true)),
              _kv('إجمالي الديون', f.amount(cs.debit, cs.currency, withSymbol: true)),
              _kv('إجمالي المسدد', f.amount(cs.credit, cs.currency, withSymbol: true)),
              _kv('الرصيد المتبقي', f.amount(cs.closingBalance, cs.currency, withSymbol: true), bold: true),
              _kv('عدد الحركات', '${cs.lines.length}'),
            ]),
          ),
        ),
    ]);
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: AjilColors.textMuted))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? AjilColors.debt : null)),
        ]),
      );
}

class _Detailed extends ConsumerWidget {
  const _Detailed({required this.st, required this.voided, required this.onTap, required this.dt, this.range});
  final Statement st;
  final Set<String> voided;
  final void Function(LedgerTx) onTap;
  final intl.DateFormat dt;
  final DateTimeRange? range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final sections = st.byCurrency.values.toList();
    if (sections.isEmpty) {
      return const Center(child: Text('لا توجد حركات', style: TextStyle(color: AjilColors.textMuted)));
    }
    return ListView(padding: EdgeInsets.zero, children: [
      for (final cs in sections) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            Expanded(
              child: Text(
                '${Currency.of(cs.currency).nameAr} · ${range == null ? 'الأحدث أولاً' : '${intl.DateFormat('d/M').format(range!.start)}–${intl.DateFormat('d/M').format(range!.end)}'}',
                style: const TextStyle(color: AjilColors.textMuted, fontSize: 13),
              ),
            ),
            const Text('الرصيد', style: TextStyle(color: AjilColors.textMuted, fontSize: 13)),
          ]),
        ),
        for (final l in cs.lines)
          InkWell(
            onTap: () => onTap(l.tx),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AjilColors.divider))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                _KindBadge(l.tx.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_signedText(f.amount(l.signed.abs(), cs.currency), l.signed),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: l.tx.kind == TxKind.opening || l.tx.kind == TxKind.voided
                              ? AjilColors.text
                              : (l.signed > Decimal.zero ? AjilColors.debt : AjilColors.paid),
                          decoration: l.isVoided ? TextDecoration.lineThrough : null,
                        )),
                    Text(
                      [l.tx.description ?? l.tx.voidReason, dt.format(l.tx.createdAt), l.tx.invoiceNo, if (l.isVoided) 'ملغاة']
                          .whereType<String>()
                          .join(' · '),
                      style: const TextStyle(fontSize: 12, color: AjilColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(f.amount(l.runningBalance, cs.currency), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  SyncBadge(l.tx.sync),
                ]),
              ]),
            ),
          ),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

/// «+ 12,500» للدين و«− 20,000» للسداد كما في التصميم (الإشارة يسار الرقم)
String _signedText(String amount, Decimal signed) => signed < Decimal.zero ? '− $amount' : '+ $amount';

class _KindBadge extends StatelessWidget {
  const _KindBadge(this.kind);
  final TxKind kind;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      TxKind.debt => (AjilColors.debtBg, AjilColors.debtTag),
      TxKind.opening => (AjilColors.infoBg, AjilColors.infoText),
      TxKind.voided => (AjilColors.divider, AjilColors.textSoft),
      _ => (AjilColors.paidBg, AjilColors.paidDark),
    };
    final label = switch (kind) {
      TxKind.opening => 'افتتاحي',
      TxKind.paymentFx => 'سداد عملة',
      TxKind.discount => 'خصم',
      TxKind.voided => 'إلغاء',
      _ => kind.labelAr,
    };
    return SizedBox(width: 64, child: TypeBadge(label, bg: bg, fg: fg));
  }
}
