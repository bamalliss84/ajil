// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultCurrencyMeta =
      const VerificationMeta('defaultCurrency');
  @override
  late final GeneratedColumn<String> defaultCurrency = GeneratedColumn<String>(
      'default_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _creditLimitMeta =
      const VerificationMeta('creditLimit');
  @override
  late final GeneratedColumn<String> creditLimit = GeneratedColumn<String>(
      'credit_limit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _creditLimitCurrencyMeta =
      const VerificationMeta('creditLimitCurrency');
  @override
  late final GeneratedColumn<String> creditLimitCurrency =
      GeneratedColumn<String>('credit_limit_currency', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _serverSeqMeta =
      const VerificationMeta('serverSeq');
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
      'server_seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        branchId,
        name,
        phone,
        address,
        notes,
        defaultCurrency,
        creditLimit,
        creditLimitCurrency,
        status,
        updatedAt,
        serverSeq,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(Insertable<CustomerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('default_currency')) {
      context.handle(
          _defaultCurrencyMeta,
          defaultCurrency.isAcceptableOrUnknown(
              data['default_currency']!, _defaultCurrencyMeta));
    } else if (isInserting) {
      context.missing(_defaultCurrencyMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
          _creditLimitMeta,
          creditLimit.isAcceptableOrUnknown(
              data['credit_limit']!, _creditLimitMeta));
    }
    if (data.containsKey('credit_limit_currency')) {
      context.handle(
          _creditLimitCurrencyMeta,
          creditLimitCurrency.isAcceptableOrUnknown(
              data['credit_limit_currency']!, _creditLimitCurrencyMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_seq')) {
      context.handle(_serverSeqMeta,
          serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      defaultCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_currency'])!,
      creditLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}credit_limit']),
      creditLimitCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}credit_limit_currency']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      serverSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_seq']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String storeId;
  final String branchId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final String defaultCurrency;
  final String? creditLimit;
  final String? creditLimitCurrency;
  final String status;
  final DateTime updatedAt;
  final int? serverSeq;
  final bool dirty;
  const CustomerRow(
      {required this.id,
      required this.storeId,
      required this.branchId,
      required this.name,
      this.phone,
      this.address,
      this.notes,
      required this.defaultCurrency,
      this.creditLimit,
      this.creditLimitCurrency,
      required this.status,
      required this.updatedAt,
      this.serverSeq,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['branch_id'] = Variable<String>(branchId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['default_currency'] = Variable<String>(defaultCurrency);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<String>(creditLimit);
    }
    if (!nullToAbsent || creditLimitCurrency != null) {
      map['credit_limit_currency'] = Variable<String>(creditLimitCurrency);
    }
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      storeId: Value(storeId),
      branchId: Value(branchId),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      defaultCurrency: Value(defaultCurrency),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      creditLimitCurrency: creditLimitCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitCurrency),
      status: Value(status),
      updatedAt: Value(updatedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      dirty: Value(dirty),
    );
  }

  factory CustomerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      notes: serializer.fromJson<String?>(json['notes']),
      defaultCurrency: serializer.fromJson<String>(json['defaultCurrency']),
      creditLimit: serializer.fromJson<String?>(json['creditLimit']),
      creditLimitCurrency:
          serializer.fromJson<String?>(json['creditLimitCurrency']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'branchId': serializer.toJson<String>(branchId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'notes': serializer.toJson<String?>(notes),
      'defaultCurrency': serializer.toJson<String>(defaultCurrency),
      'creditLimit': serializer.toJson<String?>(creditLimit),
      'creditLimitCurrency': serializer.toJson<String?>(creditLimitCurrency),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  CustomerRow copyWith(
          {String? id,
          String? storeId,
          String? branchId,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? defaultCurrency,
          Value<String?> creditLimit = const Value.absent(),
          Value<String?> creditLimitCurrency = const Value.absent(),
          String? status,
          DateTime? updatedAt,
          Value<int?> serverSeq = const Value.absent(),
          bool? dirty}) =>
      CustomerRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        notes: notes.present ? notes.value : this.notes,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
        creditLimitCurrency: creditLimitCurrency.present
            ? creditLimitCurrency.value
            : this.creditLimitCurrency,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
        dirty: dirty ?? this.dirty,
      );
  CustomerRow copyWithCompanion(LocalCustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      defaultCurrency: data.defaultCurrency.present
          ? data.defaultCurrency.value
          : this.defaultCurrency,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      creditLimitCurrency: data.creditLimitCurrency.present
          ? data.creditLimitCurrency.value
          : this.creditLimitCurrency,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('creditLimitCurrency: $creditLimitCurrency, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      storeId,
      branchId,
      name,
      phone,
      address,
      notes,
      defaultCurrency,
      creditLimit,
      creditLimitCurrency,
      status,
      updatedAt,
      serverSeq,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.defaultCurrency == this.defaultCurrency &&
          other.creditLimit == this.creditLimit &&
          other.creditLimitCurrency == this.creditLimitCurrency &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt &&
          other.serverSeq == this.serverSeq &&
          other.dirty == this.dirty);
}

class LocalCustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> branchId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> notes;
  final Value<String> defaultCurrency;
  final Value<String?> creditLimit;
  final Value<String?> creditLimitCurrency;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  final Value<int?> serverSeq;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.defaultCurrency = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.creditLimitCurrency = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    required String id,
    required String storeId,
    required String branchId,
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    required String defaultCurrency,
    this.creditLimit = const Value.absent(),
    this.creditLimitCurrency = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime updatedAt,
    this.serverSeq = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        branchId = Value(branchId),
        name = Value(name),
        defaultCurrency = Value(defaultCurrency),
        updatedAt = Value(updatedAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? branchId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<String>? defaultCurrency,
    Expression<String>? creditLimit,
    Expression<String>? creditLimitCurrency,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? serverSeq,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (creditLimitCurrency != null)
        'credit_limit_currency': creditLimitCurrency,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? branchId,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? address,
      Value<String?>? notes,
      Value<String>? defaultCurrency,
      Value<String?>? creditLimit,
      Value<String?>? creditLimitCurrency,
      Value<String>? status,
      Value<DateTime>? updatedAt,
      Value<int?>? serverSeq,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      creditLimit: creditLimit ?? this.creditLimit,
      creditLimitCurrency: creditLimitCurrency ?? this.creditLimitCurrency,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (defaultCurrency.present) {
      map['default_currency'] = Variable<String>(defaultCurrency.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<String>(creditLimit.value);
    }
    if (creditLimitCurrency.present) {
      map['credit_limit_currency'] =
          Variable<String>(creditLimitCurrency.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('creditLimitCurrency: $creditLimitCurrency, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTxsTable extends LocalTxs with TableInfo<$LocalTxsTable, TxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTxsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
      'amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fxPaidAmountMeta =
      const VerificationMeta('fxPaidAmount');
  @override
  late final GeneratedColumn<String> fxPaidAmount = GeneratedColumn<String>(
      'fx_paid_amount', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fxPaidCurrencyMeta =
      const VerificationMeta('fxPaidCurrency');
  @override
  late final GeneratedColumn<String> fxPaidCurrency = GeneratedColumn<String>(
      'fx_paid_currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  @override
  late final GeneratedColumn<String> fxRate = GeneratedColumn<String>(
      'fx_rate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voidedIdMeta =
      const VerificationMeta('voidedId');
  @override
  late final GeneratedColumn<String> voidedId = GeneratedColumn<String>(
      'voided_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voidReasonMeta =
      const VerificationMeta('voidReason');
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
      'void_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceNoMeta =
      const VerificationMeta('invoiceNo');
  @override
  late final GeneratedColumn<String> invoiceNo = GeneratedColumn<String>(
      'invoice_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviceSeqMeta =
      const VerificationMeta('deviceSeq');
  @override
  late final GeneratedColumn<int> deviceSeq = GeneratedColumn<int>(
      'device_seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _serverSeqMeta =
      const VerificationMeta('serverSeq');
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
      'server_seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _signedAmountMeta =
      const VerificationMeta('signedAmount');
  @override
  late final GeneratedColumn<String> signedAmount = GeneratedColumn<String>(
      'signed_amount', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncMeta = const VerificationMeta('sync');
  @override
  late final GeneratedColumn<String> sync = GeneratedColumn<String>(
      'sync', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        branchId,
        customerId,
        kind,
        amount,
        currency,
        fxPaidAmount,
        fxPaidCurrency,
        fxRate,
        voidedId,
        voidReason,
        description,
        invoiceNo,
        dueDate,
        createdBy,
        deviceId,
        deviceSeq,
        createdAt,
        serverSeq,
        signedAmount,
        sync,
        syncError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_txs';
  @override
  VerificationContext validateIntegrity(Insertable<TxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('fx_paid_amount')) {
      context.handle(
          _fxPaidAmountMeta,
          fxPaidAmount.isAcceptableOrUnknown(
              data['fx_paid_amount']!, _fxPaidAmountMeta));
    }
    if (data.containsKey('fx_paid_currency')) {
      context.handle(
          _fxPaidCurrencyMeta,
          fxPaidCurrency.isAcceptableOrUnknown(
              data['fx_paid_currency']!, _fxPaidCurrencyMeta));
    }
    if (data.containsKey('fx_rate')) {
      context.handle(_fxRateMeta,
          fxRate.isAcceptableOrUnknown(data['fx_rate']!, _fxRateMeta));
    }
    if (data.containsKey('voided_id')) {
      context.handle(_voidedIdMeta,
          voidedId.isAcceptableOrUnknown(data['voided_id']!, _voidedIdMeta));
    }
    if (data.containsKey('void_reason')) {
      context.handle(
          _voidReasonMeta,
          voidReason.isAcceptableOrUnknown(
              data['void_reason']!, _voidReasonMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('invoice_no')) {
      context.handle(_invoiceNoMeta,
          invoiceNo.isAcceptableOrUnknown(data['invoice_no']!, _invoiceNoMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    if (data.containsKey('device_seq')) {
      context.handle(_deviceSeqMeta,
          deviceSeq.isAcceptableOrUnknown(data['device_seq']!, _deviceSeqMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('server_seq')) {
      context.handle(_serverSeqMeta,
          serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta));
    }
    if (data.containsKey('signed_amount')) {
      context.handle(
          _signedAmountMeta,
          signedAmount.isAcceptableOrUnknown(
              data['signed_amount']!, _signedAmountMeta));
    }
    if (data.containsKey('sync')) {
      context.handle(
          _syncMeta, sync.isAcceptableOrUnknown(data['sync']!, _syncMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      fxPaidAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fx_paid_amount']),
      fxPaidCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fx_paid_currency']),
      fxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fx_rate']),
      voidedId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voided_id']),
      voidReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}void_reason']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      invoiceNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_no']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id']),
      deviceSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_seq']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      serverSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_seq']),
      signedAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signed_amount']),
      sync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync'])!,
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
    );
  }

  @override
  $LocalTxsTable createAlias(String alias) {
    return $LocalTxsTable(attachedDatabase, alias);
  }
}

class TxRow extends DataClass implements Insertable<TxRow> {
  final String id;
  final String storeId;
  final String branchId;
  final String customerId;
  final String kind;
  final String amount;
  final String currency;
  final String? fxPaidAmount;
  final String? fxPaidCurrency;
  final String? fxRate;
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
  final String? signedAmount;

  /// synced | pending | failed
  final String sync;
  final String? syncError;
  const TxRow(
      {required this.id,
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
      this.signedAmount,
      required this.sync,
      this.syncError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['branch_id'] = Variable<String>(branchId);
    map['customer_id'] = Variable<String>(customerId);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<String>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || fxPaidAmount != null) {
      map['fx_paid_amount'] = Variable<String>(fxPaidAmount);
    }
    if (!nullToAbsent || fxPaidCurrency != null) {
      map['fx_paid_currency'] = Variable<String>(fxPaidCurrency);
    }
    if (!nullToAbsent || fxRate != null) {
      map['fx_rate'] = Variable<String>(fxRate);
    }
    if (!nullToAbsent || voidedId != null) {
      map['voided_id'] = Variable<String>(voidedId);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || invoiceNo != null) {
      map['invoice_no'] = Variable<String>(invoiceNo);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || deviceSeq != null) {
      map['device_seq'] = Variable<int>(deviceSeq);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    if (!nullToAbsent || signedAmount != null) {
      map['signed_amount'] = Variable<String>(signedAmount);
    }
    map['sync'] = Variable<String>(sync);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  LocalTxsCompanion toCompanion(bool nullToAbsent) {
    return LocalTxsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      branchId: Value(branchId),
      customerId: Value(customerId),
      kind: Value(kind),
      amount: Value(amount),
      currency: Value(currency),
      fxPaidAmount: fxPaidAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(fxPaidAmount),
      fxPaidCurrency: fxPaidCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(fxPaidCurrency),
      fxRate:
          fxRate == null && nullToAbsent ? const Value.absent() : Value(fxRate),
      voidedId: voidedId == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedId),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      invoiceNo: invoiceNo == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNo),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      createdBy: Value(createdBy),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      deviceSeq: deviceSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceSeq),
      createdAt: Value(createdAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      signedAmount: signedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(signedAmount),
      sync: Value(sync),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory TxRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<String>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      fxPaidAmount: serializer.fromJson<String?>(json['fxPaidAmount']),
      fxPaidCurrency: serializer.fromJson<String?>(json['fxPaidCurrency']),
      fxRate: serializer.fromJson<String?>(json['fxRate']),
      voidedId: serializer.fromJson<String?>(json['voidedId']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      description: serializer.fromJson<String?>(json['description']),
      invoiceNo: serializer.fromJson<String?>(json['invoiceNo']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      deviceSeq: serializer.fromJson<int?>(json['deviceSeq']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      signedAmount: serializer.fromJson<String?>(json['signedAmount']),
      sync: serializer.fromJson<String>(json['sync']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'branchId': serializer.toJson<String>(branchId),
      'customerId': serializer.toJson<String>(customerId),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<String>(amount),
      'currency': serializer.toJson<String>(currency),
      'fxPaidAmount': serializer.toJson<String?>(fxPaidAmount),
      'fxPaidCurrency': serializer.toJson<String?>(fxPaidCurrency),
      'fxRate': serializer.toJson<String?>(fxRate),
      'voidedId': serializer.toJson<String?>(voidedId),
      'voidReason': serializer.toJson<String?>(voidReason),
      'description': serializer.toJson<String?>(description),
      'invoiceNo': serializer.toJson<String?>(invoiceNo),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'createdBy': serializer.toJson<String>(createdBy),
      'deviceId': serializer.toJson<String?>(deviceId),
      'deviceSeq': serializer.toJson<int?>(deviceSeq),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'signedAmount': serializer.toJson<String?>(signedAmount),
      'sync': serializer.toJson<String>(sync),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  TxRow copyWith(
          {String? id,
          String? storeId,
          String? branchId,
          String? customerId,
          String? kind,
          String? amount,
          String? currency,
          Value<String?> fxPaidAmount = const Value.absent(),
          Value<String?> fxPaidCurrency = const Value.absent(),
          Value<String?> fxRate = const Value.absent(),
          Value<String?> voidedId = const Value.absent(),
          Value<String?> voidReason = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> invoiceNo = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          String? createdBy,
          Value<String?> deviceId = const Value.absent(),
          Value<int?> deviceSeq = const Value.absent(),
          DateTime? createdAt,
          Value<int?> serverSeq = const Value.absent(),
          Value<String?> signedAmount = const Value.absent(),
          String? sync,
          Value<String?> syncError = const Value.absent()}) =>
      TxRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        branchId: branchId ?? this.branchId,
        customerId: customerId ?? this.customerId,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        fxPaidAmount:
            fxPaidAmount.present ? fxPaidAmount.value : this.fxPaidAmount,
        fxPaidCurrency:
            fxPaidCurrency.present ? fxPaidCurrency.value : this.fxPaidCurrency,
        fxRate: fxRate.present ? fxRate.value : this.fxRate,
        voidedId: voidedId.present ? voidedId.value : this.voidedId,
        voidReason: voidReason.present ? voidReason.value : this.voidReason,
        description: description.present ? description.value : this.description,
        invoiceNo: invoiceNo.present ? invoiceNo.value : this.invoiceNo,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        createdBy: createdBy ?? this.createdBy,
        deviceId: deviceId.present ? deviceId.value : this.deviceId,
        deviceSeq: deviceSeq.present ? deviceSeq.value : this.deviceSeq,
        createdAt: createdAt ?? this.createdAt,
        serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
        signedAmount:
            signedAmount.present ? signedAmount.value : this.signedAmount,
        sync: sync ?? this.sync,
        syncError: syncError.present ? syncError.value : this.syncError,
      );
  TxRow copyWithCompanion(LocalTxsCompanion data) {
    return TxRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxPaidAmount: data.fxPaidAmount.present
          ? data.fxPaidAmount.value
          : this.fxPaidAmount,
      fxPaidCurrency: data.fxPaidCurrency.present
          ? data.fxPaidCurrency.value
          : this.fxPaidCurrency,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      voidedId: data.voidedId.present ? data.voidedId.value : this.voidedId,
      voidReason:
          data.voidReason.present ? data.voidReason.value : this.voidReason,
      description:
          data.description.present ? data.description.value : this.description,
      invoiceNo: data.invoiceNo.present ? data.invoiceNo.value : this.invoiceNo,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceSeq: data.deviceSeq.present ? data.deviceSeq.value : this.deviceSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      signedAmount: data.signedAmount.present
          ? data.signedAmount.value
          : this.signedAmount,
      sync: data.sync.present ? data.sync.value : this.sync,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('fxPaidAmount: $fxPaidAmount, ')
          ..write('fxPaidCurrency: $fxPaidCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('voidedId: $voidedId, ')
          ..write('voidReason: $voidReason, ')
          ..write('description: $description, ')
          ..write('invoiceNo: $invoiceNo, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('signedAmount: $signedAmount, ')
          ..write('sync: $sync, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        storeId,
        branchId,
        customerId,
        kind,
        amount,
        currency,
        fxPaidAmount,
        fxPaidCurrency,
        fxRate,
        voidedId,
        voidReason,
        description,
        invoiceNo,
        dueDate,
        createdBy,
        deviceId,
        deviceSeq,
        createdAt,
        serverSeq,
        signedAmount,
        sync,
        syncError
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.branchId == this.branchId &&
          other.customerId == this.customerId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.fxPaidAmount == this.fxPaidAmount &&
          other.fxPaidCurrency == this.fxPaidCurrency &&
          other.fxRate == this.fxRate &&
          other.voidedId == this.voidedId &&
          other.voidReason == this.voidReason &&
          other.description == this.description &&
          other.invoiceNo == this.invoiceNo &&
          other.dueDate == this.dueDate &&
          other.createdBy == this.createdBy &&
          other.deviceId == this.deviceId &&
          other.deviceSeq == this.deviceSeq &&
          other.createdAt == this.createdAt &&
          other.serverSeq == this.serverSeq &&
          other.signedAmount == this.signedAmount &&
          other.sync == this.sync &&
          other.syncError == this.syncError);
}

class LocalTxsCompanion extends UpdateCompanion<TxRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> branchId;
  final Value<String> customerId;
  final Value<String> kind;
  final Value<String> amount;
  final Value<String> currency;
  final Value<String?> fxPaidAmount;
  final Value<String?> fxPaidCurrency;
  final Value<String?> fxRate;
  final Value<String?> voidedId;
  final Value<String?> voidReason;
  final Value<String?> description;
  final Value<String?> invoiceNo;
  final Value<DateTime?> dueDate;
  final Value<String> createdBy;
  final Value<String?> deviceId;
  final Value<int?> deviceSeq;
  final Value<DateTime> createdAt;
  final Value<int?> serverSeq;
  final Value<String?> signedAmount;
  final Value<String> sync;
  final Value<String?> syncError;
  final Value<int> rowid;
  const LocalTxsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxPaidAmount = const Value.absent(),
    this.fxPaidCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.voidedId = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.description = const Value.absent(),
    this.invoiceNo = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.signedAmount = const Value.absent(),
    this.sync = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTxsCompanion.insert({
    required String id,
    required String storeId,
    required String branchId,
    required String customerId,
    required String kind,
    required String amount,
    required String currency,
    this.fxPaidAmount = const Value.absent(),
    this.fxPaidCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.voidedId = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.description = const Value.absent(),
    this.invoiceNo = const Value.absent(),
    this.dueDate = const Value.absent(),
    required String createdBy,
    this.deviceId = const Value.absent(),
    this.deviceSeq = const Value.absent(),
    required DateTime createdAt,
    this.serverSeq = const Value.absent(),
    this.signedAmount = const Value.absent(),
    this.sync = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        branchId = Value(branchId),
        customerId = Value(customerId),
        kind = Value(kind),
        amount = Value(amount),
        currency = Value(currency),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt);
  static Insertable<TxRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? branchId,
    Expression<String>? customerId,
    Expression<String>? kind,
    Expression<String>? amount,
    Expression<String>? currency,
    Expression<String>? fxPaidAmount,
    Expression<String>? fxPaidCurrency,
    Expression<String>? fxRate,
    Expression<String>? voidedId,
    Expression<String>? voidReason,
    Expression<String>? description,
    Expression<String>? invoiceNo,
    Expression<DateTime>? dueDate,
    Expression<String>? createdBy,
    Expression<String>? deviceId,
    Expression<int>? deviceSeq,
    Expression<DateTime>? createdAt,
    Expression<int>? serverSeq,
    Expression<String>? signedAmount,
    Expression<String>? sync,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (fxPaidAmount != null) 'fx_paid_amount': fxPaidAmount,
      if (fxPaidCurrency != null) 'fx_paid_currency': fxPaidCurrency,
      if (fxRate != null) 'fx_rate': fxRate,
      if (voidedId != null) 'voided_id': voidedId,
      if (voidReason != null) 'void_reason': voidReason,
      if (description != null) 'description': description,
      if (invoiceNo != null) 'invoice_no': invoiceNo,
      if (dueDate != null) 'due_date': dueDate,
      if (createdBy != null) 'created_by': createdBy,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceSeq != null) 'device_seq': deviceSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (signedAmount != null) 'signed_amount': signedAmount,
      if (sync != null) 'sync': sync,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTxsCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? branchId,
      Value<String>? customerId,
      Value<String>? kind,
      Value<String>? amount,
      Value<String>? currency,
      Value<String?>? fxPaidAmount,
      Value<String?>? fxPaidCurrency,
      Value<String?>? fxRate,
      Value<String?>? voidedId,
      Value<String?>? voidReason,
      Value<String?>? description,
      Value<String?>? invoiceNo,
      Value<DateTime?>? dueDate,
      Value<String>? createdBy,
      Value<String?>? deviceId,
      Value<int?>? deviceSeq,
      Value<DateTime>? createdAt,
      Value<int?>? serverSeq,
      Value<String?>? signedAmount,
      Value<String>? sync,
      Value<String?>? syncError,
      Value<int>? rowid}) {
    return LocalTxsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      fxPaidAmount: fxPaidAmount ?? this.fxPaidAmount,
      fxPaidCurrency: fxPaidCurrency ?? this.fxPaidCurrency,
      fxRate: fxRate ?? this.fxRate,
      voidedId: voidedId ?? this.voidedId,
      voidReason: voidReason ?? this.voidReason,
      description: description ?? this.description,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      deviceId: deviceId ?? this.deviceId,
      deviceSeq: deviceSeq ?? this.deviceSeq,
      createdAt: createdAt ?? this.createdAt,
      serverSeq: serverSeq ?? this.serverSeq,
      signedAmount: signedAmount ?? this.signedAmount,
      sync: sync ?? this.sync,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxPaidAmount.present) {
      map['fx_paid_amount'] = Variable<String>(fxPaidAmount.value);
    }
    if (fxPaidCurrency.present) {
      map['fx_paid_currency'] = Variable<String>(fxPaidCurrency.value);
    }
    if (fxRate.present) {
      map['fx_rate'] = Variable<String>(fxRate.value);
    }
    if (voidedId.present) {
      map['voided_id'] = Variable<String>(voidedId.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (invoiceNo.present) {
      map['invoice_no'] = Variable<String>(invoiceNo.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceSeq.present) {
      map['device_seq'] = Variable<int>(deviceSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (signedAmount.present) {
      map['signed_amount'] = Variable<String>(signedAmount.value);
    }
    if (sync.present) {
      map['sync'] = Variable<String>(sync.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTxsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('fxPaidAmount: $fxPaidAmount, ')
          ..write('fxPaidCurrency: $fxPaidCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('voidedId: $voidedId, ')
          ..write('voidReason: $voidReason, ')
          ..write('description: $description, ')
          ..write('invoiceNo: $invoiceNo, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('signedAmount: $signedAmount, ')
          ..write('sync: $sync, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPromisesTable extends LocalPromises
    with TableInfo<$LocalPromisesTable, PromiseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPromisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promisedDateMeta =
      const VerificationMeta('promisedDate');
  @override
  late final GeneratedColumn<DateTime> promisedDate = GeneratedColumn<DateTime>(
      'promised_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
      'amount', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remindDayBeforeMeta =
      const VerificationMeta('remindDayBefore');
  @override
  late final GeneratedColumn<bool> remindDayBefore = GeneratedColumn<bool>(
      'remind_day_before', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remind_day_before" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remindCustomerMeta =
      const VerificationMeta('remindCustomer');
  @override
  late final GeneratedColumn<bool> remindCustomer = GeneratedColumn<bool>(
      'remind_customer', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remind_customer" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _serverSeqMeta =
      const VerificationMeta('serverSeq');
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
      'server_seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        branchId,
        customerId,
        promisedDate,
        amount,
        currency,
        note,
        remindDayBefore,
        remindCustomer,
        status,
        serverSeq,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_promises';
  @override
  VerificationContext validateIntegrity(Insertable<PromiseRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('promised_date')) {
      context.handle(
          _promisedDateMeta,
          promisedDate.isAcceptableOrUnknown(
              data['promised_date']!, _promisedDateMeta));
    } else if (isInserting) {
      context.missing(_promisedDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('remind_day_before')) {
      context.handle(
          _remindDayBeforeMeta,
          remindDayBefore.isAcceptableOrUnknown(
              data['remind_day_before']!, _remindDayBeforeMeta));
    }
    if (data.containsKey('remind_customer')) {
      context.handle(
          _remindCustomerMeta,
          remindCustomer.isAcceptableOrUnknown(
              data['remind_customer']!, _remindCustomerMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('server_seq')) {
      context.handle(_serverSeqMeta,
          serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromiseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromiseRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      promisedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}promised_date'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amount']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      remindDayBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}remind_day_before'])!,
      remindCustomer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}remind_customer'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      serverSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_seq']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LocalPromisesTable createAlias(String alias) {
    return $LocalPromisesTable(attachedDatabase, alias);
  }
}

class PromiseRow extends DataClass implements Insertable<PromiseRow> {
  final String id;
  final String storeId;
  final String branchId;
  final String customerId;
  final DateTime promisedDate;
  final String? amount;
  final String? currency;
  final String? note;
  final bool remindDayBefore;
  final bool remindCustomer;
  final String status;
  final int? serverSeq;
  final bool dirty;
  const PromiseRow(
      {required this.id,
      required this.storeId,
      required this.branchId,
      required this.customerId,
      required this.promisedDate,
      this.amount,
      this.currency,
      this.note,
      required this.remindDayBefore,
      required this.remindCustomer,
      required this.status,
      this.serverSeq,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['branch_id'] = Variable<String>(branchId);
    map['customer_id'] = Variable<String>(customerId);
    map['promised_date'] = Variable<DateTime>(promisedDate);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<String>(amount);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['remind_day_before'] = Variable<bool>(remindDayBefore);
    map['remind_customer'] = Variable<bool>(remindCustomer);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LocalPromisesCompanion toCompanion(bool nullToAbsent) {
    return LocalPromisesCompanion(
      id: Value(id),
      storeId: Value(storeId),
      branchId: Value(branchId),
      customerId: Value(customerId),
      promisedDate: Value(promisedDate),
      amount:
          amount == null && nullToAbsent ? const Value.absent() : Value(amount),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      remindDayBefore: Value(remindDayBefore),
      remindCustomer: Value(remindCustomer),
      status: Value(status),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      dirty: Value(dirty),
    );
  }

  factory PromiseRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromiseRow(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      promisedDate: serializer.fromJson<DateTime>(json['promisedDate']),
      amount: serializer.fromJson<String?>(json['amount']),
      currency: serializer.fromJson<String?>(json['currency']),
      note: serializer.fromJson<String?>(json['note']),
      remindDayBefore: serializer.fromJson<bool>(json['remindDayBefore']),
      remindCustomer: serializer.fromJson<bool>(json['remindCustomer']),
      status: serializer.fromJson<String>(json['status']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'branchId': serializer.toJson<String>(branchId),
      'customerId': serializer.toJson<String>(customerId),
      'promisedDate': serializer.toJson<DateTime>(promisedDate),
      'amount': serializer.toJson<String?>(amount),
      'currency': serializer.toJson<String?>(currency),
      'note': serializer.toJson<String?>(note),
      'remindDayBefore': serializer.toJson<bool>(remindDayBefore),
      'remindCustomer': serializer.toJson<bool>(remindCustomer),
      'status': serializer.toJson<String>(status),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  PromiseRow copyWith(
          {String? id,
          String? storeId,
          String? branchId,
          String? customerId,
          DateTime? promisedDate,
          Value<String?> amount = const Value.absent(),
          Value<String?> currency = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? remindDayBefore,
          bool? remindCustomer,
          String? status,
          Value<int?> serverSeq = const Value.absent(),
          bool? dirty}) =>
      PromiseRow(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        branchId: branchId ?? this.branchId,
        customerId: customerId ?? this.customerId,
        promisedDate: promisedDate ?? this.promisedDate,
        amount: amount.present ? amount.value : this.amount,
        currency: currency.present ? currency.value : this.currency,
        note: note.present ? note.value : this.note,
        remindDayBefore: remindDayBefore ?? this.remindDayBefore,
        remindCustomer: remindCustomer ?? this.remindCustomer,
        status: status ?? this.status,
        serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
        dirty: dirty ?? this.dirty,
      );
  PromiseRow copyWithCompanion(LocalPromisesCompanion data) {
    return PromiseRow(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      promisedDate: data.promisedDate.present
          ? data.promisedDate.value
          : this.promisedDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      note: data.note.present ? data.note.value : this.note,
      remindDayBefore: data.remindDayBefore.present
          ? data.remindDayBefore.value
          : this.remindDayBefore,
      remindCustomer: data.remindCustomer.present
          ? data.remindCustomer.value
          : this.remindCustomer,
      status: data.status.present ? data.status.value : this.status,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromiseRow(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('promisedDate: $promisedDate, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('remindDayBefore: $remindDayBefore, ')
          ..write('remindCustomer: $remindCustomer, ')
          ..write('status: $status, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      storeId,
      branchId,
      customerId,
      promisedDate,
      amount,
      currency,
      note,
      remindDayBefore,
      remindCustomer,
      status,
      serverSeq,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromiseRow &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.branchId == this.branchId &&
          other.customerId == this.customerId &&
          other.promisedDate == this.promisedDate &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.note == this.note &&
          other.remindDayBefore == this.remindDayBefore &&
          other.remindCustomer == this.remindCustomer &&
          other.status == this.status &&
          other.serverSeq == this.serverSeq &&
          other.dirty == this.dirty);
}

class LocalPromisesCompanion extends UpdateCompanion<PromiseRow> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> branchId;
  final Value<String> customerId;
  final Value<DateTime> promisedDate;
  final Value<String?> amount;
  final Value<String?> currency;
  final Value<String?> note;
  final Value<bool> remindDayBefore;
  final Value<bool> remindCustomer;
  final Value<String> status;
  final Value<int?> serverSeq;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LocalPromisesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.promisedDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.note = const Value.absent(),
    this.remindDayBefore = const Value.absent(),
    this.remindCustomer = const Value.absent(),
    this.status = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPromisesCompanion.insert({
    required String id,
    required String storeId,
    required String branchId,
    required String customerId,
    required DateTime promisedDate,
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.note = const Value.absent(),
    this.remindDayBefore = const Value.absent(),
    this.remindCustomer = const Value.absent(),
    this.status = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        storeId = Value(storeId),
        branchId = Value(branchId),
        customerId = Value(customerId),
        promisedDate = Value(promisedDate);
  static Insertable<PromiseRow> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? branchId,
    Expression<String>? customerId,
    Expression<DateTime>? promisedDate,
    Expression<String>? amount,
    Expression<String>? currency,
    Expression<String>? note,
    Expression<bool>? remindDayBefore,
    Expression<bool>? remindCustomer,
    Expression<String>? status,
    Expression<int>? serverSeq,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (promisedDate != null) 'promised_date': promisedDate,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (note != null) 'note': note,
      if (remindDayBefore != null) 'remind_day_before': remindDayBefore,
      if (remindCustomer != null) 'remind_customer': remindCustomer,
      if (status != null) 'status': status,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPromisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? storeId,
      Value<String>? branchId,
      Value<String>? customerId,
      Value<DateTime>? promisedDate,
      Value<String?>? amount,
      Value<String?>? currency,
      Value<String?>? note,
      Value<bool>? remindDayBefore,
      Value<bool>? remindCustomer,
      Value<String>? status,
      Value<int?>? serverSeq,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return LocalPromisesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      promisedDate: promisedDate ?? this.promisedDate,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      remindDayBefore: remindDayBefore ?? this.remindDayBefore,
      remindCustomer: remindCustomer ?? this.remindCustomer,
      status: status ?? this.status,
      serverSeq: serverSeq ?? this.serverSeq,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (promisedDate.present) {
      map['promised_date'] = Variable<DateTime>(promisedDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (remindDayBefore.present) {
      map['remind_day_before'] = Variable<bool>(remindDayBefore.value);
    }
    if (remindCustomer.present) {
      map['remind_customer'] = Variable<bool>(remindCustomer.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPromisesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('promisedDate: $promisedDate, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('remindDayBefore: $remindDayBefore, ')
          ..write('remindCustomer: $remindCustomer, ')
          ..write('status: $status, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues with TableInfo<$KeyValuesTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(Insertable<KvRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory KvRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) => KvRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KvRow copyWithCompanion(KeyValuesCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNoticesTable extends LocalNotices
    with TableInfo<$LocalNoticesTable, NoticeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNoticesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _batchIdMeta =
      const VerificationMeta('batchId');
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
      'batch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _asOfMeta = const VerificationMeta('asOf');
  @override
  late final GeneratedColumn<DateTime> asOf = GeneratedColumn<DateTime>(
      'as_of', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _balancesMeta =
      const VerificationMeta('balances');
  @override
  late final GeneratedColumn<String> balances = GeneratedColumn<String>(
      'balances', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentByMeta = const VerificationMeta('sentBy');
  @override
  late final GeneratedColumn<String> sentBy = GeneratedColumn<String>(
      'sent_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        branchId,
        customerId,
        batchId,
        asOf,
        balances,
        sentBy,
        sentAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notices';
  @override
  VerificationContext validateIntegrity(Insertable<NoticeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(_batchIdMeta,
          batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta));
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('as_of')) {
      context.handle(
          _asOfMeta, asOf.isAcceptableOrUnknown(data['as_of']!, _asOfMeta));
    } else if (isInserting) {
      context.missing(_asOfMeta);
    }
    if (data.containsKey('balances')) {
      context.handle(_balancesMeta,
          balances.isAcceptableOrUnknown(data['balances']!, _balancesMeta));
    } else if (isInserting) {
      context.missing(_balancesMeta);
    }
    if (data.containsKey('sent_by')) {
      context.handle(_sentByMeta,
          sentBy.isAcceptableOrUnknown(data['sent_by']!, _sentByMeta));
    } else if (isInserting) {
      context.missing(_sentByMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoticeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoticeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      batchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_id'])!,
      asOf: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}as_of'])!,
      balances: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}balances'])!,
      sentBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sent_by'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LocalNoticesTable createAlias(String alias) {
    return $LocalNoticesTable(attachedDatabase, alias);
  }
}

class NoticeRow extends DataClass implements Insertable<NoticeRow> {
  final String id;
  final String branchId;
  final String customerId;
  final String batchId;
  final DateTime asOf;
  final String balances;
  final String sentBy;
  final DateTime sentAt;
  final bool dirty;
  const NoticeRow(
      {required this.id,
      required this.branchId,
      required this.customerId,
      required this.batchId,
      required this.asOf,
      required this.balances,
      required this.sentBy,
      required this.sentAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['customer_id'] = Variable<String>(customerId);
    map['batch_id'] = Variable<String>(batchId);
    map['as_of'] = Variable<DateTime>(asOf);
    map['balances'] = Variable<String>(balances);
    map['sent_by'] = Variable<String>(sentBy);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LocalNoticesCompanion toCompanion(bool nullToAbsent) {
    return LocalNoticesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      customerId: Value(customerId),
      batchId: Value(batchId),
      asOf: Value(asOf),
      balances: Value(balances),
      sentBy: Value(sentBy),
      sentAt: Value(sentAt),
      dirty: Value(dirty),
    );
  }

  factory NoticeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoticeRow(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      asOf: serializer.fromJson<DateTime>(json['asOf']),
      balances: serializer.fromJson<String>(json['balances']),
      sentBy: serializer.fromJson<String>(json['sentBy']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'customerId': serializer.toJson<String>(customerId),
      'batchId': serializer.toJson<String>(batchId),
      'asOf': serializer.toJson<DateTime>(asOf),
      'balances': serializer.toJson<String>(balances),
      'sentBy': serializer.toJson<String>(sentBy),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  NoticeRow copyWith(
          {String? id,
          String? branchId,
          String? customerId,
          String? batchId,
          DateTime? asOf,
          String? balances,
          String? sentBy,
          DateTime? sentAt,
          bool? dirty}) =>
      NoticeRow(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        customerId: customerId ?? this.customerId,
        batchId: batchId ?? this.batchId,
        asOf: asOf ?? this.asOf,
        balances: balances ?? this.balances,
        sentBy: sentBy ?? this.sentBy,
        sentAt: sentAt ?? this.sentAt,
        dirty: dirty ?? this.dirty,
      );
  NoticeRow copyWithCompanion(LocalNoticesCompanion data) {
    return NoticeRow(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      asOf: data.asOf.present ? data.asOf.value : this.asOf,
      balances: data.balances.present ? data.balances.value : this.balances,
      sentBy: data.sentBy.present ? data.sentBy.value : this.sentBy,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoticeRow(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('batchId: $batchId, ')
          ..write('asOf: $asOf, ')
          ..write('balances: $balances, ')
          ..write('sentBy: $sentBy, ')
          ..write('sentAt: $sentAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, branchId, customerId, batchId, asOf, balances, sentBy, sentAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoticeRow &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.customerId == this.customerId &&
          other.batchId == this.batchId &&
          other.asOf == this.asOf &&
          other.balances == this.balances &&
          other.sentBy == this.sentBy &&
          other.sentAt == this.sentAt &&
          other.dirty == this.dirty);
}

class LocalNoticesCompanion extends UpdateCompanion<NoticeRow> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> customerId;
  final Value<String> batchId;
  final Value<DateTime> asOf;
  final Value<String> balances;
  final Value<String> sentBy;
  final Value<DateTime> sentAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LocalNoticesCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.asOf = const Value.absent(),
    this.balances = const Value.absent(),
    this.sentBy = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNoticesCompanion.insert({
    required String id,
    required String branchId,
    required String customerId,
    required String batchId,
    required DateTime asOf,
    required String balances,
    required String sentBy,
    required DateTime sentAt,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        branchId = Value(branchId),
        customerId = Value(customerId),
        batchId = Value(batchId),
        asOf = Value(asOf),
        balances = Value(balances),
        sentBy = Value(sentBy),
        sentAt = Value(sentAt);
  static Insertable<NoticeRow> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? customerId,
    Expression<String>? batchId,
    Expression<DateTime>? asOf,
    Expression<String>? balances,
    Expression<String>? sentBy,
    Expression<DateTime>? sentAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (batchId != null) 'batch_id': batchId,
      if (asOf != null) 'as_of': asOf,
      if (balances != null) 'balances': balances,
      if (sentBy != null) 'sent_by': sentBy,
      if (sentAt != null) 'sent_at': sentAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNoticesCompanion copyWith(
      {Value<String>? id,
      Value<String>? branchId,
      Value<String>? customerId,
      Value<String>? batchId,
      Value<DateTime>? asOf,
      Value<String>? balances,
      Value<String>? sentBy,
      Value<DateTime>? sentAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return LocalNoticesCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      batchId: batchId ?? this.batchId,
      asOf: asOf ?? this.asOf,
      balances: balances ?? this.balances,
      sentBy: sentBy ?? this.sentBy,
      sentAt: sentAt ?? this.sentAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (asOf.present) {
      map['as_of'] = Variable<DateTime>(asOf.value);
    }
    if (balances.present) {
      map['balances'] = Variable<String>(balances.value);
    }
    if (sentBy.present) {
      map['sent_by'] = Variable<String>(sentBy.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNoticesCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('batchId: $batchId, ')
          ..write('asOf: $asOf, ')
          ..write('balances: $balances, ')
          ..write('sentBy: $sentBy, ')
          ..write('sentAt: $sentAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalTxsTable localTxs = $LocalTxsTable(this);
  late final $LocalPromisesTable localPromises = $LocalPromisesTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $LocalNoticesTable localNotices = $LocalNoticesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localCustomers, localTxs, localPromises, keyValues, localNotices];
}

typedef $$LocalCustomersTableCreateCompanionBuilder = LocalCustomersCompanion
    Function({
  required String id,
  required String storeId,
  required String branchId,
  required String name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  required String defaultCurrency,
  Value<String?> creditLimit,
  Value<String?> creditLimitCurrency,
  Value<String> status,
  required DateTime updatedAt,
  Value<int?> serverSeq,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$LocalCustomersTableUpdateCompanionBuilder = LocalCustomersCompanion
    Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> branchId,
  Value<String> name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<String> defaultCurrency,
  Value<String?> creditLimit,
  Value<String?> creditLimitCurrency,
  Value<String> status,
  Value<DateTime> updatedAt,
  Value<int?> serverSeq,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$LocalCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultCurrency => $composableBuilder(
      column: $table.defaultCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creditLimitCurrency => $composableBuilder(
      column: $table.creditLimitCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LocalCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultCurrency => $composableBuilder(
      column: $table.defaultCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creditLimitCurrency => $composableBuilder(
      column: $table.creditLimitCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LocalCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get defaultCurrency => $composableBuilder(
      column: $table.defaultCurrency, builder: (column) => column);

  GeneratedColumn<String> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => column);

  GeneratedColumn<String> get creditLimitCurrency => $composableBuilder(
      column: $table.creditLimitCurrency, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LocalCustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalCustomersTable,
    CustomerRow,
    $$LocalCustomersTableFilterComposer,
    $$LocalCustomersTableOrderingComposer,
    $$LocalCustomersTableAnnotationComposer,
    $$LocalCustomersTableCreateCompanionBuilder,
    $$LocalCustomersTableUpdateCompanionBuilder,
    (
      CustomerRow,
      BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>
    ),
    CustomerRow,
    PrefetchHooks Function()> {
  $$LocalCustomersTableTableManager(
      _$AppDatabase db, $LocalCustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> defaultCurrency = const Value.absent(),
            Value<String?> creditLimit = const Value.absent(),
            Value<String?> creditLimitCurrency = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCustomersCompanion(
            id: id,
            storeId: storeId,
            branchId: branchId,
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            defaultCurrency: defaultCurrency,
            creditLimit: creditLimit,
            creditLimitCurrency: creditLimitCurrency,
            status: status,
            updatedAt: updatedAt,
            serverSeq: serverSeq,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String branchId,
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String defaultCurrency,
            Value<String?> creditLimit = const Value.absent(),
            Value<String?> creditLimitCurrency = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime updatedAt,
            Value<int?> serverSeq = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCustomersCompanion.insert(
            id: id,
            storeId: storeId,
            branchId: branchId,
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            defaultCurrency: defaultCurrency,
            creditLimit: creditLimit,
            creditLimitCurrency: creditLimitCurrency,
            status: status,
            updatedAt: updatedAt,
            serverSeq: serverSeq,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalCustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalCustomersTable,
    CustomerRow,
    $$LocalCustomersTableFilterComposer,
    $$LocalCustomersTableOrderingComposer,
    $$LocalCustomersTableAnnotationComposer,
    $$LocalCustomersTableCreateCompanionBuilder,
    $$LocalCustomersTableUpdateCompanionBuilder,
    (
      CustomerRow,
      BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>
    ),
    CustomerRow,
    PrefetchHooks Function()>;
typedef $$LocalTxsTableCreateCompanionBuilder = LocalTxsCompanion Function({
  required String id,
  required String storeId,
  required String branchId,
  required String customerId,
  required String kind,
  required String amount,
  required String currency,
  Value<String?> fxPaidAmount,
  Value<String?> fxPaidCurrency,
  Value<String?> fxRate,
  Value<String?> voidedId,
  Value<String?> voidReason,
  Value<String?> description,
  Value<String?> invoiceNo,
  Value<DateTime?> dueDate,
  required String createdBy,
  Value<String?> deviceId,
  Value<int?> deviceSeq,
  required DateTime createdAt,
  Value<int?> serverSeq,
  Value<String?> signedAmount,
  Value<String> sync,
  Value<String?> syncError,
  Value<int> rowid,
});
typedef $$LocalTxsTableUpdateCompanionBuilder = LocalTxsCompanion Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> branchId,
  Value<String> customerId,
  Value<String> kind,
  Value<String> amount,
  Value<String> currency,
  Value<String?> fxPaidAmount,
  Value<String?> fxPaidCurrency,
  Value<String?> fxRate,
  Value<String?> voidedId,
  Value<String?> voidReason,
  Value<String?> description,
  Value<String?> invoiceNo,
  Value<DateTime?> dueDate,
  Value<String> createdBy,
  Value<String?> deviceId,
  Value<int?> deviceSeq,
  Value<DateTime> createdAt,
  Value<int?> serverSeq,
  Value<String?> signedAmount,
  Value<String> sync,
  Value<String?> syncError,
  Value<int> rowid,
});

class $$LocalTxsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTxsTable> {
  $$LocalTxsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fxPaidAmount => $composableBuilder(
      column: $table.fxPaidAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fxPaidCurrency => $composableBuilder(
      column: $table.fxPaidCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fxRate => $composableBuilder(
      column: $table.fxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voidedId => $composableBuilder(
      column: $table.voidedId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceNo => $composableBuilder(
      column: $table.invoiceNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deviceSeq => $composableBuilder(
      column: $table.deviceSeq, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signedAmount => $composableBuilder(
      column: $table.signedAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sync => $composableBuilder(
      column: $table.sync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));
}

class $$LocalTxsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTxsTable> {
  $$LocalTxsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fxPaidAmount => $composableBuilder(
      column: $table.fxPaidAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fxPaidCurrency => $composableBuilder(
      column: $table.fxPaidCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fxRate => $composableBuilder(
      column: $table.fxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voidedId => $composableBuilder(
      column: $table.voidedId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceNo => $composableBuilder(
      column: $table.invoiceNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deviceSeq => $composableBuilder(
      column: $table.deviceSeq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signedAmount => $composableBuilder(
      column: $table.signedAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sync => $composableBuilder(
      column: $table.sync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));
}

class $$LocalTxsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTxsTable> {
  $$LocalTxsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get fxPaidAmount => $composableBuilder(
      column: $table.fxPaidAmount, builder: (column) => column);

  GeneratedColumn<String> get fxPaidCurrency => $composableBuilder(
      column: $table.fxPaidCurrency, builder: (column) => column);

  GeneratedColumn<String> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => column);

  GeneratedColumn<String> get voidedId =>
      $composableBuilder(column: $table.voidedId, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get invoiceNo =>
      $composableBuilder(column: $table.invoiceNo, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get deviceSeq =>
      $composableBuilder(column: $table.deviceSeq, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<String> get signedAmount => $composableBuilder(
      column: $table.signedAmount, builder: (column) => column);

  GeneratedColumn<String> get sync =>
      $composableBuilder(column: $table.sync, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$LocalTxsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTxsTable,
    TxRow,
    $$LocalTxsTableFilterComposer,
    $$LocalTxsTableOrderingComposer,
    $$LocalTxsTableAnnotationComposer,
    $$LocalTxsTableCreateCompanionBuilder,
    $$LocalTxsTableUpdateCompanionBuilder,
    (TxRow, BaseReferences<_$AppDatabase, $LocalTxsTable, TxRow>),
    TxRow,
    PrefetchHooks Function()> {
  $$LocalTxsTableTableManager(_$AppDatabase db, $LocalTxsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTxsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTxsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTxsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> fxPaidAmount = const Value.absent(),
            Value<String?> fxPaidCurrency = const Value.absent(),
            Value<String?> fxRate = const Value.absent(),
            Value<String?> voidedId = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> invoiceNo = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<int?> deviceSeq = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            Value<String?> signedAmount = const Value.absent(),
            Value<String> sync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTxsCompanion(
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
            serverSeq: serverSeq,
            signedAmount: signedAmount,
            sync: sync,
            syncError: syncError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String branchId,
            required String customerId,
            required String kind,
            required String amount,
            required String currency,
            Value<String?> fxPaidAmount = const Value.absent(),
            Value<String?> fxPaidCurrency = const Value.absent(),
            Value<String?> fxRate = const Value.absent(),
            Value<String?> voidedId = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> invoiceNo = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            required String createdBy,
            Value<String?> deviceId = const Value.absent(),
            Value<int?> deviceSeq = const Value.absent(),
            required DateTime createdAt,
            Value<int?> serverSeq = const Value.absent(),
            Value<String?> signedAmount = const Value.absent(),
            Value<String> sync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTxsCompanion.insert(
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
            serverSeq: serverSeq,
            signedAmount: signedAmount,
            sync: sync,
            syncError: syncError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTxsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTxsTable,
    TxRow,
    $$LocalTxsTableFilterComposer,
    $$LocalTxsTableOrderingComposer,
    $$LocalTxsTableAnnotationComposer,
    $$LocalTxsTableCreateCompanionBuilder,
    $$LocalTxsTableUpdateCompanionBuilder,
    (TxRow, BaseReferences<_$AppDatabase, $LocalTxsTable, TxRow>),
    TxRow,
    PrefetchHooks Function()>;
typedef $$LocalPromisesTableCreateCompanionBuilder = LocalPromisesCompanion
    Function({
  required String id,
  required String storeId,
  required String branchId,
  required String customerId,
  required DateTime promisedDate,
  Value<String?> amount,
  Value<String?> currency,
  Value<String?> note,
  Value<bool> remindDayBefore,
  Value<bool> remindCustomer,
  Value<String> status,
  Value<int?> serverSeq,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$LocalPromisesTableUpdateCompanionBuilder = LocalPromisesCompanion
    Function({
  Value<String> id,
  Value<String> storeId,
  Value<String> branchId,
  Value<String> customerId,
  Value<DateTime> promisedDate,
  Value<String?> amount,
  Value<String?> currency,
  Value<String?> note,
  Value<bool> remindDayBefore,
  Value<bool> remindCustomer,
  Value<String> status,
  Value<int?> serverSeq,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$LocalPromisesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPromisesTable> {
  $$LocalPromisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get promisedDate => $composableBuilder(
      column: $table.promisedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get remindCustomer => $composableBuilder(
      column: $table.remindCustomer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LocalPromisesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPromisesTable> {
  $$LocalPromisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get promisedDate => $composableBuilder(
      column: $table.promisedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get remindCustomer => $composableBuilder(
      column: $table.remindCustomer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverSeq => $composableBuilder(
      column: $table.serverSeq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LocalPromisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPromisesTable> {
  $$LocalPromisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<DateTime> get promisedDate => $composableBuilder(
      column: $table.promisedDate, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore, builder: (column) => column);

  GeneratedColumn<bool> get remindCustomer => $composableBuilder(
      column: $table.remindCustomer, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LocalPromisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPromisesTable,
    PromiseRow,
    $$LocalPromisesTableFilterComposer,
    $$LocalPromisesTableOrderingComposer,
    $$LocalPromisesTableAnnotationComposer,
    $$LocalPromisesTableCreateCompanionBuilder,
    $$LocalPromisesTableUpdateCompanionBuilder,
    (
      PromiseRow,
      BaseReferences<_$AppDatabase, $LocalPromisesTable, PromiseRow>
    ),
    PromiseRow,
    PrefetchHooks Function()> {
  $$LocalPromisesTableTableManager(_$AppDatabase db, $LocalPromisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPromisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPromisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPromisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<DateTime> promisedDate = const Value.absent(),
            Value<String?> amount = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> remindDayBefore = const Value.absent(),
            Value<bool> remindCustomer = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPromisesCompanion(
            id: id,
            storeId: storeId,
            branchId: branchId,
            customerId: customerId,
            promisedDate: promisedDate,
            amount: amount,
            currency: currency,
            note: note,
            remindDayBefore: remindDayBefore,
            remindCustomer: remindCustomer,
            status: status,
            serverSeq: serverSeq,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String storeId,
            required String branchId,
            required String customerId,
            required DateTime promisedDate,
            Value<String?> amount = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> remindDayBefore = const Value.absent(),
            Value<bool> remindCustomer = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPromisesCompanion.insert(
            id: id,
            storeId: storeId,
            branchId: branchId,
            customerId: customerId,
            promisedDate: promisedDate,
            amount: amount,
            currency: currency,
            note: note,
            remindDayBefore: remindDayBefore,
            remindCustomer: remindCustomer,
            status: status,
            serverSeq: serverSeq,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPromisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPromisesTable,
    PromiseRow,
    $$LocalPromisesTableFilterComposer,
    $$LocalPromisesTableOrderingComposer,
    $$LocalPromisesTableAnnotationComposer,
    $$LocalPromisesTableCreateCompanionBuilder,
    $$LocalPromisesTableUpdateCompanionBuilder,
    (
      PromiseRow,
      BaseReferences<_$AppDatabase, $LocalPromisesTable, PromiseRow>
    ),
    PromiseRow,
    PrefetchHooks Function()>;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeyValuesTable,
    KvRow,
    $$KeyValuesTableFilterComposer,
    $$KeyValuesTableOrderingComposer,
    $$KeyValuesTableAnnotationComposer,
    $$KeyValuesTableCreateCompanionBuilder,
    $$KeyValuesTableUpdateCompanionBuilder,
    (KvRow, BaseReferences<_$AppDatabase, $KeyValuesTable, KvRow>),
    KvRow,
    PrefetchHooks Function()> {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyValuesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyValuesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KeyValuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeyValuesTable,
    KvRow,
    $$KeyValuesTableFilterComposer,
    $$KeyValuesTableOrderingComposer,
    $$KeyValuesTableAnnotationComposer,
    $$KeyValuesTableCreateCompanionBuilder,
    $$KeyValuesTableUpdateCompanionBuilder,
    (KvRow, BaseReferences<_$AppDatabase, $KeyValuesTable, KvRow>),
    KvRow,
    PrefetchHooks Function()>;
typedef $$LocalNoticesTableCreateCompanionBuilder = LocalNoticesCompanion
    Function({
  required String id,
  required String branchId,
  required String customerId,
  required String batchId,
  required DateTime asOf,
  required String balances,
  required String sentBy,
  required DateTime sentAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$LocalNoticesTableUpdateCompanionBuilder = LocalNoticesCompanion
    Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> customerId,
  Value<String> batchId,
  Value<DateTime> asOf,
  Value<String> balances,
  Value<String> sentBy,
  Value<DateTime> sentAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$LocalNoticesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNoticesTable> {
  $$LocalNoticesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get asOf => $composableBuilder(
      column: $table.asOf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get balances => $composableBuilder(
      column: $table.balances, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentBy => $composableBuilder(
      column: $table.sentBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LocalNoticesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNoticesTable> {
  $$LocalNoticesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get asOf => $composableBuilder(
      column: $table.asOf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get balances => $composableBuilder(
      column: $table.balances, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentBy => $composableBuilder(
      column: $table.sentBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LocalNoticesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNoticesTable> {
  $$LocalNoticesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<DateTime> get asOf =>
      $composableBuilder(column: $table.asOf, builder: (column) => column);

  GeneratedColumn<String> get balances =>
      $composableBuilder(column: $table.balances, builder: (column) => column);

  GeneratedColumn<String> get sentBy =>
      $composableBuilder(column: $table.sentBy, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LocalNoticesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalNoticesTable,
    NoticeRow,
    $$LocalNoticesTableFilterComposer,
    $$LocalNoticesTableOrderingComposer,
    $$LocalNoticesTableAnnotationComposer,
    $$LocalNoticesTableCreateCompanionBuilder,
    $$LocalNoticesTableUpdateCompanionBuilder,
    (NoticeRow, BaseReferences<_$AppDatabase, $LocalNoticesTable, NoticeRow>),
    NoticeRow,
    PrefetchHooks Function()> {
  $$LocalNoticesTableTableManager(_$AppDatabase db, $LocalNoticesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNoticesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNoticesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNoticesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String> batchId = const Value.absent(),
            Value<DateTime> asOf = const Value.absent(),
            Value<String> balances = const Value.absent(),
            Value<String> sentBy = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoticesCompanion(
            id: id,
            branchId: branchId,
            customerId: customerId,
            batchId: batchId,
            asOf: asOf,
            balances: balances,
            sentBy: sentBy,
            sentAt: sentAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String branchId,
            required String customerId,
            required String batchId,
            required DateTime asOf,
            required String balances,
            required String sentBy,
            required DateTime sentAt,
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoticesCompanion.insert(
            id: id,
            branchId: branchId,
            customerId: customerId,
            batchId: batchId,
            asOf: asOf,
            balances: balances,
            sentBy: sentBy,
            sentAt: sentAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalNoticesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalNoticesTable,
    NoticeRow,
    $$LocalNoticesTableFilterComposer,
    $$LocalNoticesTableOrderingComposer,
    $$LocalNoticesTableAnnotationComposer,
    $$LocalNoticesTableCreateCompanionBuilder,
    $$LocalNoticesTableUpdateCompanionBuilder,
    (NoticeRow, BaseReferences<_$AppDatabase, $LocalNoticesTable, NoticeRow>),
    NoticeRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalTxsTableTableManager get localTxs =>
      $$LocalTxsTableTableManager(_db, _db.localTxs);
  $$LocalPromisesTableTableManager get localPromises =>
      $$LocalPromisesTableTableManager(_db, _db.localPromises);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$LocalNoticesTableTableManager get localNotices =>
      $$LocalNoticesTableTableManager(_db, _db.localNotices);
}
