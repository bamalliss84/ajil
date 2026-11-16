/// أنواع الحركات — مطابقة لقيد kind في app.transactions وقواعد app.tx_before_insert
enum TxKind {
  opening('opening', 'رصيد افتتاحي', isDebit: true),
  debt('debt', 'دين', isDebit: true),
  payment('payment', 'سداد', isDebit: false),
  paymentFx('payment_fx', 'سداد بعملة أخرى', isDebit: false),
  returned('return', 'مرتجع', isDebit: false),
  discount('discount', 'خصم / مسامحة', isDebit: false),
  voided('void', 'إلغاء', isDebit: false);

  final String wire;
  final String labelAr;

  /// يزيد الدين (+) أو ينقصه (−). الإلغاء يأخذ عكس إشارة الأصل.
  final bool isDebit;
  const TxKind(this.wire, this.labelAr, {required this.isDebit});

  static TxKind fromWire(String w) => TxKind.values.firstWhere((k) => k.wire == w,
      orElse: () => throw ArgumentError('نوع حركة غير معروف: $w'));

  bool get isCredit => !isDebit && this != TxKind.voided;
}
