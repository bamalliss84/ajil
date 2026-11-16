import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// إضافة زبون (مع رصيد افتتاحي من الدفتر الورقي) أو تعديل بياناته
class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key, this.editId});
  final String? editId;
  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _limit = TextEditingController();
  final _opening = TextEditingController();
  final _openingNote = TextEditingController();
  late String _currency;
  DateTime _openingDate = DateTime.now();
  CustomerStatus _status = CustomerStatus.active;
  Customer? _editing;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final w = sessionOf(ref);
    _currency = w.defaultCurrency;
    if (widget.editId != null) {
      repoOf(ref).watchCustomer(widget.editId!).first.then((c) {
        if (c == null || !mounted) return;
        setState(() {
          _editing = c;
          _name.text = c.name;
          _phone.text = c.phone ?? '';
          _address.text = c.address ?? '';
          _notes.text = c.notes ?? '';
          _limit.text = c.creditLimit?.toString() ?? '';
          _currency = c.defaultCurrency;
          _status = c.status;
        });
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) return showError(context, 'x: اكتب اسم الزبون');
    final limit = _limit.text.trim().isEmpty ? null : MoneyFormat.parse(_limit.text);
    final opening = _opening.text.trim().isEmpty ? null : MoneyFormat.parse(_opening.text);
    if (_limit.text.trim().isNotEmpty && limit == null) return showError(context, 'x: سقف الدين غير صحيح');
    if (_opening.text.trim().isNotEmpty && opening == null) return showError(context, 'x: الرصيد السابق غير صحيح');
    setState(() => _busy = true);
    try {
      final repo = repoOf(ref);
      if (_editing != null) {
        String? clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
        final e = _editing!;
        await repo.updateCustomer(Customer(
          id: e.id,
          storeId: e.storeId,
          branchId: e.branchId,
          name: _name.text.trim(),
          phone: clean(_phone),
          address: clean(_address),
          notes: clean(_notes),
          defaultCurrency: _currency,
          creditLimit: limit,
          creditLimitCurrency: limit == null ? null : _currency,
          status: _status,
          updatedAt: DateTime.now(),
          serverSeq: e.serverSeq,
        ));
        ref.read(sessionProvider).kick();
        if (mounted) context.pop();
      } else {
        final c = await repo.addCustomer(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
          notes: _notes.text,
          currency: _currency,
          creditLimit: limit,
          openingBalance: opening,
          openingDate: _openingDate,
          openingNote: _openingNote.text.trim().isEmpty ? null : _openingNote.text.trim(),
        );
        ref.read(sessionProvider).kick();
        if (mounted) context.pushReplacement('/customers/${c.id}');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = sessionOf(ref);
    final editing = widget.editId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'تعديل بيانات الزبون' : 'زبون جديد')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, autofocus: !editing, decoration: const InputDecoration(labelText: 'الاسم *')),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'رقم الجوال (للتذكير عبر واتساب)'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان')),
        const SizedBox(height: 12),
        TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات')),
        const SizedBox(height: 16),
        Row(children: [
          const Text('العملة الافتراضية'),
          const Spacer(),
          CurrencyToggle(currencies: w.enabledCurrencies, value: _currency, onChanged: (v) => setState(() => _currency = v)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _limit,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'سقف الدين (اختياري)', suffixText: Currency.of(_currency).symbolAr),
        ),
        if (!editing) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AjilColors.infoBg, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('رصيد سابق من الدفتر (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AjilColors.infoText)),
              const Text('ما كان على الزبون قبل استخدام التطبيق — يظهر أول سطر في الكشف',
                  style: TextStyle(fontSize: 13, color: AjilColors.infoText)),
              const SizedBox(height: 10),
              TextField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'المبلغ', suffixText: Currency.of(_currency).symbolAr),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context, firstDate: DateTime(2015), lastDate: DateTime.now(), initialDate: _openingDate);
                  if (d != null) setState(() => _openingDate = d);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text('التاريخ: ${intl.DateFormat('yyyy/MM/dd').format(_openingDate)}'),
              ),
              const SizedBox(height: 10),
              TextField(controller: _openingNote, decoration: const InputDecoration(labelText: 'ملاحظة (مثل: صفحة 12 في الدفتر)')),
            ]),
          ),
        ],
        if (editing && w.isOwner) ...[
          const SizedBox(height: 16),
          SegmentedButton<CustomerStatus>(
            segments: const [
              ButtonSegment(value: CustomerStatus.active, label: Text('نشط')),
              ButtonSegment(value: CustomerStatus.suspended, label: Text('موقوف')),
              ButtonSegment(value: CustomerStatus.archived, label: Text('مؤرشف')),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('الأرشفة لا تحذف السجل المالي، ولا يُحسب المؤرشف ضمن حد الباقة.',
                style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('حفظ')),
      ]),
    );
  }
}
