import 'dart:io';
import 'dart:typed_data';

import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../features/reports/report_state.dart';

/// تصدير التقرير: PDF بنفس الأقسام، وExcel بورقة لكل قسم. المشاركة عبر نافذة النظام.
class ReportExport {
  static const _green = PdfColor.fromInt(0xFF0F6E56);
  static const _red = PdfColor.fromInt(0xFFB03224);
  static const _grey = PdfColor.fromInt(0xFF5B6B70);

  static String _title(PeriodReport r) => periodLabel(const MoneyFormat(), r.period, r.today);
  static String _file(PeriodReport r, String ext) =>
      'تقرير-${_title(r).replaceAll('/', '-').replaceAll(' ', '-')}.$ext';

  static String _n(Decimal v, String cur) => const MoneyFormat().amount(v, cur);

  static List<(String, String)> _summary(PeriodReport r, String Function(String) user) {
    final sym = Currency.of(r.currency).symbolAr;
    return [
      ('الفترة', _title(r)),
      ('العملة', Currency.of(r.currency).nameAr),
      ('الديون عند الزبائن بداية الفترة', '${_n(r.openingDebt, r.currency)} $sym'),
      ('الديون عند الزبائن نهاية الفترة', '${_n(r.closingDebt, r.currency)} $sym'),
      ('التحصيل', '${_n(r.collected, r.currency)} $sym (${r.collectedCount})'),
      ('ديون جديدة', '${_n(r.newDebt, r.currency)} $sym (${r.debtCount})'),
      ('التحصيل في فترة المقارنة', '${_n(r.prevCollected, r.currency)} $sym'),
      ('الديون الجديدة في فترة المقارنة', '${_n(r.prevNewDebt, r.currency)} $sym'),
      ('نسبة التحصيل إلى الديون الجديدة', r.collectionRatio == null ? '—' : '${r.collectionRatio}%'),
      ('وعود: وُفي / متأخرة / قادمة', '${r.promises.kept} / ${r.promises.overdue} / ${r.promises.upcoming}'),
      ('زبائن جدد', '${r.newCustomers}'),
      if (r.avgPayDays != null) ('متوسط مدة السداد', '${r.avgPayDays} يوماً'),
    ];
  }

  static List<(String, Decimal, Decimal, int)> _series(PeriodReport r) {
    if (r.period.kind == PeriodKind.year) {
      return [for (final b in r.monthly) (monthNames[b.at.month - 1], b.collected, b.debt, b.count)];
    }
    if (r.period.kind == PeriodKind.day) {
      return [for (final b in r.hourly) if (b.count > 0) ('${b.at.hour}:00', b.collected, b.debt, b.count)];
    }
    return [for (final b in r.daily) if (!b.at.isAfter(r.effectiveEnd)) ('${b.at.year}/${b.at.month}/${b.at.day}', b.collected, b.debt, b.count)];
  }

  static String _seriesTitle(PeriodReport r) =>
      r.period.kind == PeriodKind.year ? 'الأشهر' : (r.period.kind == PeriodKind.day ? 'الساعات' : 'الأيام');

  // ------------------------------------------------------------------ PDF

  static Future<Uint8List> pdf(PeriodReport r, {required WorkSession session, required Map<String, String> users}) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf'));
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
    String user(String id) => users[id] ?? 'مستخدم';

    pw.Widget h(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
        );
    pw.Widget table(List<String> head, List<List<String>> rows) => pw.TableHelper.fromTextArray(
          headers: head,
          data: rows,
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2F1)),
          cellAlignment: pw.Alignment.centerRight,
          headerAlignment: pw.Alignment.centerRight,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(session.storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.Text('تقرير ${_title(r)}', style: const pw.TextStyle(fontSize: 14)),
        ]),
        pw.Text('${session.branch.name} · ${Currency.of(r.currency).nameAr}', style: const pw.TextStyle(fontSize: 10, color: _grey)),
        pw.Divider(),
      ]),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('صفحة ${c.pageNumber} من ${c.pagesCount} — آجِل', style: const pw.TextStyle(fontSize: 9)),
      ),
      build: (_) => [
        h('الملخص'),
        table(['البند', 'القيمة'], [for (final (k, v) in _summary(r, user)) [k, v]]),
        h(_seriesTitle(r)),
        table(['', 'تحصيل', 'ديون', 'عمليات'],
            [for (final (k, c, d, n) in _series(r)) [k, _n(c, r.currency), _n(d, r.currency), '$n']]),
        h('ملخص الحركات'),
        table(['النوع', 'العدد', 'المبلغ'], [
          for (final k in r.kinds) [k.kind == TxKind.payment ? 'سداد' : k.kind.labelAr, '${k.count}', _n(k.amount, r.currency)]
        ]),
        h('الأكثر سداداً'),
        table(['الزبون', 'دفعات', 'المبلغ'], [
          for (final c in r.topPayers.take(20)) [c.customer?.name ?? '—', '${c.count}', _n(c.amount, r.currency)]
        ]),
        h('الأكثر ديناً'),
        table(['الزبون', 'عمليات', 'المبلغ'], [
          for (final c in r.topDebtors.take(20)) [c.customer?.name ?? '—', '${c.count}', _n(c.amount, r.currency)]
        ]),
        h('عليهم رصيد ولم يسددوا في الفترة'),
        table(['الزبون', 'الرصيد'], [for (final c in r.noPayment.take(30)) [c.customer?.name ?? '—', _n(c.amount, r.currency)]]),
        if (session.isOwner) ...[
          h('حسب المستخدم'),
          table(['المستخدم', 'تحصيل', 'ديون', 'عمليات'], [
            for (final u in r.users) [user(u.userId), _n(u.collected, r.currency), _n(u.debt, r.currency), '${u.ops}']
          ]),
        ],
        h('أعمار الديون'),
        table(['أقل من 30 يوماً', '30–60', '60–90', 'أكثر من 90'], [
          [_n(r.aging.under30, r.currency), _n(r.aging.d30to60, r.currency), _n(r.aging.d60to90, r.currency), _n(r.aging.over90, r.currency)]
        ]),
        pw.SizedBox(height: 10),
        pw.Text('محسوب من بيانات هذا الجوال — الحركات غير المتزامنة محسوبة، والمرفوضة من الخادم مستبعدة.',
            style: const pw.TextStyle(fontSize: 9, color: _red)),
      ],
    ));
    return doc.save();
  }

  // ------------------------------------------------------------------ Excel

  static Uint8List excel(PeriodReport r,
      {required WorkSession session, required Map<String, String> users, Map<String, String> customerNames = const {}}) {
    final book = xl.Excel.createExcel();
    String user(String id) => users[id] ?? 'مستخدم';
    xl.CellValue t(String s) => xl.TextCellValue(s);
    xl.CellValue d(Decimal v) => xl.DoubleCellValue(v.toDouble());
    xl.CellValue i(int v) => xl.IntCellValue(v);

    void sheet(String name, List<String> head, List<List<xl.CellValue>> rows) {
      final s = book[name];
      s.isRTL = true;
      s.appendRow([for (final h in head) t(h)]);
      for (final r in rows) {
        s.appendRow(r);
      }
    }

    sheet('الملخص', ['البند', 'القيمة'], [
      [t('البقالة'), t('${session.storeName} · ${session.branch.name}')],
      for (final (k, v) in _summary(r, user)) [t(k), t(v)],
    ]);
    sheet(_seriesTitle(r), ['', 'تحصيل', 'ديون', 'عمليات'], [
      for (final (k, c, dd, n) in _series(r)) [t(k), d(c), d(dd), i(n)]
    ]);
    sheet('ملخص الحركات', ['النوع', 'العدد', 'المبلغ'], [
      for (final k in r.kinds) [t(k.kind == TxKind.payment ? 'سداد' : k.kind.labelAr), i(k.count), d(k.amount)]
    ]);
    sheet('الزبائن', ['التصنيف', 'الزبون', 'العدد', 'المبلغ', 'الرصيد نهاية الفترة'], [
      for (final c in r.topPayers) [t('سداد'), t(c.customer?.name ?? '—'), i(c.count), d(c.amount), d(c.balance)],
      for (final c in r.topDebtors) [t('دين'), t(c.customer?.name ?? '—'), i(c.count), d(c.amount), d(c.balance)],
      for (final c in r.noPayment) [t('بلا سداد'), t(c.customer?.name ?? '—'), i(0), d(c.amount), d(c.balance)],
    ]);
    if (session.isOwner) {
      sheet('المستخدمون', ['المستخدم', 'تحصيل', 'ديون', 'عمليات'], [
        for (final u in r.users) [t(user(u.userId)), d(u.collected), d(u.debt), i(u.ops)]
      ]);
    }
    sheet('أعمار الديون', ['أقل من 30 يوماً', '30–60', '60–90', 'أكثر من 90'], [
      [d(r.aging.under30), d(r.aging.d30to60), d(r.aging.d60to90), d(r.aging.over90)]
    ]);
    sheet('الحركات', ['التاريخ', 'النوع', 'الزبون', 'المبلغ', 'الوصف', 'المستخدم'], [
      for (final x in r.txs)
        [
          t('${x.createdAt.year}/${x.createdAt.month}/${x.createdAt.day} ${x.createdAt.hour}:${x.createdAt.minute.toString().padLeft(2, '0')}'),
          t(x.kind.labelAr),
          t(customerNames[x.customerId] ?? ''),
          d(x.amount),
          t(x.description ?? ''),
          t(user(x.createdBy)),
        ]
    ]);
    book.delete('Sheet1');
    book.setDefaultSheet('الملخص');
    return Uint8List.fromList(book.encode()!);
  }

  static Future<void> share(Uint8List bytes, String filename, String mime) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: filename);
  }

  static Future<void> sharePdf(PeriodReport r, {required WorkSession session, required Map<String, String> users}) async =>
      share(await pdf(r, session: session, users: users), _file(r, 'pdf'), 'application/pdf');

  static Future<void> shareExcel(PeriodReport r,
          {required WorkSession session, required Map<String, String> users, Map<String, String> customerNames = const {}}) =>
      share(excel(r, session: session, users: users, customerNames: customerNames), _file(r, 'xlsx'),
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
}
