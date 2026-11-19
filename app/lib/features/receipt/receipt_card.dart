import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import 'receipt_data.dart';

/// الإشعار كما يظهر في الشاشة وفي الصورة المشاركة (نفس تصميم الـ PDF)
class ReceiptCard extends StatelessWidget {
  const ReceiptCard(this.d, {super.key});
  final ReceiptData d;

  BoxDecoration _box(BuildContext context) => BoxDecoration(
    color: context.ajil.surface,
    border: Border.fromBorderSide(BorderSide(color: context.ajil.paperBorder)),
    borderRadius: const BorderRadius.all(Radius.circular(6)),
      );

  Widget _label(BuildContext context, String t) => Text(t, style: TextStyle(fontSize: 12, color: context.ajil.textMuted));

  Widget _field(BuildContext context, String label, String value, {Color? color, bool boxed = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 62, child: _label(context, label)),
          Expanded(
            child: Container(
              padding: boxed ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : EdgeInsets.zero,
              decoration: boxed ? _box(context) : null,
              child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final accent = d.isCredit ? context.ajil.paid : context.ajil.debt;
    return Container(
      color: context.ajil.surface,
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: context.ajil.paperMuted, width: 1.2)),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // الرأس: الشعار واسم البقالة والعنوان
          Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: context.ajil.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(d.storeMark, style: TextStyle(color: context.ajil.onPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.storeName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.ajil.primaryDark)),
                Text(d.branchName, style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: accent.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
              child: Text(d.title, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ]),
          Divider(height: 24, color: context.ajil.border),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _field(context, 'التاريخ', '${d.date}  ${d.time}'),
                _field(context, 'المرجع', d.reference, color: context.ajil.debt, boxed: true),
                _field(context, 'السيد/ة', d.customerName),
                if (d.customerPhone != null) _field(context, 'الجوال', d.customerPhone!),
              ]),
            ),
            const SizedBox(width: 10),
            Column(children: [
              QrImageView(data: d.qrData, size: 92, padding: EdgeInsets.zero, semanticsLabel: 'رمز التحقق'),
              const SizedBox(height: 4),
              _label(context, 'رمز التحقق'),
            ]),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            SizedBox(width: 62, child: _label(context, 'المبلغ')),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: _box(context),
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
                decoration: _box(context),
                child: Text(d.currencyName, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _box(context),
            child: Text(d.amountWords, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _box(context),
            child: Text(d.statement, style: const TextStyle(fontSize: 13, height: 1.6)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: d.owes ? context.ajil.debtBg : context.ajil.paidBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              const Text('الرصيد المتبقي: ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  d.balances.isEmpty ? 'مسدد بالكامل ✓' : d.balances.join(' و '),
                  style: TextStyle(fontWeight: FontWeight.w700, color: d.owes ? context.ajil.debt : context.ajil.paid),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(
                d.pending ? 'سُجّل على الجوال وسيُعتمد عند المزامنة' : 'هذا الإشعار آلي ولا يحتاج إلى ختم أو توقيع',
                style: TextStyle(fontSize: 11, color: context.ajil.textMuted),
              ),
            ),
            Text('بواسطة: ${d.recordedBy}', style: TextStyle(fontSize: 11, color: context.ajil.textMuted)),
          ]),
          const SizedBox(height: 6),
          Center(child: Text('آجِل — دفتر ديون البقالة', style: TextStyle(fontSize: 10, color: context.ajil.paperMuted))),
        ]),
      ),
    );
  }
}
