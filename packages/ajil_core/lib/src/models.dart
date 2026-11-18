import 'package:decimal/decimal.dart';
import 'tx_kind.dart';

Decimal _dec(Object? v) => v == null ? Decimal.zero : Decimal.parse(v.toString());
Decimal? _decN(Object? v) => v == null ? null : Decimal.parse(v.toString());
DateTime _dt(Object? v) => DateTime.parse(v as String).toLocal();
DateTime? _dtN(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();
DateTime? _dateN(Object? v) => v == null ? null : DateTime.parse(v as String);
String? _dateStr(DateTime? d) =>
    d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum CustomerStatus { active, suspended, archived }

class Customer {
  final String id;
  final String storeId;
  final String branchId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final String defaultCurrency;
  final Decimal? creditLimit;
  final String? creditLimitCurrency;
  final CustomerStatus status;
  final DateTime updatedAt;
  final int? serverSeq;

  const Customer({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    required this.defaultCurrency,
    this.creditLimit,
    this.creditLimitCurrency,
    this.status = CustomerStatus.active,
    required this.updatedAt,
    this.serverSeq,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'],
        storeId: j['store_id'],
        branchId: j['branch_id'],
        name: j['name'],
        phone: j['phone'],
        address: j['address'],
        notes: j['notes'],
        defaultCurrency: j['default_currency'],
        creditLimit: _decN(j['credit_limit']),
        creditLimitCurrency: j['credit_limit_currency'],
        status: CustomerStatus.values.byName(j['status'] ?? 'active'),
        updatedAt: _dt(j['updated_at']),
        serverSeq: j['server_seq'],
      );

  /// ما يُرسل للخادم عند الإنشاء/التعديل (الخادم يحدد updated_at و server_seq)
  Map<String, dynamic> toServer() => {
        'id': id,
        'store_id': storeId,
        'branch_id': branchId,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'default_currency': defaultCurrency,
        'credit_limit': creditLimit?.toString(),
        'credit_limit_currency': creditLimitCurrency,
        'status': status.name,
      };

  Customer copyWith({String? name, String? phone, String? address, String? notes, String? defaultCurrency,
          Decimal? creditLimit, String? creditLimitCurrency, CustomerStatus? status}) =>
      Customer(
        id: id,
        storeId: storeId,
        branchId: branchId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        creditLimit: creditLimit ?? this.creditLimit,
        creditLimitCurrency: creditLimitCurrency ?? this.creditLimitCurrency,
        status: status ?? this.status,
        updatedAt: DateTime.now(),
        serverSeq: serverSeq,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)} ${parts[1].substring(0, 1)}';
  }
}

/// حالة مزامنة الحركة على الجوال
enum SyncState { synced, pending, failed }

class LedgerTx {
  final String id;
  final String storeId;
  final String branchId;
  final String customerId;
  final TxKind kind;
  final Decimal amount;
  final String currency;
  final Decimal? fxPaidAmount;
  final String? fxPaidCurrency;
  final Decimal? fxRate;
  final String? voidedId;
  final String? voidReason;
  final String? description;
  final String? invoiceNo;
  final DateTime? dueDate;
  final String createdBy;
  final String? deviceId;
  final int? deviceSeq;
  final DateTime createdAt;
  final int? serverSeq;
  final SyncState sync;
  final String? syncError;

  /// المبلغ بإشارته كما يحسبه الخادم (للحركات المتزامنة)
  final Decimal? serverSignedAmount;

  const LedgerTx({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.customerId,
    required this.kind,
    required this.amount,
    required this.currency,
    this.fxPaidAmount,
    this.fxPaidCurrency,
    this.fxRate,
    this.voidedId,
    this.voidReason,
    this.description,
    this.invoiceNo,
    this.dueDate,
    required this.createdBy,
    this.deviceId,
    this.deviceSeq,
    required this.createdAt,
    this.serverSeq,
    this.sync = SyncState.pending,
    this.syncError,
    this.serverSignedAmount,
  });

  factory LedgerTx.fromJson(Map<String, dynamic> j) => LedgerTx(
        id: j['id'],
        storeId: j['store_id'],
        branchId: j['branch_id'],
        customerId: j['customer_id'],
        kind: TxKind.fromWire(j['kind']),
        amount: _dec(j['amount']),
        currency: j['currency'],
        fxPaidAmount: _decN(j['fx_paid_amount']),
        fxPaidCurrency: j['fx_paid_currency'],
        fxRate: _decN(j['fx_rate']),
        voidedId: j['voided_id'],
        voidReason: j['void_reason'],
        description: j['description'],
        invoiceNo: j['invoice_no'],
        dueDate: _dateN(j['due_date']),
        createdBy: j['created_by'],
        deviceId: j['device_id'],
        deviceSeq: j['device_seq'],
        createdAt: _dt(j['created_at']),
        serverSeq: j['server_seq'],
        sync: SyncState.synced,
        serverSignedAmount: _decN(j['signed_amount']),
      );

  /// صف الرفع لـ push_transactions (الخادم يتجاهل أي إشارة يرسلها الجوال)
  Map<String, dynamic> toPushRow() => {
        'id': id,
        'branch_id': branchId,
        'customer_id': customerId,
        'kind': kind.wire,
        'amount': amount.toString(),
        'currency': currency,
        if (fxPaidAmount != null) 'fx_paid_amount': fxPaidAmount.toString(),
        if (fxPaidCurrency != null) 'fx_paid_currency': fxPaidCurrency,
        if (fxRate != null) 'fx_rate': fxRate.toString(),
        if (voidedId != null) 'voided_id': voidedId,
        if (voidReason != null) 'void_reason': voidReason,
        if (description != null) 'description': description,
        if (invoiceNo != null) 'invoice_no': invoiceNo,
        if (dueDate != null) 'due_date': _dateStr(dueDate),
        'device_seq': deviceSeq,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  LedgerTx withSync(SyncState s, {int? serverSeq, String? error, Decimal? serverSigned}) => LedgerTx(
        id: id,
        storeId: storeId,
        branchId: branchId,
        customerId: customerId,
        kind: kind,
        amount: amount,
        currency: currency,
        fxPaidAmount: fxPaidAmount,
        fxPaidCurrency: fxPaidCurrency,
        fxRate: fxRate,
        voidedId: voidedId,
        voidReason: voidReason,
        description: description,
        invoiceNo: invoiceNo,
        dueDate: dueDate,
        createdBy: createdBy,
        deviceId: deviceId,
        deviceSeq: deviceSeq,
        createdAt: createdAt,
        serverSeq: serverSeq ?? this.serverSeq,
        sync: s,
        syncError: error,
        serverSignedAmount: serverSigned ?? serverSignedAmount,
      );
}

enum PromiseStatus { open, kept, cancelled }

class PaymentPromise {
  final String id;
  final String storeId;
  final String branchId;
  final String customerId;
  final DateTime promisedDate;
  final Decimal? amount;
  final String? currency;
  final String? note;
  final bool remindDayBefore;
  final bool remindCustomer;
  final PromiseStatus status;
  final int? serverSeq;

  const PaymentPromise({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.customerId,
    required this.promisedDate,
    this.amount,
    this.currency,
    this.note,
    this.remindDayBefore = false,
    this.remindCustomer = false,
    this.status = PromiseStatus.open,
    this.serverSeq,
  });

  factory PaymentPromise.fromJson(Map<String, dynamic> j) => PaymentPromise(
        id: j['id'],
        storeId: j['store_id'],
        branchId: j['branch_id'],
        customerId: j['customer_id'],
        promisedDate: DateTime.parse(j['promised_date']),
        amount: _decN(j['amount']),
        currency: j['currency'],
        note: j['note'],
        remindDayBefore: j['remind_day_before'] ?? false,
        remindCustomer: j['remind_customer'] ?? false,
        status: PromiseStatus.values.byName(j['status'] ?? 'open'),
        serverSeq: j['server_seq'],
      );

  Map<String, dynamic> toServer() => {
        'id': id,
        'store_id': storeId,
        'branch_id': branchId,
        'customer_id': customerId,
        'promised_date': _dateStr(promisedDate),
        'amount': amount?.toString(),
        'currency': currency,
        'note': note,
        'remind_day_before': remindDayBefore,
        'remind_customer': remindCustomer,
        'status': status.name,
      };

  bool isOverdue(DateTime today) =>
      status == PromiseStatus.open && DateTime(promisedDate.year, promisedDate.month, promisedDate.day)
          .isBefore(DateTime(today.year, today.month, today.day));
}

class Branch {
  final String id;
  final String code;
  final String name;
  const Branch(this.id, this.code, this.name);
  factory Branch.fromJson(Map<String, dynamic> j) => Branch(j['id'], j['code'], j['name']);
  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};
}

/// جلسة العمل: من، في أي بقالة وأي فرع، ومن أي جهاز
class WorkSession {
  final String storeId;
  final String storeName;
  final String storePhone;
  final String appUserId;
  final int userNo;
  final String displayName;
  final bool isOwner;
  final Branch branch;
  final String deviceId;
  final String deviceLetter;
  final List<String> enabledCurrencies;
  final String defaultCurrency;

  const WorkSession({
    required this.storeId,
    required this.storeName,
    required this.storePhone,
    required this.appUserId,
    required this.userNo,
    required this.displayName,
    required this.isOwner,
    required this.branch,
    required this.deviceId,
    required this.deviceLetter,
    required this.enabledCurrencies,
    required this.defaultCurrency,
  });

  /// بادئة أرقام الفواتير: فرع + جهاز (B1-A-0001)
  String invoicePrefix() => '${branch.code}-$deviceLetter-';

  /// يُحفظ محلياً بعد كل فتح ناجح ليعمل الجوال عند فتحه بدون نت
  Map<String, dynamic> toJson() => {
        'store_id': storeId,
        'store_name': storeName,
        'store_phone': storePhone,
        'app_user_id': appUserId,
        'user_no': userNo,
        'display_name': displayName,
        'is_owner': isOwner,
        'branch': branch.toJson(),
        'device_id': deviceId,
        'device_letter': deviceLetter,
        'currencies': enabledCurrencies,
        'default_currency': defaultCurrency,
      };

  factory WorkSession.fromJson(Map<String, dynamic> j) => WorkSession(
        storeId: j['store_id'],
        storeName: j['store_name'],
        storePhone: j['store_phone'],
        appUserId: j['app_user_id'],
        userNo: j['user_no'],
        displayName: j['display_name'],
        isOwner: j['is_owner'],
        branch: Branch.fromJson(Map<String, dynamic>.from(j['branch'])),
        deviceId: j['device_id'],
        deviceLetter: j['device_letter'],
        enabledCurrencies: List<String>.from(j['currencies']),
        defaultCurrency: j['default_currency'],
      );
}

