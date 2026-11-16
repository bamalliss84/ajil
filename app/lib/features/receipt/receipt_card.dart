import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import 'receipt_data.dart';

/// الإشعار كما يظهر في الشاشة وفي الصورة المشاركة (نفس تصميم الـ PDF)
class ReceiptCard extends StatelessWidget {
  const ReceiptCard(this.d, {super.key});
  final ReceiptData d;

  static const _box = BoxDecoration(
    color: Colors.white,
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFB9C4C1))),
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted));

  Widget _field(String label, String value, {Color? color, bool boxed = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 62, child: _label(label)),
          Expanded(
            child: Container(
              padding: boxed ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : EdgeInsets.zero,
              decoration: boxed ? _box : null,
              child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final accent = d.isCredit ? AjilColors.paid : AjilColors.debt;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF9AA6A3), width: 1.2)),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // الرأس: الشعار واسم البقالة والعنوان
          Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AjilColors.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(d.storeMark, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.storeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AjilColors.primaryDark)),
                Text(d.branchName, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: accent.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
              child: Text(d.title, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ]),
          const Divider(height: 24, color: Color(0xFFD5DDDB)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _field('التاريخ', '${d.date}  ${d.time}'),
                _field('المرجع', d.reference, color: AjilColors.debt, boxed: true),
                _field('السيد/ة', d.customerName),
                if (d.customerPhone != null) _field('الجوال', d.customerPhone!),
              ]),
            ),
            const SizedBox(width: 10),
            Column(children: [
              QrImageView(data: d.qrData, size: 92, padding: EdgeInsets.zero, semanticsLabel: 'رمز التحقق'),
              const SizedBox(height: 4),
              _label('رمز التحقق'),
            ]),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            SizedBox(width: 62, child: _label('المبلغ')),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: _box,
                child: Text('#${d.amount}#',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: _box,
                child: Text(d.currencyName, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _box,
            child: Text(d.amountWords, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _box,
            child: Text(d.statement, style: const TextStyle(fontSize: 13, height: 1.6)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: d.owes ? AjilColors.debtBg : AjilColors.paidBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              const Text('الرصيد المتبقي: ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  d.balances.isEmpty ? 'مسدد بالكامل ✓' : d.balances.join(' و '),
                  style: TextStyle(fontWeight: FontWeight.w700, color: d.owes ? AjilColors.debt : AjilColors.paid),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(
                d.pending ? 'سُجّل على الجوال وسيُعتمد عند المزامنة' : 'هذا الإشعار آلي ولا يحتاج إلى ختم أو توقيع',
                style: const TextStyle(fontSize: 11, color: AjilColors.textMuted),
              ),
            ),
            Text('بواسطة: ${d.recordedBy}', style: const TextStyle(fontSize: 11, color: AjilColors.textMuted)),
          ]),
          const SizedBox(height: 6),
          const Center(child: Text('آجِل — دفتر ديون البقالة', style: TextStyle(fontSize: 10, color: Color(0xFF9AA6A3)))),
        ]),
      ),
    );
  }
}
