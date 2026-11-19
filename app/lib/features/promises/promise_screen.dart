import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// «قال بيسدد بكره»: الوعد ليس حركة مالية ولا يغيّر الرصيد — تذكير فقط
class PromiseScreen extends ConsumerStatefulWidget {
  const PromiseScreen({super.key, required this.customerId});
  final String customerId;
  @override
  ConsumerState<PromiseScreen> createState() => _PromiseScreenState();
}

class _PromiseScreenState extends ConsumerState<PromiseScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _dayBefore = false;
  bool _remindCustomer = true;
  String? _currency;

  TextStyle get _legend => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.ajil.text);

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(customerProvider(widget.customerId)).valueOrNull;
    final txs = ref.watch(customerTxsProvider(widget.customerId)).valueOrNull ?? const [];
    final w = sessionOf(ref);
    final f = ref.watch(moneyFormatProvider);
    if (c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cur = _currency ?? c.defaultCurrency;
    final bal = Ledger.balances(txs)[cur]?.balance;
    final now = DateTime.now();
    final options = [
      ('اليوم', now),
      ('غداً', now.add(const Duration(days: 1))),
      ('بعد 3 أيام', now.add(const Duration(days: 3))),
      ('بعد أسبوع', now.add(const Duration(days: 7))),
      ('آخر الشهر', DateTime(now.year, now.month + 1, 0)),
    ];
    bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final preset = options.any((o) => same(o.$2, _date));

    return Scaffold(
      backgroundColor: context.ajil.surface,
      appBar: AjilHeader(
        close: true,
        title: 'وعد بالسداد',
        subtitle: '${c.name}${bal == null ? '' : ' · عليه ${f.amount(bal, cur, withSymbol: true)}'}',
      ),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), children: [
            Text('متى قال بيسدد؟', style: _legend),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.3,
              children: [
                for (final (label, d) in options)
                  OptionTile(label: label, selected: same(_date, d), onTap: () => setState(() => _date = d)),
                OptionTile(
                  label: preset ? 'تاريخ…' : intl.DateFormat('d/M').format(_date),
                  selected: !preset,
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: _date);
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(intl.DateFormat('EEEE d MMMM y', 'ar').format(_date),
                style: TextStyle(fontSize: 14, color: context.ajil.primaryDark)),
            const SizedBox(height: 18),
            LabeledField(
              label: 'المبلغ الموعود (اختياري)',
              labelStyle: _legend,
              gap: 6,
              helper: 'فارغ = يسدد الرصيد كاملاً',
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                if (w.enabledCurrencies.length > 1)
                  PopupMenuButton<String>(
                    tooltip: 'العملة',
                    onSelected: (v) => setState(() => _currency = v),
                    itemBuilder: (_) => [
                      for (final x in w.enabledCurrencies) PopupMenuItem(value: x, child: Text(Currency.of(x).nameAr)),
                    ],
                    child: UnitBox('${Currency.of(cur).symbolAr} ▾', height: 50),
                  )
                else
                  UnitBox(Currency.of(cur).symbolAr, height: 50),
              ]),
            ),
            const SizedBox(height: 18),
            Text('التنبيهات', style: _legend),
            const SizedBox(height: 4),
            const CheckRow(label: 'تنبيهي يوم الموعد 9:00 ص', value: true, onChanged: null, minHeight: 48),
            CheckRow(
              label: 'تنبيهي قبلها بيوم',
              value: _dayBefore,
              minHeight: 48,
              divider: c.phone != null,
              onChanged: (v) => setState(() => _dayBefore = v),
            ),
            if (c.phone != null)
              CheckRow(
                label: 'تذكير الزبون عبر واتساب يوم الموعد',
                subtitle: 'يظهر لك زر الإرسال في «مطلوب تحصيله اليوم»',
                value: _remindCustomer,
                minHeight: 48,
                divider: false,
                onChanged: (v) => setState(() => _remindCustomer = v),
              ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'ملاحظة',
              labelStyle: _legend,
              gap: 6,
              child: TextField(
                controller: _note,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(hintText: 'مثل: بعد ما يستلم الراتب'),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: context.ajil.background, borderRadius: BorderRadius.circular(12)),
              child: Text('إذا مرّ الموعد بدون سداد يتحول إلى «وعد متأخر»، ويُغلق تلقائياً عند السداد.',
                  style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
            ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.headerBorder))),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                final amount = _amount.text.trim().isEmpty ? null : MoneyFormat.parse(_amount.text);
                if (_amount.text.trim().isNotEmpty && amount == null) return showError(context, 'x: المبلغ غير صحيح');
                try {
                  await repoOf(ref).addPromise(
                    customerId: c.id,
                    date: _date,
                    amount: amount,
                    currency: cur,
                    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                    remindDayBefore: _dayBefore,
                    remindCustomer: _remindCustomer,
                  );
                  ref.read(sessionProvider).kick();
                  if (context.mounted) context.pop();
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: const Text('حفظ الوعد'),
            ),
          ),
        ),
      ]),
    );
  }
}
