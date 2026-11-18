import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../services/statement_links.dart';
import '../../services/whatsapp.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// إرسال الأرصدة لكل الزبائن حتى تاريخ معيّن.
/// الإرسال من واتساب صاحب البقالة بضغطة لكل زبون (مجاني ولا يعرّض رقمه للحظر)،
/// والتطبيق يرتب الدور ويحفظ التقدم ويسجل من استلم.
class BalanceNoticesScreen extends ConsumerStatefulWidget {
  const BalanceNoticesScreen({super.key});
  @override
  ConsumerState<BalanceNoticesScreen> createState() => _BalanceNoticesScreenState();
}

enum _Phase { loading, setup, sending, done }

class _BalanceNoticesScreenState extends ConsumerState<BalanceNoticesScreen> with WidgetsBindingObserver {
  _Phase _phase = _Phase.loading;

  // الإعداد
  DateTime _asOf = DateTime.now();
  bool _debtorsOnly = true;
  final _min = TextEditingController();
  String? _currency;
  int? _skipDays = 7;
  final _tpl = TextEditingController();
  bool _saveTemplate = false;
  NoticeSelection? _sel;
  bool _selecting = false;

  // الإرسال
  NoticeBatch? _batch;
  Map<String, NoticeRecipient> _recipients = {};
  bool _awaitingConfirm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _min.dispose();
    _tpl.dispose();
    super.dispose();
  }

  /// عند الرجوع من واتساب نسأل: هل أُرسلت؟
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingConfirm && mounted) setState(() {});
  }

  bool get _allowed {
    final s = ref.read(sessionProvider);
    return s.session!.isOwner || s.settings?['employees_can_send_notices'] == true;
  }

  Future<void> _init() async {
    final s = ref.read(sessionProvider);
    final repo = repoOf(ref);
    _tpl.text = (s.settings?['balance_notice_template'] as String?) ?? BalanceNotices.defaultTemplate;
    await repo.refreshNotices(s.api);
    final b = await repo.loadNoticeBatch();
    if (b != null && !b.finished) {
      _batch = b;
      _recipients = await repo.recipientsOf(b);
      if (mounted) setState(() => _phase = _Phase.sending);
      return;
    }
    if (b != null) await repo.clearNoticeBatch();
    if (mounted) setState(() => _phase = _Phase.setup);
    await _reselect();
  }

  NoticeFilter get _filter => NoticeFilter(
        debtorsOnly: _debtorsOnly,
        minAmount: MoneyFormat.parse(_min.text),
        currency: _currency,
        skipSentWithinDays: _skipDays,
      );

  Future<void> _reselect() async {
    setState(() => _selecting = true);
    try {
      final sel = await repoOf(ref).selectForNotices(_asOf, _filter);
      if (mounted) setState(() => _sel = sel);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _start() async {
    final sel = _sel;
    if (sel == null || sel.recipients.isEmpty) return;
    final s = ref.read(sessionProvider);
    final tpl = _tpl.text.trim().isEmpty ? BalanceNotices.defaultTemplate : _tpl.text.trim();
    if (_saveTemplate && s.session!.isOwner) {
      try {
        await s.api.updateSettings(s.session!.storeId, {'balance_notice_template': tpl});
        s.settings?['balance_notice_template'] = tpl;
      } catch (_) {/* بدون نت: يكفي القالب لهذه الدفعة */}
    }
    final b = await repoOf(ref).startNoticeBatch(_asOf, _filter, tpl, sel);
    setState(() {
      _batch = b;
      _recipients = {for (final r in sel.recipients) r.customer.id: r};
      _phase = _Phase.sending;
    });
  }

  /// روابط الكشف لزبائن الدفعة (null = لا رابط: بدون نت ولا رابط محفوظ)
  final Map<String, String?> _links = {};
  final Map<String, Future<String?>> _linkFetches = {};

  bool get _wantsLink => _batch!.template.contains('{الرابط}');

  /// رابط الكشف: المحفوظ على الجوال أو يُجلب إن وُجد نت، وإلا تُرسل الرسالة بدون سطر الرابط
  Future<void> _ensureLink(NoticeRecipient r) async {
    final id = r.customer.id;
    if (!_wantsLink || _links.containsKey(id)) return;
    final pending = _linkFetches[id] ??= StatementLinks.linkFor(ref.read(sessionProvider), id);
    final link = await pending;
    if (mounted) setState(() => _links[id] = link);
  }

  String _message(NoticeRecipient r) => BalanceNotices.render(
        _batch!.template,
        r: r,
        store: sessionOf(ref).storeName,
        asOf: _batch!.asOf,
        f: ref.read(moneyFormatProvider),
        link: _links[r.customer.id],
      );

  /// أول زبون في الدور ما زال له رصيد (لو تغيّر رصيده بمزامنة متأخرة يُتخطى تلقائياً)
  NoticeRecipient? _current() {
    final b = _batch!;
    for (final id in b.queue) {
      if (b.sent.contains(id) || b.skipped.contains(id)) continue;
      final r = _recipients[id];
      if (r != null) return r;
      b.skipped.add(id);
    }
    return null;
  }

  Future<void> _send(NoticeRecipient r) async {
    setState(() => _awaitingConfirm = true);
    try {
      await _ensureLink(r);
      await Whatsapp.send(r.customer.phone!, _message(r));
    } catch (e) {
      if (mounted) {
        setState(() => _awaitingConfirm = false);
        showError(context, e);
      }
    }
  }

  Future<void> _confirmSent(NoticeRecipient r) async {
    await repoOf(ref).markNoticeSent(_batch!, r);
    ref.read(sessionProvider).kick(); // يرفع السجل إن وُجد نت
    _advance();
  }

  Future<void> _skip(NoticeRecipient r) async {
    await repoOf(ref).markNoticeSkipped(_batch!, r.customer.id);
    _advance();
  }

  void _advance() {
    setState(() {
      _awaitingConfirm = false;
      if (_current() == null) _phase = _Phase.done;
    });
  }

  Future<void> _retrySkipped() async {
    final b = _batch!;
    b.skipped.clear();
    await repoOf(ref).saveNoticeBatch(b);
    setState(() => _phase = _current() == null ? _Phase.done : _Phase.sending);
  }

  Future<void> _finish() async {
    await repoOf(ref).clearNoticeBatch();
    if (mounted) context.pop();
  }

  Future<void> _abandon() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الدفعة؟'),
        content: const Text('من استلموا يبقون مسجلين. الباقون لن يستلموا في هذه الدفعة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنهاء')),
        ],
      ),
    );
    if (ok == true) await _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AjilHeader(
        title: 'إرسال الأرصدة',
        subtitle: 'للزبائن عبر واتساب — رسالة لكل زبون بضغطة',
        actions: [
          if (_phase == _Phase.sending)
            LinkText('إنهاء الدفعة', onTap: _abandon, color: AjilColors.debt, size: 14, weight: FontWeight.w500),
        ],
      ),
      body: !_allowed
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('إرسال الأرصدة للمالك، أو للموظف الذي يسمح له المالك من إعدادات التنبيهات.',
                    textAlign: TextAlign.center),
              ),
            )
          : switch (_phase) {
              _Phase.loading => const Center(child: CircularProgressIndicator()),
              _Phase.setup => _setup(),
              _Phase.sending => _sending(),
              _Phase.done => _done(),
            },
    );
  }

  // ------------------------------------------------------------------ الإعداد
  Widget _setup() {
    final w = sessionOf(ref);
    final f = ref.watch(moneyFormatProvider);
    final sel = _sel;
    final today = DateTime.now();
    final lastMonthEnd = DateTime(today.year, today.month, 0);
    final preview = sel == null || sel.recipients.isEmpty
        ? null
        : BalanceNotices.render(_tpl.text.trim().isEmpty ? BalanceNotices.defaultTemplate : _tpl.text,
            r: sel.recipients.first, store: w.storeName, asOf: _asOf, f: f,
            link: StatementLinks.configured ? StatementLinks.url('…') : null);

    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('الرصيد حتى تاريخ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                PillChip(
                  label: 'اليوم',
                  selected: DateUtils.isSameDay(_asOf, today),
                  onTap: () {
                    setState(() => _asOf = today);
                    _reselect();
                  },
                ),
                PillChip(
                  label: 'نهاية الشهر الماضي (${BalanceNotices.date(lastMonthEnd, f)})',
                  selected: DateUtils.isSameDay(_asOf, lastMonthEnd),
                  onTap: () {
                    setState(() => _asOf = lastMonthEnd);
                    _reselect();
                  },
                ),
                PillChip(
                  icon: Icons.calendar_month_outlined,
                  label: BalanceNotices.date(_asOf, f),
                  selected: !DateUtils.isSameDay(_asOf, today) && !DateUtils.isSameDay(_asOf, lastMonthEnd),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _asOf,
                      firstDate: DateTime(2020),
                      lastDate: today,
                    );
                    if (d != null) {
                      setState(() => _asOf = d);
                      _reselect();
                    }
                  },
                ),
              ]),
              const SizedBox(height: 4),
              const Text('تُحسب الحركات حتى آخر ذلك اليوم فقط؛ ما سُجل بعده لا يدخل في الرصيد.',
                  style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
            ]),
          ),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('من يستلم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              CheckRow(
                label: 'الزبائن الذين عليهم فقط',
                subtitle: 'ألغِه لتشمل من لهم رصيد عندك',
                value: _debtorsOnly,
                onChanged: (v) {
                  setState(() => _debtorsOnly = v);
                  _reselect();
                },
              ),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'رصيده أكثر من (اختياري)'),
                    onChanged: (_) => _reselect(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'العملة'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('كل العملات')),
                      for (final c in w.enabledCurrencies) DropdownMenuItem(value: c, child: Text(Currency.of(c).nameAr)),
                    ],
                    onChanged: (v) {
                      setState(() => _currency = v);
                      _reselect();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: _skipDays,
                decoration: const InputDecoration(labelText: 'لا ترسل لمن استلم رصيده خلال'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('أرسل للجميع')),
                  DropdownMenuItem(value: 3, child: Text('3 أيام')),
                  DropdownMenuItem(value: 7, child: Text('أسبوع')),
                  DropdownMenuItem(value: 15, child: Text('15 يوماً')),
                  DropdownMenuItem(value: 30, child: Text('شهر')),
                ],
                onChanged: (v) {
                  setState(() => _skipDays = v);
                  _reselect();
                },
              ),
            ]),
          ),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('نص الرسالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: _tpl, maxLines: 5, onChanged: (_) => setState(() {})),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                for (final p in BalanceNotices.placeholders)
                  ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      final sel = _tpl.selection;
                      final at = sel.isValid ? sel.start : _tpl.text.length;
                      _tpl.text = _tpl.text.replaceRange(at, sel.isValid ? sel.end : at, p);
                      setState(() {});
                    },
                  ),
              ]),
              if (w.isOwner)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveTemplate,
                  onChanged: (v) => setState(() => _saveTemplate = v ?? false),
                  title: const Text('احفظه كنص افتراضي'),
                ),
              if (preview != null) ...[
                const SizedBox(height: 6),
                const Text('معاينة (أول زبون):', style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFE7F6EE), borderRadius: BorderRadius.circular(12)),
                  child: Text(preview, style: const TextStyle(height: 1.6)),
                ),
              ],
            ]),
          ),
          if (sel != null && sel.noPhone.isNotEmpty)
            SectionCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_disabled_outlined, color: AjilColors.pendingText),
                title: Text('${sel.noPhone.length} زبون عليهم رصيد بدون رقم جوال'),
                subtitle: const Text('أضف أرقامهم ليدخلوا في الإرسال'),
                children: [
                  for (final c in sel.noPhone)
                    ListTile(
                      dense: true,
                      title: Text(c.name),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: () async {
                        await context.push('/customers/${c.id}/edit');
                        _reselect();
                      },
                    ),
                ],
              ),
            ),
        ]),
      ),
      _summaryBar(sel, f),
    ]);
  }

  Widget _summaryBar(NoticeSelection? sel, MoneyFormat f) {
    final n = sel?.recipients.length ?? 0;
    final totals = sel?.totals ?? const <String, Decimal>{};
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_selecting)
            const LinearProgressIndicator(minHeight: 2)
          else if (sel != null)
            Text(
              [
                '$n زبون',
                if (totals.isNotEmpty) 'المطلوب: ${totals.entries.map((e) => f.amount(e.value, e.key, withSymbol: true)).join(' و ')}',
                if (sel.recentlySent > 0) 'تخطي ${sel.recentlySent} استلموا مؤخراً',
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: AjilColors.textSoft),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: n == 0 || _selecting ? null : _start,
            icon: const Icon(Icons.send_rounded),
            label: Text(n == 0 ? 'لا يوجد زبائن بهذه الشروط' : 'ابدأ الإرسال ($n)'),
          ),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------------ الإرسال
  Widget _sending() {
    final b = _batch!;
    final r = _current();
    if (r == null) return _done();
    if (_wantsLink && !_links.containsKey(r.customer.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLink(r)); // المعاينة تُحدَّث بالرابط
    }
    final f = ref.watch(moneyFormatProvider);
    final total = b.queue.length;
    final upcoming = b.queue
        .where((id) => id != r.customer.id && !b.sent.contains(id) && !b.skipped.contains(id))
        .map((id) => _recipients[id])
        .whereType<NoticeRecipient>()
        .take(5)
        .toList();

    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('${b.done + 1} من $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('أُرسل ${b.sent.length} · تُخطي ${b.skipped.length}',
                style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: total == 0 ? 0 : b.done / total, minHeight: 8),
          ),
          const SizedBox(height: 6),
          Text('الرصيد حتى ${BalanceNotices.date(b.asOf, f)}',
              style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
        ]),
      ),
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Initials(r.customer.name.characters.first),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                Text(r.customer.phone!, textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final e in r.balances.entries)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: e.value > Decimal.zero ? AjilColors.debtBg : AjilColors.paidBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${f.amount(e.value.abs(), e.key, withSymbol: true)} ${e.value > Decimal.zero ? 'عليه' : 'له'}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: e.value > Decimal.zero ? AjilColors.debt : AjilColors.paid),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE7F6EE), borderRadius: BorderRadius.circular(12)),
            child: Text(_message(r), style: const TextStyle(height: 1.6)),
          ),
          const SizedBox(height: 14),
          if (!_awaitingConfirm) ...[
            FilledButton.icon(
              onPressed: () => _send(r),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('إرسال عبر واتساب'),
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: () => _skip(r), child: const Text('تخطي هذا الزبون')),
          ] else ...[
            const Text('هل وصلت الرسالة؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _confirmSent(r),
              icon: const Icon(Icons.check_rounded),
              label: const Text('نعم، أُرسلت — التالي'),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _send(r), child: const Text('افتح واتساب مرة أخرى'))),
              const SizedBox(width: 8),
              Expanded(child: TextButton(onPressed: () => _skip(r), child: const Text('لم تُرسل — تخطي'))),
            ]),
          ],
        ]),
      ),
      if (upcoming.isNotEmpty)
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('التالي في الدور', style: TextStyle(fontSize: 13, color: AjilColors.textMuted)),
            for (final u in upcoming)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Expanded(child: Text(u.customer.name)),
                  Text(BalanceNotices.balancesText(u.balances, f), style: const TextStyle(fontSize: 13)),
                ]),
              ),
          ]),
        ),
    ]);
  }

  // ------------------------------------------------------------------ النهاية
  Widget _done() {
    final b = _batch!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.check_circle_rounded, size: 64, color: AjilColors.paid),
        const SizedBox(height: 12),
        Text('انتهى الإرسال', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('أُرسل لـ ${b.sent.length} زبون${b.skipped.isEmpty ? '' : ' · تُخطي ${b.skipped.length}'}',
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('سُجل لكل زبون تاريخ الرسالة والرصيد المرسل — يظهر في صفحته.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
        const SizedBox(height: 24),
        if (b.skipped.isNotEmpty) ...[
          OutlinedButton(onPressed: _retrySkipped, child: Text('أرسل للمتخطين (${b.skipped.length})')),
          const SizedBox(height: 8),
        ],
        FilledButton(onPressed: _finish, child: const Text('تم')),
      ]),
    );
  }
}
