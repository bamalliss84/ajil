import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme.dart';
import 'pdf_palette.dart';
import '../features/receipt/receipt_data.dart';

/// الإشعار/السند PDF — نفس تصميم شاشة المعاينة (A5)، أو نسخة مختصرة للطابعة الحرارية 58mm
class ReceiptPdf {
  static PdfPalette _p = PdfPalette.of(AjilTheme.classic);


  static Future<pw.ThemeData> _theme() async {
    try {
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf')),
        bold: pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf')),
      );
    } catch (_) {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.iBMPlexSansArabicRegular(),
        bold: await PdfGoogleFonts.iBMPlexSansArabicSemiBold(),
      );
    }
  }

  static pw.BoxDecoration get _box => pw.BoxDecoration(
        border: pw.Border.all(color: _p.paperBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      );

  static Future<Uint8List> build(ReceiptData d, {bool thermal = false, AjilTheme theme = AjilTheme.classic}) async {
    _p = PdfPalette.of(theme);
    final doc = pw.Document(theme: await _theme(), title: '${d.title} ${d.reference}', author: d.storeName);
    final accent = d.isCredit ? _p.paid : _p.debt;
    doc.addPage(thermal ? _thermal(d, accent) : _a5(d, accent));
    return doc.save();
  }

  static pw.Widget _label(String t) => pw.Text(t, style: pw.TextStyle(fontSize: 9, color: _p.muted));

  static pw.Widget _field(String label, String value, {PdfColor? color, bool boxed = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(children: [
          pw.SizedBox(width: 48, child: _label(label)),
          pw.Expanded(
            child: pw.Container(
              padding: boxed ? const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4) : pw.EdgeInsets.zero,
              decoration: boxed ? _box : null,
              child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
            ),
          ),
        ]),
      );

  static pw.Page _a5(ReceiptData d, PdfColor accent) => pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _p.paperMuted, width: 1.2)),
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Row(children: [
              pw.Container(
                width: 38,
                height: 38,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: _p.primary, borderRadius: pw.BorderRadius.all(pw.Radius.circular(9))),
                child: pw.Text(d.storeMark, style: pw.TextStyle(color: _p.onPrimary, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(d.storeName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _p.primaryDark)),
                  pw.Text(d.branchName, style: pw.TextStyle(fontSize: 9, color: _p.muted)),
                ]),
              ),
              pw.Text(d.title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: accent)),
            ]),
            pw.Divider(color: _p.paperBorder, height: 18),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(children: [
                  _field('التاريخ', '${d.date}  ${d.time}'),
                  _field('المرجع', d.reference, color: _p.debt, boxed: true),
                  _field('السيد/ة', d.customerName),
                  if (d.customerPhone != null) _field('الجوال', d.customerPhone!),
                ]),
              ),
              pw.SizedBox(width: 10),
              pw.Column(children: [
                pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: d.qrData, width: 70, height: 70),
                pw.SizedBox(height: 3),
                _label('رمز التحقق'),
              ]),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.SizedBox(width: 48, child: _label('المبلغ')),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  alignment: pw.Alignment.center,
                  decoration: _box,
                  child: pw.Text('#${d.amount}#',
                      textDirection: pw.TextDirection.ltr,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: accent)),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 7),
                  alignment: pw.Alignment.center,
                  decoration: _box,
                  child: pw.Text(d.currencyName, style: const pw.TextStyle(fontSize: 11)),
                ),
              ),
            ]),
            pw.SizedBox(height: 6),
            pw.Container(padding: const pw.EdgeInsets.all(8), decoration: _box,
                child: pw.Text(d.amountWords, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 6),
            pw.Container(padding: const pw.EdgeInsets.all(8), decoration: _box,
                child: pw.Text(d.statement, style: const pw.TextStyle(fontSize: 10, lineSpacing: 3))),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: pw.BoxDecoration(
                color: d.owes ? _p.debtBg : _p.paidBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(children: [
                pw.Text('الرصيد المتبقي: ', style: const pw.TextStyle(fontSize: 10)),
                pw.Expanded(
                  child: pw.Text(d.balances.isEmpty ? 'مسدد بالكامل' : d.balances.join(' و '),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: d.owes ? _p.debt : _p.paid)),
                ),
              ]),
            ),
            pw.Spacer(),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Text(
                  d.pending ? 'سُجّل على الجوال وسيُعتمد عند المزامنة' : 'هذا الإشعار آلي ولا يحتاج إلى ختم أو توقيع',
                  style: pw.TextStyle(fontSize: 8, color: _p.muted),
                ),
              ),
              pw.Text('بواسطة: ${d.recordedBy}', style: pw.TextStyle(fontSize: 8, color: _p.muted)),
            ]),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('آجِل — دفتر ديون البقالة', style: pw.TextStyle(fontSize: 7, color: _p.paperBorder))),
          ]),
        ),
      );

  static pw.Page _thermal(ReceiptData d, PdfColor accent) => pw.Page(
        pageFormat: PdfPageFormat.roll57,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(6),
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Text(d.storeName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(d.title, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(height: 8),
          pw.Text('التاريخ: ${d.date} ${d.time}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('المرجع: ${d.reference}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('الزبون: ${d.customerName}', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text('${d.amount} ${d.currencyName}',
              textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text(d.amountWords, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
          pw.Divider(height: 8),
          pw.Text('الرصيد: ${d.balances.isEmpty ? 'مسدد بالكامل' : d.balances.join(' و ')}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: d.qrData, width: 50, height: 50)),
          pw.SizedBox(height: 3),
          pw.Text('شكراً لتعاملكم', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
        ]),
      );
}
