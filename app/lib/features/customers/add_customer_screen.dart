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
      backgroundColor: Colors.white,
      appBar: AjilHeader(close: true, title: editing ? 'تعديل بيانات الزبون' : 'زبون جديد'),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), children: [
            LabeledField(
              label: 'الاسم *',
              child: TextField(controller: _name, autofocus: !editing, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'رقم الجوال',
              helper: 'للتذكير عبر واتساب',
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(label: 'العنوان', child: TextField(controller: _address, style: const TextStyle(fontSize: 15))),
            const SizedBox(height: 14),
            LabeledField(label: 'ملاحظات', child: TextField(controller: _notes, maxLines: 2, style: const TextStyle(fontSize: 15))),
            if (w.enabledCurrencies.length > 1) ...[
              const SizedBox(height: 14),
              LabeledField(
                label: 'العملة الافتراضية',
                child: AjilSegmented<String>(
                  options: [for (final c in w.enabledCurrencies) (c, Currency.of(c).nameAr)],
                  value: _currency,
                  onChanged: (v) => setState(() => _currency = v),
                ),
              ),
            ],
            const SizedBox(height: 14),
            LabeledField(
              label: 'سقف الدين (اختياري)',
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _limit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                UnitBox(Currency.of(_currency).symbolAr),
              ]),
            ),
            if (!editing) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AjilColors.infoBg, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('رصيد سابق من الدفتر (اختياري)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AjilColors.infoText)),
                  const SizedBox(height: 2),
                  const Text('ما كان على الزبون قبل استخدام التطبيق — يظهر أول سطر في الكشف',
                      style: TextStyle(fontSize: 13, color: AjilColors.infoText)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _opening,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(hintText: 'المبلغ', fillColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AjilColors.border)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context, firstDate: DateTime(2015), lastDate: DateTime.now(), initialDate: _openingDate);
                          if (d != null) setState(() => _openingDate = d);
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.event_outlined, size: 18, color: AjilColors.textSoft),
                            const SizedBox(width: 6),
                            Text(intl.DateFormat('yyyy/MM/dd').format(_openingDate), style: const TextStyle(fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _openingNote,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(hintText: 'ملاحظة (مثل: صفحة 12 في الدفتر)', fillColor: Colors.white),
                  ),
                ]),
              ),
            ],
            if (editing && w.isOwner) ...[
              const SizedBox(height: 18),
              LabeledField(
                label: 'الحالة',
                helper: 'الأرشفة لا تحذف السجل المالي، ولا يُحسب المؤرشف ضمن حد الباقة.',
                child: AjilSegmented<CustomerStatus>(
                  options: const [
                    (CustomerStatus.active, 'نشط'),
                    (CustomerStatus.suspended, 'موقوف'),
                    (CustomerStatus.archived, 'مؤرشف'),
                  ],
                  value: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
            ],
          ]),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.headerBorder))),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              onPressed: _busy ? null : _save,
              child: Text(editing ? 'حفظ التعديلات' : 'حفظ الزبون'),
            ),
          ),
        ),
      ]),
    );
  }
}
