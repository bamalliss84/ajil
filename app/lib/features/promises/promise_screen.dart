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

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وعد بالسداد'),
          Text('${c.name}${bal == null ? '' : ' · عليه ${f.amount(bal, cur, withSymbol: true)}'}',
              style: const TextStyle(fontSize: 13, color: AjilColors.textMuted, fontWeight: FontWeight.w400)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('متى قال بيسدد؟', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (label, d) in options)
            ChoiceChip(label: Text(label), selected: same(_date, d), onSelected: (_) => setState(() => _date = d)),
          ActionChip(
            avatar: const Icon(Icons.event_outlined, size: 18),
            label: const Text('تاريخ…'),
            onPressed: () async {
              final d = await showDatePicker(
                  context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: _date);
              if (d != null) setState(() => _date = d);
            },
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(intl.DateFormat('EEEE d MMMM y', 'ar').format(_date), style: const TextStyle(color: AjilColors.primaryDark)),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ الموعود (اختياري)', helperText: 'فارغ = يسدد الرصيد كاملاً'),
            ),
          ),
          const SizedBox(width: 10),
          CurrencyToggle(currencies: w.enabledCurrencies, value: cur, onChanged: (v) => setState(() => _currency = v)),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: null, title: const Text('تنبيهي يوم الموعد')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _dayBefore,
          onChanged: (v) => setState(() => _dayBefore = v),
          title: const Text('تنبيهي قبلها بيوم'),
        ),
        if (c.phone != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _remindCustomer,
            onChanged: (v) => setState(() => _remindCustomer = v),
            title: const Text('تذكير الزبون عبر واتساب يوم الموعد'),
            subtitle: const Text('يظهر لك زر الإرسال في «مطلوب تحصيله اليوم»'),
          ),
        TextField(controller: _note, decoration: const InputDecoration(labelText: 'ملاحظة (مثل: بعد ما يستلم الراتب)')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AjilColors.background, borderRadius: BorderRadius.circular(12)),
          child: const Text('إذا مرّ الموعد بدون سداد يتحول إلى «وعد متأخر»، ويُغلق تلقائياً عند السداد.',
              style: TextStyle(fontSize: 13, color: AjilColors.textMuted)),
        ),
        const SizedBox(height: 20),
        FilledButton(
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
      ]),
    );
  }
}
