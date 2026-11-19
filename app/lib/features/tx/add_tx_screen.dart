import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// تسجيل دين / سداد / مرتجع / خصم / سداد بعملة أخرى — 3 ضغطات: المبلغ ← حفظ
class AddTxScreen extends ConsumerStatefulWidget {
  const AddTxScreen({super.key, required this.customerId, required this.kind});
  final String customerId;
  final TxKind kind;
  @override
  ConsumerState<AddTxScreen> createState() => _AddTxScreenState();
}

class _AddTxScreenState extends ConsumerState<AddTxScreen> {
  String _amount = '';
  String? _currency; // عملة الدين/الحركة
  String? _paidCurrency; // للسداد بعملة أخرى
  final _rate = TextEditingController();
  final _desc = TextEditingController();
  final _invoice = TextEditingController();
  DateTime? _due;
  bool _busy = false;

  bool get _fx => widget.kind == TxKind.paymentFx;
  bool get _isDebt => widget.kind == TxKind.debt;

  void _onKey(String k) => setState(() {
        if (k == 'del') {
          if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
        } else if (_amount.length < 12) {
          if (_amount.isEmpty && (k == '0' || k == '000')) return;
          _amount += k;
        }
      });

  Decimal? get _entered => _amount.isEmpty ? null : Decimal.parse(_amount);

  /// المبلغ الذي ينقص من الدين (بعملة الدين)
  Decimal? _applied(Currency debtCur) {
    final paid = _entered;
    if (!_fx) return paid;
    final rate = MoneyFormat.parse(_rate.text);
    if (paid == null || rate == null || rate == Decimal.zero) return null;
    final v = (paid / rate).toDecimal(scaleOnInfinitePrecision: debtCur.decimals + 2);
    return Decimal.parse(v.toStringAsFixed(debtCur.decimals));
  }

  Future<void> _save(Customer c, Map<String, CurrencyBalance> balances) async {
    final w = ref.read(sessionProvider);
    if (!w.canWrite) return showError(context, w.writeBlockedError);
    final cur = _currency ?? c.defaultCurrency;
    final applied = _applied(Currency.of(cur));
    if (applied == null || applied <= Decimal.zero) return showError(context, 'x: أدخل المبلغ${_fx ? ' والسعر' : ''}');
    if (_isDebt && Ledger.exceedsLimit(c, balances, applied, cur)) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تجاوز سقف الدين'),
          content: Text('هذا الدين يتجاوز السقف المحدد لـ ${c.name}. هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('متابعة')),
          ],
        ),
      );
      if (go != true) return;
    }
    setState(() => _busy = true);
    try {
      final tx = await repoOf(ref).addTx(
        customerId: c.id,
        kind: widget.kind,
        amount: applied,
        currency: cur,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        invoiceNo: _invoice.text.trim().isEmpty ? null : _invoice.text.trim(),
        dueDate: _isDebt ? _due : null,
        fxPaidAmount: _fx ? _entered : null,
        fxPaidCurrency: _fx ? _paidCurrency : null,
        fxRate: _fx ? MoneyFormat.parse(_rate.text) : null,
      );
      ref.read(sessionProvider).kick();
      // بعد الحفظ: معاينة الإشعار مع زر المشاركة (واتساب وغيره)
      if (mounted) context.pushReplacement('/customers/${c.id}/receipt/${tx.id}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(sessionProvider).session!;
    final c = ref.watch(customerProvider(widget.customerId)).valueOrNull;
    final txs = ref.watch(customerTxsProvider(widget.customerId)).valueOrNull ?? const [];
    final f = ref.watch(moneyFormatProvider);
    if (c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final balances = Ledger.balances(txs);
    final cur = _currency ?? c.defaultCurrency;
    final others = w.enabledCurrencies.where((x) => x != cur).toList();
    _paidCurrency ??= others.isEmpty ? null : others.first;
    final applied = _applied(Currency.of(cur));
    final before = balances[cur]?.balance ?? Decimal.zero;
    final after = applied == null ? before : (widget.kind.isDebit ? before + applied : before - applied);
    final color = widget.kind.isDebit ? context.ajil.debt : context.ajil.paid;
    final displayCur = _fx ? (_paidCurrency ?? cur) : cur;

    // لوحة الأرقام تظهر فقط عند إدخال المبلغ؛ إذا كان المؤشر في حقل نصي (الوصف…) تختفي ويظهر كيبورد الجوال
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: context.ajil.surface,
      appBar: AjilHeader(close: true, title: 'تسجيل ${widget.kind.labelAr}', subtitle: '${c.name} · ${w.branch.name}'),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: Text(
                  _amount.isEmpty ? '0' : f.amount(_entered!, displayCur),
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w600, color: color, height: 1.2),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _fx
                  ? Text('المدفوع بـ ${Currency.of(displayCur).nameAr}', style: TextStyle(fontSize: 13, color: context.ajil.textMuted))
                  : CurrencyToggle(currencies: w.enabledCurrencies, value: cur, onChanged: (v) => setState(() => _currency = v)),
            ),
            if (!_fx && cur == c.defaultCurrency && w.enabledCurrencies.length > 1) ...[
              const SizedBox(height: 12),
              Center(
                child: Text('العملة الافتراضية للزبون: ${Currency.of(c.defaultCurrency).nameAr}',
                    style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
              ),
            ],
            if (_fx) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text('الدين بعملة', style: TextStyle(fontSize: 13, color: context.ajil.textSoft))),
                CurrencyToggle(
                    currencies: w.enabledCurrencies,
                    value: cur,
                    onChanged: (v) => setState(() {
                          _currency = v;
                          _paidCurrency = w.enabledCurrencies.firstWhere((x) => x != v, orElse: () => v);
                        })),
              ]),
              const SizedBox(height: 10),
              LabeledField(
                label: 'سعر الصرف المتفق عليه',
                helper: '1 ${Currency.of(cur).symbolAr} = كم ${Currency.of(_paidCurrency ?? '').symbolAr}',
                child: TextField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (applied != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('ينقص الدين: ${f.amount(applied, cur, withSymbol: true)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.ajil.paid)),
                ),
            ],
            const SizedBox(height: 16),
            LabeledField(
              label: 'الوصف (اختياري)',
              child: TextField(controller: _desc, style: const TextStyle(fontSize: 15), textInputAction: TextInputAction.done),
            ),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_isDebt) ...[
                Expanded(
                  child: LabeledField(
                    label: 'رقم الفاتورة',
                    child: TextField(
                      controller: _invoice,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(hintText: 'تلقائي'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: LabeledField(
                  label: 'التاريخ',
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(color: context.ajil.background, borderRadius: BorderRadius.circular(12)),
                    child: Text('اليوم ${intl.DateFormat('h:mm a', 'ar').format(now)}', style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ]),
            if (_isDebt) ...[
              const SizedBox(height: 10),
              Text('موعد السداد (اختياري — للتنبيه)', style: TextStyle(fontSize: 13, color: context.ajil.textSoft)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (label, date) in [
                  ('بدون موعد', null),
                  ('غداً', now.add(const Duration(days: 1))),
                  ('بعد أسبوع', now.add(const Duration(days: 7))),
                  ('آخر الشهر', DateTime(now.year, now.month + 1, 0)),
                ])
                  PillChip(
                    label: label,
                    selected: (_due == null && date == null) || (_due != null && date != null && _sameDay(_due!, date)),
                    onTap: () => setState(() => _due = date),
                  ),
                PillChip(
                  label: _due == null || _isPreset(_due!) ? 'تاريخ…' : intl.DateFormat('yyyy/MM/dd').format(_due!),
                  selected: _due != null && !_isPreset(_due!),
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: _due ?? now.add(const Duration(days: 1)));
                    if (d != null) setState(() => _due = d);
                  },
                ),
              ]),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: context.ajil.background, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Text('الرصيد بعد العملية', style: TextStyle(fontSize: 14, color: context.ajil.textMuted))),
                MoneyText(after, cur, size: 14),
              ]),
            ),
          ]),
        ),
        Container(
          color: context.ajil.background,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: Column(children: [
              if (!typing) ...[AmountKeypad(onKey: _onKey), const SizedBox(height: 12)],
              FilledButton(
                onPressed: _busy ? null : () => _save(c, balances),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                child: Text(switch (widget.kind) { TxKind.debt => 'حفظ الدين', TxKind.payment => 'حفظ السداد', _ => 'حفظ ${widget.kind.labelAr}' }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  bool _isPreset(DateTime d) {
    final now = DateTime.now();
    return [now.add(const Duration(days: 1)), now.add(const Duration(days: 7)), DateTime(now.year, now.month + 1, 0)]
        .any((x) => _sameDay(x, d));
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
