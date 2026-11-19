import 'dart:typed_data';

import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme.dart';
import 'pdf_palette.dart';

/// كشف حساب / إيصال PDF بالعربي (يُشارك عبر واتساب أو يُطبع)
class StatementPdf {
  static PdfPalette _p = PdfPalette.of(AjilTheme.classic);

  /// الخط مضمّن في التطبيق حتى يعمل الـ PDF بدون إنترنت (assets/fonts)
  static Future<pw.ThemeData> _theme() async {
    try {
      final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'));
      final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf'));
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      final regular = await PdfGoogleFonts.iBMPlexSansArabicRegular();
      final bold = await PdfGoogleFonts.iBMPlexSansArabicSemiBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    }
  }

  static final _date = intl.DateFormat('yyyy/MM/dd HH:mm');

  static Future<Uint8List> statement({
    required WorkSession session,
    required Statement st,
    required MoneyFormat f,
    bool detailed = true,
    AjilTheme theme = AjilTheme.classic,
  }) async {
    _p = PdfPalette.of(theme);
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(session.storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _p.primary)),
          pw.Text('كشف حساب', style: const pw.TextStyle(fontSize: 14)),
        ]),
        pw.Text('${session.branch.name} · ${_date.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Text('${st.customer.name}${st.customer.phone == null ? '' : ' · ${st.customer.phone}'}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
      ]),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('صفحة ${c.pageNumber} من ${c.pagesCount} — آجِل', style: const pw.TextStyle(fontSize: 9)),
      ),
      build: (_) => [
        for (final cs in st.byCurrency.values) ...[
          pw.Text(Currency.of(cs.currency).nameAr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 4),
          pw.Table(border: pw.TableBorder.all(color: _p.border), children: [
            _row(['إجمالي الديون', 'إجمالي المسدد', 'الرصيد المتبقي'], header: true),
            _row([f.amount(cs.openingBalance + cs.debit, cs.currency), f.amount(cs.credit, cs.currency),
              f.amount(cs.closingBalance, cs.currency, withSymbol: true)], highlightLast: true),
          ]),
          if (detailed) ...[
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _p.border),
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(3), 3: pw.FlexColumnWidth(1.6), 4: pw.FlexColumnWidth(1.6)},
              children: [
                _row(['التاريخ', 'النوع', 'البيان', 'المبلغ', 'الرصيد'], header: true),
                if (st.from != null)
                  _row(['', '', 'رصيد ما قبل الفترة', '', f.amount(cs.openingBalance, cs.currency)]),
                for (final l in cs.lines.reversed)
                  _row([
                    _date.format(l.tx.createdAt),
                    l.tx.kind.labelAr,
                    [l.tx.description, l.tx.invoiceNo, l.tx.voidReason].whereType<String>().join(' · '),
                    f.amount(l.signed, cs.currency, signed: true),
                    f.amount(l.runningBalance, cs.currency),
                  ], strike: l.isVoided),
              ],
            ),
          ],
          pw.SizedBox(height: 18),
        ],
      ],
    ));
    return doc.save();
  }

  static pw.TableRow _row(List<String> cells, {bool header = false, bool strike = false, bool highlightLast = false}) =>
      pw.TableRow(
        decoration: header ? pw.BoxDecoration(color: _p.primaryLight) : null,
        children: [
          for (var i = 0; i < cells.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                cells[i],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: header || (highlightLast && i == cells.length - 1) ? pw.FontWeight.bold : null,
                  color: highlightLast && i == cells.length - 1 ? _p.debt : null,
                  decoration: strike ? pw.TextDecoration.lineThrough : null,
                ),
              ),
            ),
        ],
      );

  static Future<void> share(Uint8List bytes, String filename) => Printing.sharePdf(bytes: bytes, filename: filename);
  static Future<void> printDoc(Uint8List bytes) => Printing.layoutPdf(onLayout: (_) async => bytes);
}
