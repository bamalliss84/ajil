import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart' as intl;

/// محتوى الإشعار/السند — يُبنى مرة ويُعرض في الشاشة وفي الـ PDF والصورة بنفس الشكل
class ReceiptData {
  final String title;
  final String storeName;
  final String storeMark; // الحرف الأول للشعار
  final String branchName;
  final String reference;
  final String date;
  final String time;
  final String customerName;
  final String? customerPhone;
  final String amount;
  final String currencyName;
  final String amountWords;
  final String statement;
  final List<String> balances; // الرصيد المتبقي لكل عملة
  final bool owes;
  final String qrData;
  final bool pending;
  final bool isCredit; // سداد/مرتجع/خصم (أخضر) أو دين (أحمر)
  final String recordedBy;

  const ReceiptData({
    required this.title,
    required this.storeName,
    required this.storeMark,
    required this.branchName,
    required this.reference,
    required this.date,
    required this.time,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.currencyName,
    required this.amountWords,
    required this.statement,
    required this.balances,
    required this.owes,
    required this.qrData,
    required this.pending,
    required this.isCredit,
    required this.recordedBy,
  });

  static String titleFor(TxKind k) => switch (k) {
        TxKind.debt => 'إشعار دين',
        TxKind.payment => 'سند قبض',
        TxKind.paymentFx => 'سند قبض بعملة أخرى',
        TxKind.returned => 'إشعار مرتجع',
        TxKind.discount => 'إشعار خصم',
        TxKind.opening => 'إشعار رصيد افتتاحي',
        TxKind.voided => 'إشعار إلغاء قيد',
      };

  factory ReceiptData.build({
    required WorkSession session,
    required Customer customer,
    required LedgerTx tx,
    required Map<String, CurrencyBalance> balances,
    required MoneyFormat f,
    String? originalRef,
  }) {
    final cur = Currency.of(tx.currency);
    final verb = tx.kind.isDebit ? 'قيدنا على حسابكم' : 'قيدنا لحسابكم';
    final details = <String>[
      'نفيدكم أننا $verb ${tx.kind.labelAr}',
      if (tx.description != null && tx.description!.isNotEmpty) tx.description!,
      if (tx.kind == TxKind.paymentFx && tx.fxPaidAmount != null)
        'المدفوع ${f.amount(tx.fxPaidAmount!, tx.fxPaidCurrency!, withSymbol: true)} بسعر صرف ${tx.fxRate}',
      if (tx.kind == TxKind.voided) 'إلغاء القيد ${originalRef ?? ''} — السبب: ${tx.voidReason ?? ''}',
      if (tx.dueDate != null) 'موعد السداد: ${intl.DateFormat('yyyy/MM/dd').format(tx.dueDate!)}',
    ];
    final owes = balances.values.any((b) => b.balance > Decimal.zero);
    return ReceiptData(
      title: titleFor(tx.kind),
      storeName: session.storeName,
      storeMark: session.storeName.trim().isEmpty ? 'آ' : session.storeName.trim().replaceFirst('بقالة ', '').substring(0, 1),
      branchName: session.branch.name,
      reference: tx.invoiceNo ?? '${session.branch.code}-${tx.deviceSeq ?? tx.id.substring(0, 6).toUpperCase()}',
      date: intl.DateFormat('yyyy-MM-dd').format(tx.createdAt),
      time: intl.DateFormat('h:mm a', 'ar').format(tx.createdAt),
      customerName: customer.name,
      customerPhone: customer.phone,
      amount: f.amount(tx.amount, tx.currency),
      currencyName: cur.nameAr,
      amountWords: ArabicWords.amount(tx.amount, tx.currency),
      statement: details.join(' — '),
      balances: [
        for (final b in balances.values)
          if (b.balance != Decimal.zero)
            '${f.amount(b.balance.abs(), b.currency, withSymbol: true)}${b.balance > Decimal.zero ? ' عليكم' : ' لكم'}',
      ],
      owes: owes,
      qrData: 'ajil:tx/${tx.id}?a=${tx.amount}&c=${tx.currency}&r=${Uri.encodeComponent(tx.invoiceNo ?? '')}',
      pending: tx.sync != SyncState.synced,
      isCredit: !tx.kind.isDebit,
      recordedBy: tx.createdBy == session.appUserId ? session.displayName : 'المستخدم',
    );
  }

  /// نص مختصر للإرسال المباشر عبر واتساب
  String asText() => [
        '*$title* — $storeName',
        'التاريخ: $date $time',
        'المرجع: $reference',
        'السيد/ة: $customerName',
        'المبلغ: $amount $currencyName',
        '($amountWords)',
        if (balances.isNotEmpty) 'الرصيد: ${balances.join(' و ')}' else 'الرصيد: مسدد بالكامل ✓',
      ].join('\n');
}
