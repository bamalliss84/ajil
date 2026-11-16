import 'dart:convert';

import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import 'db.dart';

Decimal? _d(String? s) => s == null ? null : Decimal.parse(s);

extension CustomerRowX on CustomerRow {
  Customer toModel() => Customer(
        id: id,
        storeId: storeId,
        branchId: branchId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        defaultCurrency: defaultCurrency,
        creditLimit: _d(creditLimit),
        creditLimitCurrency: creditLimitCurrency,
        status: CustomerStatus.values.byName(status),
        updatedAt: updatedAt,
        serverSeq: serverSeq,
      );
}

extension CustomerModelX on Customer {
  LocalCustomersCompanion toCompanion({required bool dirty}) => LocalCustomersCompanion(
        id: Value(id),
        storeId: Value(storeId),
        branchId: Value(branchId),
        name: Value(name),
        phone: Value(phone),
        address: Value(address),
        notes: Value(notes),
        defaultCurrency: Value(defaultCurrency),
        creditLimit: Value(creditLimit?.toString()),
        creditLimitCurrency: Value(creditLimitCurrency),
        status: Value(status.name),
        updatedAt: Value(updatedAt),
        serverSeq: Value(serverSeq),
        dirty: Value(dirty),
      );
}

extension TxRowX on TxRow {
  LedgerTx toModel() => LedgerTx(
        id: id,
        storeId: storeId,
        branchId: branchId,
        customerId: customerId,
        kind: TxKind.fromWire(kind),
        amount: Decimal.parse(amount),
        currency: currency,
        fxPaidAmount: _d(fxPaidAmount),
        fxPaidCurrency: fxPaidCurrency,
        fxRate: _d(fxRate),
        voidedId: voidedId,
        voidReason: voidReason,
        description: description,
        invoiceNo: invoiceNo,
        dueDate: dueDate,
        createdBy: createdBy,
        deviceId: deviceId,
        deviceSeq: deviceSeq,
        createdAt: createdAt,
        serverSeq: serverSeq,
        sync: SyncState.values.byName(sync),
        syncError: syncError,
        serverSignedAmount: _d(signedAmount),
      );
}

extension TxModelX on LedgerTx {
  LocalTxsCompanion toCompanion() => LocalTxsCompanion(
        id: Value(id),
        storeId: Value(storeId),
        branchId: Value(branchId),
        customerId: Value(customerId),
        kind: Value(kind.wire),
        amount: Value(amount.toString()),
        currency: Value(currency),
        fxPaidAmount: Value(fxPaidAmount?.toString()),
        fxPaidCurrency: Value(fxPaidCurrency),
        fxRate: Value(fxRate?.toString()),
        voidedId: Value(voidedId),
        voidReason: Value(voidReason),
        description: Value(description),
        invoiceNo: Value(invoiceNo),
        dueDate: Value(dueDate),
        createdBy: Value(createdBy),
        deviceId: Value(deviceId),
        deviceSeq: Value(deviceSeq),
        createdAt: Value(createdAt),
        serverSeq: Value(serverSeq),
        signedAmount: Value(serverSignedAmount?.toString()),
        sync: Value(sync.name),
        syncError: Value(syncError),
      );
}

extension PromiseRowX on PromiseRow {
  PaymentPromise toModel() => PaymentPromise(
        id: id,
        storeId: storeId,
        branchId: branchId,
        customerId: customerId,
        promisedDate: promisedDate,
        amount: _d(amount),
        currency: currency,
        note: note,
        remindDayBefore: remindDayBefore,
        remindCustomer: remindCustomer,
        status: PromiseStatus.values.byName(status),
        serverSeq: serverSeq,
      );
}

extension PromiseModelX on PaymentPromise {
  LocalPromisesCompanion toCompanion({required bool dirty}) => LocalPromisesCompanion(
        id: Value(id),
        storeId: Value(storeId),
        branchId: Value(branchId),
        customerId: Value(customerId),
        promisedDate: Value(promisedDate),
        amount: Value(amount?.toString()),
        currency: Value(currency),
        note: Value(note),
        remindDayBefore: Value(remindDayBefore),
        remindCustomer: Value(remindCustomer),
        status: Value(status.name),
        serverSeq: Value(serverSeq),
        dirty: Value(dirty),
      );
}

extension NoticeRowX on NoticeRow {
  Map<String, Decimal> get balanceMap =>
      (jsonDecode(balances) as Map<String, dynamic>).map((k, v) => MapEntry(k, Decimal.parse(v as String)));

  Map<String, dynamic> toServer({required String storeId}) => {
        'id': id,
        'store_id': storeId,
        'branch_id': branchId,
        'customer_id': customerId,
        'batch_id': batchId,
        'as_of': asOf.toIso8601String().substring(0, 10),
        'balances': jsonDecode(balances),
        'sent_by': sentBy,
        'sent_at': sentAt.toUtc().toIso8601String(),
      };
}

/// رسالة أرسلها جهاز آخر (من الخادم) — تُحفظ محلياً غير متسخة
LocalNoticesCompanion noticeFromServer(Map<String, dynamic> j) => LocalNoticesCompanion.insert(
      id: j['id'] as String,
      branchId: j['branch_id'] as String,
      customerId: j['customer_id'] as String,
      batchId: j['batch_id'] as String,
      asOf: DateTime.parse(j['as_of'] as String),
      balances: jsonEncode(j['balances']),
      sentBy: j['sent_by'] as String,
      sentAt: DateTime.parse(j['sent_at'] as String).toLocal(),
      dirty: const Value(false),
    );
