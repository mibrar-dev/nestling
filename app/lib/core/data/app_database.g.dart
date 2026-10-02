// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FamiliesTable extends Families with TableInfo<$FamiliesTable, Family> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamiliesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Nestling'),
  );
  static const VerificationMeta _payoutDayMeta = const VerificationMeta(
    'payoutDay',
  );
  @override
  late final GeneratedColumn<int> payoutDay = GeneratedColumn<int>(
    'payout_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _coinValuePencePerCoinMeta =
      const VerificationMeta('coinValuePencePerCoin');
  @override
  late final GeneratedColumn<int> coinValuePencePerCoin = GeneratedColumn<int>(
    'coin_value_pence_per_coin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pocketMoneyModeMeta = const VerificationMeta(
    'pocketMoneyMode',
  );
  @override
  late final GeneratedColumn<String> pocketMoneyMode = GeneratedColumn<String>(
    'pocket_money_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('both'),
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtTzMeta = const VerificationMeta(
    'updatedAtTz',
  );
  @override
  late final GeneratedColumn<String> updatedAtTz = GeneratedColumn<String>(
    'updated_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    payoutDay,
    coinValuePencePerCoin,
    pocketMoneyMode,
    timeZone,
    updatedAt,
    updatedAtTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'families';
  @override
  VerificationContext validateIntegrity(
    Insertable<Family> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('payout_day')) {
      context.handle(
        _payoutDayMeta,
        payoutDay.isAcceptableOrUnknown(data['payout_day']!, _payoutDayMeta),
      );
    }
    if (data.containsKey('coin_value_pence_per_coin')) {
      context.handle(
        _coinValuePencePerCoinMeta,
        coinValuePencePerCoin.isAcceptableOrUnknown(
          data['coin_value_pence_per_coin']!,
          _coinValuePencePerCoinMeta,
        ),
      );
    }
    if (data.containsKey('pocket_money_mode')) {
      context.handle(
        _pocketMoneyModeMeta,
        pocketMoneyMode.isAcceptableOrUnknown(
          data['pocket_money_mode']!,
          _pocketMoneyModeMeta,
        ),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_at_tz')) {
      context.handle(
        _updatedAtTzMeta,
        updatedAtTz.isAcceptableOrUnknown(
          data['updated_at_tz']!,
          _updatedAtTzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Family map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Family(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payoutDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payout_day'],
      )!,
      coinValuePencePerCoin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coin_value_pence_per_coin'],
      )!,
      pocketMoneyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pocket_money_mode'],
      )!,
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      updatedAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at_tz'],
      )!,
    );
  }

  @override
  $FamiliesTable createAlias(String alias) {
    return $FamiliesTable(attachedDatabase, alias);
  }
}

class Family extends DataClass implements Insertable<Family> {
  final String id;
  final String name;
  final int payoutDay;
  final int coinValuePencePerCoin;
  final String pocketMoneyMode;
  final String timeZone;
  final DateTime? updatedAt;
  final String updatedAtTz;
  const Family({
    required this.id,
    required this.name,
    required this.payoutDay,
    required this.coinValuePencePerCoin,
    required this.pocketMoneyMode,
    required this.timeZone,
    this.updatedAt,
    required this.updatedAtTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['payout_day'] = Variable<int>(payoutDay);
    map['coin_value_pence_per_coin'] = Variable<int>(coinValuePencePerCoin);
    map['pocket_money_mode'] = Variable<String>(pocketMoneyMode);
    map['time_zone'] = Variable<String>(timeZone);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['updated_at_tz'] = Variable<String>(updatedAtTz);
    return map;
  }

  FamiliesCompanion toCompanion(bool nullToAbsent) {
    return FamiliesCompanion(
      id: Value(id),
      name: Value(name),
      payoutDay: Value(payoutDay),
      coinValuePencePerCoin: Value(coinValuePencePerCoin),
      pocketMoneyMode: Value(pocketMoneyMode),
      timeZone: Value(timeZone),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      updatedAtTz: Value(updatedAtTz),
    );
  }

  factory Family.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Family(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      payoutDay: serializer.fromJson<int>(json['payoutDay']),
      coinValuePencePerCoin: serializer.fromJson<int>(
        json['coinValuePencePerCoin'],
      ),
      pocketMoneyMode: serializer.fromJson<String>(json['pocketMoneyMode']),
      timeZone: serializer.fromJson<String>(json['timeZone']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      updatedAtTz: serializer.fromJson<String>(json['updatedAtTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'payoutDay': serializer.toJson<int>(payoutDay),
      'coinValuePencePerCoin': serializer.toJson<int>(coinValuePencePerCoin),
      'pocketMoneyMode': serializer.toJson<String>(pocketMoneyMode),
      'timeZone': serializer.toJson<String>(timeZone),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'updatedAtTz': serializer.toJson<String>(updatedAtTz),
    };
  }

  Family copyWith({
    String? id,
    String? name,
    int? payoutDay,
    int? coinValuePencePerCoin,
    String? pocketMoneyMode,
    String? timeZone,
    Value<DateTime?> updatedAt = const Value.absent(),
    String? updatedAtTz,
  }) => Family(
    id: id ?? this.id,
    name: name ?? this.name,
    payoutDay: payoutDay ?? this.payoutDay,
    coinValuePencePerCoin: coinValuePencePerCoin ?? this.coinValuePencePerCoin,
    pocketMoneyMode: pocketMoneyMode ?? this.pocketMoneyMode,
    timeZone: timeZone ?? this.timeZone,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    updatedAtTz: updatedAtTz ?? this.updatedAtTz,
  );
  Family copyWithCompanion(FamiliesCompanion data) {
    return Family(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      payoutDay: data.payoutDay.present ? data.payoutDay.value : this.payoutDay,
      coinValuePencePerCoin: data.coinValuePencePerCoin.present
          ? data.coinValuePencePerCoin.value
          : this.coinValuePencePerCoin,
      pocketMoneyMode: data.pocketMoneyMode.present
          ? data.pocketMoneyMode.value
          : this.pocketMoneyMode,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedAtTz: data.updatedAtTz.present
          ? data.updatedAtTz.value
          : this.updatedAtTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Family(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payoutDay: $payoutDay, ')
          ..write('coinValuePencePerCoin: $coinValuePencePerCoin, ')
          ..write('pocketMoneyMode: $pocketMoneyMode, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedAtTz: $updatedAtTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    payoutDay,
    coinValuePencePerCoin,
    pocketMoneyMode,
    timeZone,
    updatedAt,
    updatedAtTz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Family &&
          other.id == this.id &&
          other.name == this.name &&
          other.payoutDay == this.payoutDay &&
          other.coinValuePencePerCoin == this.coinValuePencePerCoin &&
          other.pocketMoneyMode == this.pocketMoneyMode &&
          other.timeZone == this.timeZone &&
          other.updatedAt == this.updatedAt &&
          other.updatedAtTz == this.updatedAtTz);
}

class FamiliesCompanion extends UpdateCompanion<Family> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> payoutDay;
  final Value<int> coinValuePencePerCoin;
  final Value<String> pocketMoneyMode;
  final Value<String> timeZone;
  final Value<DateTime?> updatedAt;
  final Value<String> updatedAtTz;
  final Value<int> rowid;
  const FamiliesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.payoutDay = const Value.absent(),
    this.coinValuePencePerCoin = const Value.absent(),
    this.pocketMoneyMode = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedAtTz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamiliesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.payoutDay = const Value.absent(),
    this.coinValuePencePerCoin = const Value.absent(),
    this.pocketMoneyMode = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedAtTz = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Family> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? payoutDay,
    Expression<int>? coinValuePencePerCoin,
    Expression<String>? pocketMoneyMode,
    Expression<String>? timeZone,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedAtTz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (payoutDay != null) 'payout_day': payoutDay,
      if (coinValuePencePerCoin != null)
        'coin_value_pence_per_coin': coinValuePencePerCoin,
      if (pocketMoneyMode != null) 'pocket_money_mode': pocketMoneyMode,
      if (timeZone != null) 'time_zone': timeZone,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedAtTz != null) 'updated_at_tz': updatedAtTz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamiliesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? payoutDay,
    Value<int>? coinValuePencePerCoin,
    Value<String>? pocketMoneyMode,
    Value<String>? timeZone,
    Value<DateTime?>? updatedAt,
    Value<String>? updatedAtTz,
    Value<int>? rowid,
  }) {
    return FamiliesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      payoutDay: payoutDay ?? this.payoutDay,
      coinValuePencePerCoin:
          coinValuePencePerCoin ?? this.coinValuePencePerCoin,
      pocketMoneyMode: pocketMoneyMode ?? this.pocketMoneyMode,
      timeZone: timeZone ?? this.timeZone,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedAtTz: updatedAtTz ?? this.updatedAtTz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payoutDay.present) {
      map['payout_day'] = Variable<int>(payoutDay.value);
    }
    if (coinValuePencePerCoin.present) {
      map['coin_value_pence_per_coin'] = Variable<int>(
        coinValuePencePerCoin.value,
      );
    }
    if (pocketMoneyMode.present) {
      map['pocket_money_mode'] = Variable<String>(pocketMoneyMode.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedAtTz.present) {
      map['updated_at_tz'] = Variable<String>(updatedAtTz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamiliesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payoutDay: $payoutDay, ')
          ..write('coinValuePencePerCoin: $coinValuePencePerCoin, ')
          ..write('pocketMoneyMode: $pocketMoneyMode, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedAtTz: $updatedAtTz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('owner'),
  );
  static const VerificationMeta _inviteStatusMeta = const VerificationMeta(
    'inviteStatus',
  );
  @override
  late final GeneratedColumn<String> inviteStatus = GeneratedColumn<String>(
    'invite_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    name,
    role,
    inviteStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('invite_status')) {
      context.handle(
        _inviteStatusMeta,
        inviteStatus.isAcceptableOrUnknown(
          data['invite_status']!,
          _inviteStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      inviteStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_status'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String familyId;
  final String name;
  final String role;
  final String inviteStatus;
  const Member({
    required this.id,
    required this.familyId,
    required this.name,
    required this.role,
    required this.inviteStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['invite_status'] = Variable<String>(inviteStatus);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      familyId: Value(familyId),
      name: Value(name),
      role: Value(role),
      inviteStatus: Value(inviteStatus),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      inviteStatus: serializer.fromJson<String>(json['inviteStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'inviteStatus': serializer.toJson<String>(inviteStatus),
    };
  }

  Member copyWith({
    String? id,
    String? familyId,
    String? name,
    String? role,
    String? inviteStatus,
  }) => Member(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    name: name ?? this.name,
    role: role ?? this.role,
    inviteStatus: inviteStatus ?? this.inviteStatus,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      inviteStatus: data.inviteStatus.present
          ? data.inviteStatus.value
          : this.inviteStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('inviteStatus: $inviteStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, familyId, name, role, inviteStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.name == this.name &&
          other.role == this.role &&
          other.inviteStatus == this.inviteStatus);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> name;
  final Value<String> role;
  final Value<String> inviteStatus;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.inviteStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String familyId,
    required String name,
    this.role = const Value.absent(),
    this.inviteStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       name = Value(name);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? inviteStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (inviteStatus != null) 'invite_status': inviteStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? name,
    Value<String>? role,
    Value<String>? inviteStatus,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      role: role ?? this.role,
      inviteStatus: inviteStatus ?? this.inviteStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (inviteStatus.present) {
      map['invite_status'] = Variable<String>(inviteStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('inviteStatus: $inviteStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildrenTable extends Children
    with TableInfo<$ChildrenTable, ChildrenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageBandMeta = const VerificationMeta(
    'ageBand',
  );
  @override
  late final GeneratedColumn<String> ageBand = GeneratedColumn<String>(
    'age_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('7-9'),
  );
  static const VerificationMeta _ageYearsMeta = const VerificationMeta(
    'ageYears',
  );
  @override
  late final GeneratedColumn<int> ageYears = GeneratedColumn<int>(
    'age_years',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _avatarColourMeta = const VerificationMeta(
    'avatarColour',
  );
  @override
  late final GeneratedColumn<String> avatarColour = GeneratedColumn<String>(
    'avatar_colour',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('lilac'),
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pipStyleMeta = const VerificationMeta(
    'pipStyle',
  );
  @override
  late final GeneratedColumn<String> pipStyle = GeneratedColumn<String>(
    'pip_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mochi'),
  );
  static const VerificationMeta _pipSkinMeta = const VerificationMeta(
    'pipSkin',
  );
  @override
  late final GeneratedColumn<String> pipSkin = GeneratedColumn<String>(
    'pip_skin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sunny'),
  );
  static const VerificationMeta _pipAccessoryMeta = const VerificationMeta(
    'pipAccessory',
  );
  @override
  late final GeneratedColumn<String> pipAccessory = GeneratedColumn<String>(
    'pip_accessory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _pipStageMeta = const VerificationMeta(
    'pipStage',
  );
  @override
  late final GeneratedColumn<int> pipStage = GeneratedColumn<int>(
    'pip_stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pipTotalCoinsMeta = const VerificationMeta(
    'pipTotalCoins',
  );
  @override
  late final GeneratedColumn<int> pipTotalCoins = GeneratedColumn<int>(
    'pip_total_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coinsMeta = const VerificationMeta('coins');
  @override
  late final GeneratedColumn<int> coins = GeneratedColumn<int>(
    'coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _happinessMeta = const VerificationMeta(
    'happiness',
  );
  @override
  late final GeneratedColumn<int> happiness = GeneratedColumn<int>(
    'happiness',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _happyDaysMeta = const VerificationMeta(
    'happyDays',
  );
  @override
  late final GeneratedColumn<int> happyDays = GeneratedColumn<int>(
    'happy_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weeklyBasePenceMeta = const VerificationMeta(
    'weeklyBasePence',
  );
  @override
  late final GeneratedColumn<int> weeklyBasePence = GeneratedColumn<int>(
    'weekly_base_pence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    nickname,
    ageBand,
    ageYears,
    avatarColour,
    pinHash,
    pipStyle,
    pipSkin,
    pipAccessory,
    pipStage,
    pipTotalCoins,
    coins,
    happiness,
    happyDays,
    weeklyBasePence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildrenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('age_band')) {
      context.handle(
        _ageBandMeta,
        ageBand.isAcceptableOrUnknown(data['age_band']!, _ageBandMeta),
      );
    }
    if (data.containsKey('age_years')) {
      context.handle(
        _ageYearsMeta,
        ageYears.isAcceptableOrUnknown(data['age_years']!, _ageYearsMeta),
      );
    }
    if (data.containsKey('avatar_colour')) {
      context.handle(
        _avatarColourMeta,
        avatarColour.isAcceptableOrUnknown(
          data['avatar_colour']!,
          _avatarColourMeta,
        ),
      );
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('pip_style')) {
      context.handle(
        _pipStyleMeta,
        pipStyle.isAcceptableOrUnknown(data['pip_style']!, _pipStyleMeta),
      );
    }
    if (data.containsKey('pip_skin')) {
      context.handle(
        _pipSkinMeta,
        pipSkin.isAcceptableOrUnknown(data['pip_skin']!, _pipSkinMeta),
      );
    }
    if (data.containsKey('pip_accessory')) {
      context.handle(
        _pipAccessoryMeta,
        pipAccessory.isAcceptableOrUnknown(
          data['pip_accessory']!,
          _pipAccessoryMeta,
        ),
      );
    }
    if (data.containsKey('pip_stage')) {
      context.handle(
        _pipStageMeta,
        pipStage.isAcceptableOrUnknown(data['pip_stage']!, _pipStageMeta),
      );
    }
    if (data.containsKey('pip_total_coins')) {
      context.handle(
        _pipTotalCoinsMeta,
        pipTotalCoins.isAcceptableOrUnknown(
          data['pip_total_coins']!,
          _pipTotalCoinsMeta,
        ),
      );
    }
    if (data.containsKey('coins')) {
      context.handle(
        _coinsMeta,
        coins.isAcceptableOrUnknown(data['coins']!, _coinsMeta),
      );
    }
    if (data.containsKey('happiness')) {
      context.handle(
        _happinessMeta,
        happiness.isAcceptableOrUnknown(data['happiness']!, _happinessMeta),
      );
    }
    if (data.containsKey('happy_days')) {
      context.handle(
        _happyDaysMeta,
        happyDays.isAcceptableOrUnknown(data['happy_days']!, _happyDaysMeta),
      );
    }
    if (data.containsKey('weekly_base_pence')) {
      context.handle(
        _weeklyBasePenceMeta,
        weeklyBasePence.isAcceptableOrUnknown(
          data['weekly_base_pence']!,
          _weeklyBasePenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChildrenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildrenData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      ageBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_band'],
      )!,
      ageYears: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age_years'],
      )!,
      avatarColour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_colour'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
      pipStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pip_style'],
      )!,
      pipSkin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pip_skin'],
      )!,
      pipAccessory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pip_accessory'],
      )!,
      pipStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pip_stage'],
      )!,
      pipTotalCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pip_total_coins'],
      )!,
      coins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins'],
      )!,
      happiness: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}happiness'],
      )!,
      happyDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}happy_days'],
      )!,
      weeklyBasePence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_base_pence'],
      )!,
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class ChildrenData extends DataClass implements Insertable<ChildrenData> {
  final String id;
  final String familyId;
  final String nickname;
  final String ageBand;
  final int ageYears;
  final String avatarColour;
  final String? pinHash;
  final String pipStyle;
  final String pipSkin;
  final String pipAccessory;
  final int pipStage;
  final int pipTotalCoins;
  final int coins;
  final int happiness;
  final int happyDays;
  final int weeklyBasePence;
  const ChildrenData({
    required this.id,
    required this.familyId,
    required this.nickname,
    required this.ageBand,
    required this.ageYears,
    required this.avatarColour,
    this.pinHash,
    required this.pipStyle,
    required this.pipSkin,
    required this.pipAccessory,
    required this.pipStage,
    required this.pipTotalCoins,
    required this.coins,
    required this.happiness,
    required this.happyDays,
    required this.weeklyBasePence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['nickname'] = Variable<String>(nickname);
    map['age_band'] = Variable<String>(ageBand);
    map['age_years'] = Variable<int>(ageYears);
    map['avatar_colour'] = Variable<String>(avatarColour);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['pip_style'] = Variable<String>(pipStyle);
    map['pip_skin'] = Variable<String>(pipSkin);
    map['pip_accessory'] = Variable<String>(pipAccessory);
    map['pip_stage'] = Variable<int>(pipStage);
    map['pip_total_coins'] = Variable<int>(pipTotalCoins);
    map['coins'] = Variable<int>(coins);
    map['happiness'] = Variable<int>(happiness);
    map['happy_days'] = Variable<int>(happyDays);
    map['weekly_base_pence'] = Variable<int>(weeklyBasePence);
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      familyId: Value(familyId),
      nickname: Value(nickname),
      ageBand: Value(ageBand),
      ageYears: Value(ageYears),
      avatarColour: Value(avatarColour),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      pipStyle: Value(pipStyle),
      pipSkin: Value(pipSkin),
      pipAccessory: Value(pipAccessory),
      pipStage: Value(pipStage),
      pipTotalCoins: Value(pipTotalCoins),
      coins: Value(coins),
      happiness: Value(happiness),
      happyDays: Value(happyDays),
      weeklyBasePence: Value(weeklyBasePence),
    );
  }

  factory ChildrenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildrenData(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      ageBand: serializer.fromJson<String>(json['ageBand']),
      ageYears: serializer.fromJson<int>(json['ageYears']),
      avatarColour: serializer.fromJson<String>(json['avatarColour']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      pipStyle: serializer.fromJson<String>(json['pipStyle']),
      pipSkin: serializer.fromJson<String>(json['pipSkin']),
      pipAccessory: serializer.fromJson<String>(json['pipAccessory']),
      pipStage: serializer.fromJson<int>(json['pipStage']),
      pipTotalCoins: serializer.fromJson<int>(json['pipTotalCoins']),
      coins: serializer.fromJson<int>(json['coins']),
      happiness: serializer.fromJson<int>(json['happiness']),
      happyDays: serializer.fromJson<int>(json['happyDays']),
      weeklyBasePence: serializer.fromJson<int>(json['weeklyBasePence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'nickname': serializer.toJson<String>(nickname),
      'ageBand': serializer.toJson<String>(ageBand),
      'ageYears': serializer.toJson<int>(ageYears),
      'avatarColour': serializer.toJson<String>(avatarColour),
      'pinHash': serializer.toJson<String?>(pinHash),
      'pipStyle': serializer.toJson<String>(pipStyle),
      'pipSkin': serializer.toJson<String>(pipSkin),
      'pipAccessory': serializer.toJson<String>(pipAccessory),
      'pipStage': serializer.toJson<int>(pipStage),
      'pipTotalCoins': serializer.toJson<int>(pipTotalCoins),
      'coins': serializer.toJson<int>(coins),
      'happiness': serializer.toJson<int>(happiness),
      'happyDays': serializer.toJson<int>(happyDays),
      'weeklyBasePence': serializer.toJson<int>(weeklyBasePence),
    };
  }

  ChildrenData copyWith({
    String? id,
    String? familyId,
    String? nickname,
    String? ageBand,
    int? ageYears,
    String? avatarColour,
    Value<String?> pinHash = const Value.absent(),
    String? pipStyle,
    String? pipSkin,
    String? pipAccessory,
    int? pipStage,
    int? pipTotalCoins,
    int? coins,
    int? happiness,
    int? happyDays,
    int? weeklyBasePence,
  }) => ChildrenData(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    nickname: nickname ?? this.nickname,
    ageBand: ageBand ?? this.ageBand,
    ageYears: ageYears ?? this.ageYears,
    avatarColour: avatarColour ?? this.avatarColour,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
    pipStyle: pipStyle ?? this.pipStyle,
    pipSkin: pipSkin ?? this.pipSkin,
    pipAccessory: pipAccessory ?? this.pipAccessory,
    pipStage: pipStage ?? this.pipStage,
    pipTotalCoins: pipTotalCoins ?? this.pipTotalCoins,
    coins: coins ?? this.coins,
    happiness: happiness ?? this.happiness,
    happyDays: happyDays ?? this.happyDays,
    weeklyBasePence: weeklyBasePence ?? this.weeklyBasePence,
  );
  ChildrenData copyWithCompanion(ChildrenCompanion data) {
    return ChildrenData(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      ageBand: data.ageBand.present ? data.ageBand.value : this.ageBand,
      ageYears: data.ageYears.present ? data.ageYears.value : this.ageYears,
      avatarColour: data.avatarColour.present
          ? data.avatarColour.value
          : this.avatarColour,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      pipStyle: data.pipStyle.present ? data.pipStyle.value : this.pipStyle,
      pipSkin: data.pipSkin.present ? data.pipSkin.value : this.pipSkin,
      pipAccessory: data.pipAccessory.present
          ? data.pipAccessory.value
          : this.pipAccessory,
      pipStage: data.pipStage.present ? data.pipStage.value : this.pipStage,
      pipTotalCoins: data.pipTotalCoins.present
          ? data.pipTotalCoins.value
          : this.pipTotalCoins,
      coins: data.coins.present ? data.coins.value : this.coins,
      happiness: data.happiness.present ? data.happiness.value : this.happiness,
      happyDays: data.happyDays.present ? data.happyDays.value : this.happyDays,
      weeklyBasePence: data.weeklyBasePence.present
          ? data.weeklyBasePence.value
          : this.weeklyBasePence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenData(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('nickname: $nickname, ')
          ..write('ageBand: $ageBand, ')
          ..write('ageYears: $ageYears, ')
          ..write('avatarColour: $avatarColour, ')
          ..write('pinHash: $pinHash, ')
          ..write('pipStyle: $pipStyle, ')
          ..write('pipSkin: $pipSkin, ')
          ..write('pipAccessory: $pipAccessory, ')
          ..write('pipStage: $pipStage, ')
          ..write('pipTotalCoins: $pipTotalCoins, ')
          ..write('coins: $coins, ')
          ..write('happiness: $happiness, ')
          ..write('happyDays: $happyDays, ')
          ..write('weeklyBasePence: $weeklyBasePence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    familyId,
    nickname,
    ageBand,
    ageYears,
    avatarColour,
    pinHash,
    pipStyle,
    pipSkin,
    pipAccessory,
    pipStage,
    pipTotalCoins,
    coins,
    happiness,
    happyDays,
    weeklyBasePence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildrenData &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.nickname == this.nickname &&
          other.ageBand == this.ageBand &&
          other.ageYears == this.ageYears &&
          other.avatarColour == this.avatarColour &&
          other.pinHash == this.pinHash &&
          other.pipStyle == this.pipStyle &&
          other.pipSkin == this.pipSkin &&
          other.pipAccessory == this.pipAccessory &&
          other.pipStage == this.pipStage &&
          other.pipTotalCoins == this.pipTotalCoins &&
          other.coins == this.coins &&
          other.happiness == this.happiness &&
          other.happyDays == this.happyDays &&
          other.weeklyBasePence == this.weeklyBasePence);
}

class ChildrenCompanion extends UpdateCompanion<ChildrenData> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> nickname;
  final Value<String> ageBand;
  final Value<int> ageYears;
  final Value<String> avatarColour;
  final Value<String?> pinHash;
  final Value<String> pipStyle;
  final Value<String> pipSkin;
  final Value<String> pipAccessory;
  final Value<int> pipStage;
  final Value<int> pipTotalCoins;
  final Value<int> coins;
  final Value<int> happiness;
  final Value<int> happyDays;
  final Value<int> weeklyBasePence;
  final Value<int> rowid;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.ageBand = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.avatarColour = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pipStyle = const Value.absent(),
    this.pipSkin = const Value.absent(),
    this.pipAccessory = const Value.absent(),
    this.pipStage = const Value.absent(),
    this.pipTotalCoins = const Value.absent(),
    this.coins = const Value.absent(),
    this.happiness = const Value.absent(),
    this.happyDays = const Value.absent(),
    this.weeklyBasePence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildrenCompanion.insert({
    required String id,
    required String familyId,
    required String nickname,
    this.ageBand = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.avatarColour = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pipStyle = const Value.absent(),
    this.pipSkin = const Value.absent(),
    this.pipAccessory = const Value.absent(),
    this.pipStage = const Value.absent(),
    this.pipTotalCoins = const Value.absent(),
    this.coins = const Value.absent(),
    this.happiness = const Value.absent(),
    this.happyDays = const Value.absent(),
    this.weeklyBasePence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       nickname = Value(nickname);
  static Insertable<ChildrenData> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? nickname,
    Expression<String>? ageBand,
    Expression<int>? ageYears,
    Expression<String>? avatarColour,
    Expression<String>? pinHash,
    Expression<String>? pipStyle,
    Expression<String>? pipSkin,
    Expression<String>? pipAccessory,
    Expression<int>? pipStage,
    Expression<int>? pipTotalCoins,
    Expression<int>? coins,
    Expression<int>? happiness,
    Expression<int>? happyDays,
    Expression<int>? weeklyBasePence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (nickname != null) 'nickname': nickname,
      if (ageBand != null) 'age_band': ageBand,
      if (ageYears != null) 'age_years': ageYears,
      if (avatarColour != null) 'avatar_colour': avatarColour,
      if (pinHash != null) 'pin_hash': pinHash,
      if (pipStyle != null) 'pip_style': pipStyle,
      if (pipSkin != null) 'pip_skin': pipSkin,
      if (pipAccessory != null) 'pip_accessory': pipAccessory,
      if (pipStage != null) 'pip_stage': pipStage,
      if (pipTotalCoins != null) 'pip_total_coins': pipTotalCoins,
      if (coins != null) 'coins': coins,
      if (happiness != null) 'happiness': happiness,
      if (happyDays != null) 'happy_days': happyDays,
      if (weeklyBasePence != null) 'weekly_base_pence': weeklyBasePence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildrenCompanion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? nickname,
    Value<String>? ageBand,
    Value<int>? ageYears,
    Value<String>? avatarColour,
    Value<String?>? pinHash,
    Value<String>? pipStyle,
    Value<String>? pipSkin,
    Value<String>? pipAccessory,
    Value<int>? pipStage,
    Value<int>? pipTotalCoins,
    Value<int>? coins,
    Value<int>? happiness,
    Value<int>? happyDays,
    Value<int>? weeklyBasePence,
    Value<int>? rowid,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      nickname: nickname ?? this.nickname,
      ageBand: ageBand ?? this.ageBand,
      ageYears: ageYears ?? this.ageYears,
      avatarColour: avatarColour ?? this.avatarColour,
      pinHash: pinHash ?? this.pinHash,
      pipStyle: pipStyle ?? this.pipStyle,
      pipSkin: pipSkin ?? this.pipSkin,
      pipAccessory: pipAccessory ?? this.pipAccessory,
      pipStage: pipStage ?? this.pipStage,
      pipTotalCoins: pipTotalCoins ?? this.pipTotalCoins,
      coins: coins ?? this.coins,
      happiness: happiness ?? this.happiness,
      happyDays: happyDays ?? this.happyDays,
      weeklyBasePence: weeklyBasePence ?? this.weeklyBasePence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (ageBand.present) {
      map['age_band'] = Variable<String>(ageBand.value);
    }
    if (ageYears.present) {
      map['age_years'] = Variable<int>(ageYears.value);
    }
    if (avatarColour.present) {
      map['avatar_colour'] = Variable<String>(avatarColour.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (pipStyle.present) {
      map['pip_style'] = Variable<String>(pipStyle.value);
    }
    if (pipSkin.present) {
      map['pip_skin'] = Variable<String>(pipSkin.value);
    }
    if (pipAccessory.present) {
      map['pip_accessory'] = Variable<String>(pipAccessory.value);
    }
    if (pipStage.present) {
      map['pip_stage'] = Variable<int>(pipStage.value);
    }
    if (pipTotalCoins.present) {
      map['pip_total_coins'] = Variable<int>(pipTotalCoins.value);
    }
    if (coins.present) {
      map['coins'] = Variable<int>(coins.value);
    }
    if (happiness.present) {
      map['happiness'] = Variable<int>(happiness.value);
    }
    if (happyDays.present) {
      map['happy_days'] = Variable<int>(happyDays.value);
    }
    if (weeklyBasePence.present) {
      map['weekly_base_pence'] = Variable<int>(weeklyBasePence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('nickname: $nickname, ')
          ..write('ageBand: $ageBand, ')
          ..write('ageYears: $ageYears, ')
          ..write('avatarColour: $avatarColour, ')
          ..write('pinHash: $pinHash, ')
          ..write('pipStyle: $pipStyle, ')
          ..write('pipSkin: $pipSkin, ')
          ..write('pipAccessory: $pipAccessory, ')
          ..write('pipStage: $pipStage, ')
          ..write('pipTotalCoins: $pipTotalCoins, ')
          ..write('coins: $coins, ')
          ..write('happiness: $happiness, ')
          ..write('happyDays: $happyDays, ')
          ..write('weeklyBasePence: $weeklyBasePence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestsTable extends Quests with TableInfo<$QuestsTable, Quest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('star'),
  );
  static const VerificationMeta _coinsMeta = const VerificationMeta('coins');
  @override
  late final GeneratedColumn<int> coins = GeneratedColumn<int>(
    'coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('once'),
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<String> days = GeneratedColumn<String>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dueLabelMeta = const VerificationMeta(
    'dueLabel',
  );
  @override
  late final GeneratedColumn<String> dueLabel = GeneratedColumn<String>(
    'due_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeLocalMeta = const VerificationMeta(
    'dueTimeLocal',
  );
  @override
  late final GeneratedColumn<String> dueTimeLocal = GeneratedColumn<String>(
    'due_time_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsApprovalMeta = const VerificationMeta(
    'needsApproval',
  );
  @override
  late final GeneratedColumn<bool> needsApproval = GeneratedColumn<bool>(
    'needs_approval',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_approval" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _assigneeChildIdMeta = const VerificationMeta(
    'assigneeChildId',
  );
  @override
  late final GeneratedColumn<String> assigneeChildId = GeneratedColumn<String>(
    'assignee_child_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    title,
    icon,
    coins,
    repeatRule,
    days,
    dueLabel,
    dueTimeLocal,
    needsApproval,
    assigneeChildId,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quests';
  @override
  VerificationContext validateIntegrity(
    Insertable<Quest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('coins')) {
      context.handle(
        _coinsMeta,
        coins.isAcceptableOrUnknown(data['coins']!, _coinsMeta),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    }
    if (data.containsKey('due_label')) {
      context.handle(
        _dueLabelMeta,
        dueLabel.isAcceptableOrUnknown(data['due_label']!, _dueLabelMeta),
      );
    }
    if (data.containsKey('due_time_local')) {
      context.handle(
        _dueTimeLocalMeta,
        dueTimeLocal.isAcceptableOrUnknown(
          data['due_time_local']!,
          _dueTimeLocalMeta,
        ),
      );
    }
    if (data.containsKey('needs_approval')) {
      context.handle(
        _needsApprovalMeta,
        needsApproval.isAcceptableOrUnknown(
          data['needs_approval']!,
          _needsApprovalMeta,
        ),
      );
    }
    if (data.containsKey('assignee_child_id')) {
      context.handle(
        _assigneeChildIdMeta,
        assigneeChildId.isAcceptableOrUnknown(
          data['assignee_child_id']!,
          _assigneeChildIdMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      coins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins'],
      )!,
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days'],
      )!,
      dueLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_label'],
      ),
      dueTimeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time_local'],
      ),
      needsApproval: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_approval'],
      )!,
      assigneeChildId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_child_id'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $QuestsTable createAlias(String alias) {
    return $QuestsTable(attachedDatabase, alias);
  }
}

class Quest extends DataClass implements Insertable<Quest> {
  final String id;
  final String familyId;
  final String title;
  final String icon;
  final int coins;
  final String repeatRule;
  final String days;
  final String? dueLabel;
  final String? dueTimeLocal;
  final bool needsApproval;
  final String? assigneeChildId;
  final bool active;
  const Quest({
    required this.id,
    required this.familyId,
    required this.title,
    required this.icon,
    required this.coins,
    required this.repeatRule,
    required this.days,
    this.dueLabel,
    this.dueTimeLocal,
    required this.needsApproval,
    this.assigneeChildId,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['title'] = Variable<String>(title);
    map['icon'] = Variable<String>(icon);
    map['coins'] = Variable<int>(coins);
    map['repeat_rule'] = Variable<String>(repeatRule);
    map['days'] = Variable<String>(days);
    if (!nullToAbsent || dueLabel != null) {
      map['due_label'] = Variable<String>(dueLabel);
    }
    if (!nullToAbsent || dueTimeLocal != null) {
      map['due_time_local'] = Variable<String>(dueTimeLocal);
    }
    map['needs_approval'] = Variable<bool>(needsApproval);
    if (!nullToAbsent || assigneeChildId != null) {
      map['assignee_child_id'] = Variable<String>(assigneeChildId);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  QuestsCompanion toCompanion(bool nullToAbsent) {
    return QuestsCompanion(
      id: Value(id),
      familyId: Value(familyId),
      title: Value(title),
      icon: Value(icon),
      coins: Value(coins),
      repeatRule: Value(repeatRule),
      days: Value(days),
      dueLabel: dueLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(dueLabel),
      dueTimeLocal: dueTimeLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTimeLocal),
      needsApproval: Value(needsApproval),
      assigneeChildId: assigneeChildId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeChildId),
      active: Value(active),
    );
  }

  factory Quest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quest(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String>(json['icon']),
      coins: serializer.fromJson<int>(json['coins']),
      repeatRule: serializer.fromJson<String>(json['repeatRule']),
      days: serializer.fromJson<String>(json['days']),
      dueLabel: serializer.fromJson<String?>(json['dueLabel']),
      dueTimeLocal: serializer.fromJson<String?>(json['dueTimeLocal']),
      needsApproval: serializer.fromJson<bool>(json['needsApproval']),
      assigneeChildId: serializer.fromJson<String?>(json['assigneeChildId']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String>(icon),
      'coins': serializer.toJson<int>(coins),
      'repeatRule': serializer.toJson<String>(repeatRule),
      'days': serializer.toJson<String>(days),
      'dueLabel': serializer.toJson<String?>(dueLabel),
      'dueTimeLocal': serializer.toJson<String?>(dueTimeLocal),
      'needsApproval': serializer.toJson<bool>(needsApproval),
      'assigneeChildId': serializer.toJson<String?>(assigneeChildId),
      'active': serializer.toJson<bool>(active),
    };
  }

  Quest copyWith({
    String? id,
    String? familyId,
    String? title,
    String? icon,
    int? coins,
    String? repeatRule,
    String? days,
    Value<String?> dueLabel = const Value.absent(),
    Value<String?> dueTimeLocal = const Value.absent(),
    bool? needsApproval,
    Value<String?> assigneeChildId = const Value.absent(),
    bool? active,
  }) => Quest(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    coins: coins ?? this.coins,
    repeatRule: repeatRule ?? this.repeatRule,
    days: days ?? this.days,
    dueLabel: dueLabel.present ? dueLabel.value : this.dueLabel,
    dueTimeLocal: dueTimeLocal.present ? dueTimeLocal.value : this.dueTimeLocal,
    needsApproval: needsApproval ?? this.needsApproval,
    assigneeChildId: assigneeChildId.present
        ? assigneeChildId.value
        : this.assigneeChildId,
    active: active ?? this.active,
  );
  Quest copyWithCompanion(QuestsCompanion data) {
    return Quest(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coins: data.coins.present ? data.coins.value : this.coins,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      days: data.days.present ? data.days.value : this.days,
      dueLabel: data.dueLabel.present ? data.dueLabel.value : this.dueLabel,
      dueTimeLocal: data.dueTimeLocal.present
          ? data.dueTimeLocal.value
          : this.dueTimeLocal,
      needsApproval: data.needsApproval.present
          ? data.needsApproval.value
          : this.needsApproval,
      assigneeChildId: data.assigneeChildId.present
          ? data.assigneeChildId.value
          : this.assigneeChildId,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quest(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coins: $coins, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('days: $days, ')
          ..write('dueLabel: $dueLabel, ')
          ..write('dueTimeLocal: $dueTimeLocal, ')
          ..write('needsApproval: $needsApproval, ')
          ..write('assigneeChildId: $assigneeChildId, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    familyId,
    title,
    icon,
    coins,
    repeatRule,
    days,
    dueLabel,
    dueTimeLocal,
    needsApproval,
    assigneeChildId,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quest &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coins == this.coins &&
          other.repeatRule == this.repeatRule &&
          other.days == this.days &&
          other.dueLabel == this.dueLabel &&
          other.dueTimeLocal == this.dueTimeLocal &&
          other.needsApproval == this.needsApproval &&
          other.assigneeChildId == this.assigneeChildId &&
          other.active == this.active);
}

class QuestsCompanion extends UpdateCompanion<Quest> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> title;
  final Value<String> icon;
  final Value<int> coins;
  final Value<String> repeatRule;
  final Value<String> days;
  final Value<String?> dueLabel;
  final Value<String?> dueTimeLocal;
  final Value<bool> needsApproval;
  final Value<String?> assigneeChildId;
  final Value<bool> active;
  final Value<int> rowid;
  const QuestsCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coins = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.days = const Value.absent(),
    this.dueLabel = const Value.absent(),
    this.dueTimeLocal = const Value.absent(),
    this.needsApproval = const Value.absent(),
    this.assigneeChildId = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestsCompanion.insert({
    required String id,
    required String familyId,
    required String title,
    this.icon = const Value.absent(),
    this.coins = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.days = const Value.absent(),
    this.dueLabel = const Value.absent(),
    this.dueTimeLocal = const Value.absent(),
    this.needsApproval = const Value.absent(),
    this.assigneeChildId = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       title = Value(title);
  static Insertable<Quest> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<int>? coins,
    Expression<String>? repeatRule,
    Expression<String>? days,
    Expression<String>? dueLabel,
    Expression<String>? dueTimeLocal,
    Expression<bool>? needsApproval,
    Expression<String>? assigneeChildId,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coins != null) 'coins': coins,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (days != null) 'days': days,
      if (dueLabel != null) 'due_label': dueLabel,
      if (dueTimeLocal != null) 'due_time_local': dueTimeLocal,
      if (needsApproval != null) 'needs_approval': needsApproval,
      if (assigneeChildId != null) 'assignee_child_id': assigneeChildId,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestsCompanion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? title,
    Value<String>? icon,
    Value<int>? coins,
    Value<String>? repeatRule,
    Value<String>? days,
    Value<String?>? dueLabel,
    Value<String?>? dueTimeLocal,
    Value<bool>? needsApproval,
    Value<String?>? assigneeChildId,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return QuestsCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coins: coins ?? this.coins,
      repeatRule: repeatRule ?? this.repeatRule,
      days: days ?? this.days,
      dueLabel: dueLabel ?? this.dueLabel,
      dueTimeLocal: dueTimeLocal ?? this.dueTimeLocal,
      needsApproval: needsApproval ?? this.needsApproval,
      assigneeChildId: assigneeChildId ?? this.assigneeChildId,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coins.present) {
      map['coins'] = Variable<int>(coins.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (days.present) {
      map['days'] = Variable<String>(days.value);
    }
    if (dueLabel.present) {
      map['due_label'] = Variable<String>(dueLabel.value);
    }
    if (dueTimeLocal.present) {
      map['due_time_local'] = Variable<String>(dueTimeLocal.value);
    }
    if (needsApproval.present) {
      map['needs_approval'] = Variable<bool>(needsApproval.value);
    }
    if (assigneeChildId.present) {
      map['assignee_child_id'] = Variable<String>(assigneeChildId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestsCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coins: $coins, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('days: $days, ')
          ..write('dueLabel: $dueLabel, ')
          ..write('dueTimeLocal: $dueTimeLocal, ')
          ..write('needsApproval: $needsApproval, ')
          ..write('assigneeChildId: $assigneeChildId, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestCompletionsTable extends QuestCompletions
    with TableInfo<$QuestCompletionsTable, QuestCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quests (id)',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('to_do'),
  );
  static const VerificationMeta _coinsMeta = const VerificationMeta('coins');
  @override
  late final GeneratedColumn<int> coins = GeneratedColumn<int>(
    'coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtTzMeta = const VerificationMeta(
    'createdAtTz',
  );
  @override
  late final GeneratedColumn<String> createdAtTz = GeneratedColumn<String>(
    'created_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decidedAtTzMeta = const VerificationMeta(
    'decidedAtTz',
  );
  @override
  late final GeneratedColumn<String> decidedAtTz = GeneratedColumn<String>(
    'decided_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questId,
    childId,
    familyId,
    status,
    coins,
    createdAt,
    createdAtTz,
    decidedAt,
    decidedAtTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('coins')) {
      context.handle(
        _coinsMeta,
        coins.isAcceptableOrUnknown(data['coins']!, _coinsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('created_at_tz')) {
      context.handle(
        _createdAtTzMeta,
        createdAtTz.isAcceptableOrUnknown(
          data['created_at_tz']!,
          _createdAtTzMeta,
        ),
      );
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('decided_at_tz')) {
      context.handle(
        _decidedAtTzMeta,
        decidedAtTz.isAcceptableOrUnknown(
          data['decided_at_tz']!,
          _decidedAtTzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestCompletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      coins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      createdAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at_tz'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      decidedAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_at_tz'],
      )!,
    );
  }

  @override
  $QuestCompletionsTable createAlias(String alias) {
    return $QuestCompletionsTable(attachedDatabase, alias);
  }
}

class QuestCompletion extends DataClass implements Insertable<QuestCompletion> {
  final int id;
  final String questId;
  final String childId;
  final String familyId;
  final String status;
  final int coins;
  final DateTime createdAt;
  final String createdAtTz;
  final DateTime? decidedAt;
  final String decidedAtTz;
  const QuestCompletion({
    required this.id,
    required this.questId,
    required this.childId,
    required this.familyId,
    required this.status,
    required this.coins,
    required this.createdAt,
    required this.createdAtTz,
    this.decidedAt,
    required this.decidedAtTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['quest_id'] = Variable<String>(questId);
    map['child_id'] = Variable<String>(childId);
    map['family_id'] = Variable<String>(familyId);
    map['status'] = Variable<String>(status);
    map['coins'] = Variable<int>(coins);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['created_at_tz'] = Variable<String>(createdAtTz);
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    map['decided_at_tz'] = Variable<String>(decidedAtTz);
    return map;
  }

  QuestCompletionsCompanion toCompanion(bool nullToAbsent) {
    return QuestCompletionsCompanion(
      id: Value(id),
      questId: Value(questId),
      childId: Value(childId),
      familyId: Value(familyId),
      status: Value(status),
      coins: Value(coins),
      createdAt: Value(createdAt),
      createdAtTz: Value(createdAtTz),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      decidedAtTz: Value(decidedAtTz),
    );
  }

  factory QuestCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestCompletion(
      id: serializer.fromJson<int>(json['id']),
      questId: serializer.fromJson<String>(json['questId']),
      childId: serializer.fromJson<String>(json['childId']),
      familyId: serializer.fromJson<String>(json['familyId']),
      status: serializer.fromJson<String>(json['status']),
      coins: serializer.fromJson<int>(json['coins']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdAtTz: serializer.fromJson<String>(json['createdAtTz']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      decidedAtTz: serializer.fromJson<String>(json['decidedAtTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questId': serializer.toJson<String>(questId),
      'childId': serializer.toJson<String>(childId),
      'familyId': serializer.toJson<String>(familyId),
      'status': serializer.toJson<String>(status),
      'coins': serializer.toJson<int>(coins),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdAtTz': serializer.toJson<String>(createdAtTz),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'decidedAtTz': serializer.toJson<String>(decidedAtTz),
    };
  }

  QuestCompletion copyWith({
    int? id,
    String? questId,
    String? childId,
    String? familyId,
    String? status,
    int? coins,
    DateTime? createdAt,
    String? createdAtTz,
    Value<DateTime?> decidedAt = const Value.absent(),
    String? decidedAtTz,
  }) => QuestCompletion(
    id: id ?? this.id,
    questId: questId ?? this.questId,
    childId: childId ?? this.childId,
    familyId: familyId ?? this.familyId,
    status: status ?? this.status,
    coins: coins ?? this.coins,
    createdAt: createdAt ?? this.createdAt,
    createdAtTz: createdAtTz ?? this.createdAtTz,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    decidedAtTz: decidedAtTz ?? this.decidedAtTz,
  );
  QuestCompletion copyWithCompanion(QuestCompletionsCompanion data) {
    return QuestCompletion(
      id: data.id.present ? data.id.value : this.id,
      questId: data.questId.present ? data.questId.value : this.questId,
      childId: data.childId.present ? data.childId.value : this.childId,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      status: data.status.present ? data.status.value : this.status,
      coins: data.coins.present ? data.coins.value : this.coins,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdAtTz: data.createdAtTz.present
          ? data.createdAtTz.value
          : this.createdAtTz,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      decidedAtTz: data.decidedAtTz.present
          ? data.decidedAtTz.value
          : this.decidedAtTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestCompletion(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('status: $status, ')
          ..write('coins: $coins, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdAtTz: $createdAtTz, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('decidedAtTz: $decidedAtTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questId,
    childId,
    familyId,
    status,
    coins,
    createdAt,
    createdAtTz,
    decidedAt,
    decidedAtTz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestCompletion &&
          other.id == this.id &&
          other.questId == this.questId &&
          other.childId == this.childId &&
          other.familyId == this.familyId &&
          other.status == this.status &&
          other.coins == this.coins &&
          other.createdAt == this.createdAt &&
          other.createdAtTz == this.createdAtTz &&
          other.decidedAt == this.decidedAt &&
          other.decidedAtTz == this.decidedAtTz);
}

class QuestCompletionsCompanion extends UpdateCompanion<QuestCompletion> {
  final Value<int> id;
  final Value<String> questId;
  final Value<String> childId;
  final Value<String> familyId;
  final Value<String> status;
  final Value<int> coins;
  final Value<DateTime> createdAt;
  final Value<String> createdAtTz;
  final Value<DateTime?> decidedAt;
  final Value<String> decidedAtTz;
  const QuestCompletionsCompanion({
    this.id = const Value.absent(),
    this.questId = const Value.absent(),
    this.childId = const Value.absent(),
    this.familyId = const Value.absent(),
    this.status = const Value.absent(),
    this.coins = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdAtTz = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.decidedAtTz = const Value.absent(),
  });
  QuestCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required String questId,
    required String childId,
    required String familyId,
    this.status = const Value.absent(),
    this.coins = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdAtTz = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.decidedAtTz = const Value.absent(),
  }) : questId = Value(questId),
       childId = Value(childId),
       familyId = Value(familyId);
  static Insertable<QuestCompletion> custom({
    Expression<int>? id,
    Expression<String>? questId,
    Expression<String>? childId,
    Expression<String>? familyId,
    Expression<String>? status,
    Expression<int>? coins,
    Expression<DateTime>? createdAt,
    Expression<String>? createdAtTz,
    Expression<DateTime>? decidedAt,
    Expression<String>? decidedAtTz,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questId != null) 'quest_id': questId,
      if (childId != null) 'child_id': childId,
      if (familyId != null) 'family_id': familyId,
      if (status != null) 'status': status,
      if (coins != null) 'coins': coins,
      if (createdAt != null) 'created_at': createdAt,
      if (createdAtTz != null) 'created_at_tz': createdAtTz,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (decidedAtTz != null) 'decided_at_tz': decidedAtTz,
    });
  }

  QuestCompletionsCompanion copyWith({
    Value<int>? id,
    Value<String>? questId,
    Value<String>? childId,
    Value<String>? familyId,
    Value<String>? status,
    Value<int>? coins,
    Value<DateTime>? createdAt,
    Value<String>? createdAtTz,
    Value<DateTime?>? decidedAt,
    Value<String>? decidedAtTz,
  }) {
    return QuestCompletionsCompanion(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      childId: childId ?? this.childId,
      familyId: familyId ?? this.familyId,
      status: status ?? this.status,
      coins: coins ?? this.coins,
      createdAt: createdAt ?? this.createdAt,
      createdAtTz: createdAtTz ?? this.createdAtTz,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedAtTz: decidedAtTz ?? this.decidedAtTz,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (coins.present) {
      map['coins'] = Variable<int>(coins.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdAtTz.present) {
      map['created_at_tz'] = Variable<String>(createdAtTz.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (decidedAtTz.present) {
      map['decided_at_tz'] = Variable<String>(decidedAtTz.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('questId: $questId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('status: $status, ')
          ..write('coins: $coins, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdAtTz: $createdAtTz, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('decidedAtTz: $decidedAtTz')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPenceMeta = const VerificationMeta(
    'amountPence',
  );
  @override
  late final GeneratedColumn<int> amountPence = GeneratedColumn<int>(
    'amount_pence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dateTzMeta = const VerificationMeta('dateTz');
  @override
  late final GeneratedColumn<String> dateTz = GeneratedColumn<String>(
    'date_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    childId,
    type,
    amountPence,
    note,
    date,
    dateTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_pence')) {
      context.handle(
        _amountPenceMeta,
        amountPence.isAcceptableOrUnknown(
          data['amount_pence']!,
          _amountPenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPenceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('date_tz')) {
      context.handle(
        _dateTzMeta,
        dateTz.isAcceptableOrUnknown(data['date_tz']!, _dateTzMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountPence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_pence'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      dateTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_tz'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final int id;
  final String familyId;
  final String childId;
  final String type;
  final int amountPence;
  final String note;
  final DateTime date;
  final String dateTz;
  const LedgerEntry({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.type,
    required this.amountPence,
    required this.note,
    required this.date,
    required this.dateTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['family_id'] = Variable<String>(familyId);
    map['child_id'] = Variable<String>(childId);
    map['type'] = Variable<String>(type);
    map['amount_pence'] = Variable<int>(amountPence);
    map['note'] = Variable<String>(note);
    map['date'] = Variable<DateTime>(date);
    map['date_tz'] = Variable<String>(dateTz);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      familyId: Value(familyId),
      childId: Value(childId),
      type: Value(type),
      amountPence: Value(amountPence),
      note: Value(note),
      date: Value(date),
      dateTz: Value(dateTz),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      childId: serializer.fromJson<String>(json['childId']),
      type: serializer.fromJson<String>(json['type']),
      amountPence: serializer.fromJson<int>(json['amountPence']),
      note: serializer.fromJson<String>(json['note']),
      date: serializer.fromJson<DateTime>(json['date']),
      dateTz: serializer.fromJson<String>(json['dateTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'familyId': serializer.toJson<String>(familyId),
      'childId': serializer.toJson<String>(childId),
      'type': serializer.toJson<String>(type),
      'amountPence': serializer.toJson<int>(amountPence),
      'note': serializer.toJson<String>(note),
      'date': serializer.toJson<DateTime>(date),
      'dateTz': serializer.toJson<String>(dateTz),
    };
  }

  LedgerEntry copyWith({
    int? id,
    String? familyId,
    String? childId,
    String? type,
    int? amountPence,
    String? note,
    DateTime? date,
    String? dateTz,
  }) => LedgerEntry(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    childId: childId ?? this.childId,
    type: type ?? this.type,
    amountPence: amountPence ?? this.amountPence,
    note: note ?? this.note,
    date: date ?? this.date,
    dateTz: dateTz ?? this.dateTz,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      childId: data.childId.present ? data.childId.value : this.childId,
      type: data.type.present ? data.type.value : this.type,
      amountPence: data.amountPence.present
          ? data.amountPence.value
          : this.amountPence,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      dateTz: data.dateTz.present ? data.dateTz.value : this.dateTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('type: $type, ')
          ..write('amountPence: $amountPence, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('dateTz: $dateTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, familyId, childId, type, amountPence, note, date, dateTz);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.childId == this.childId &&
          other.type == this.type &&
          other.amountPence == this.amountPence &&
          other.note == this.note &&
          other.date == this.date &&
          other.dateTz == this.dateTz);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<String> familyId;
  final Value<String> childId;
  final Value<String> type;
  final Value<int> amountPence;
  final Value<String> note;
  final Value<DateTime> date;
  final Value<String> dateTz;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.childId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountPence = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.dateTz = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String familyId,
    required String childId,
    required String type,
    required int amountPence,
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.dateTz = const Value.absent(),
  }) : familyId = Value(familyId),
       childId = Value(childId),
       type = Value(type),
       amountPence = Value(amountPence);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<String>? familyId,
    Expression<String>? childId,
    Expression<String>? type,
    Expression<int>? amountPence,
    Expression<String>? note,
    Expression<DateTime>? date,
    Expression<String>? dateTz,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (childId != null) 'child_id': childId,
      if (type != null) 'type': type,
      if (amountPence != null) 'amount_pence': amountPence,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (dateTz != null) 'date_tz': dateTz,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? familyId,
    Value<String>? childId,
    Value<String>? type,
    Value<int>? amountPence,
    Value<String>? note,
    Value<DateTime>? date,
    Value<String>? dateTz,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      amountPence: amountPence ?? this.amountPence,
      note: note ?? this.note,
      date: date ?? this.date,
      dateTz: dateTz ?? this.dateTz,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountPence.present) {
      map['amount_pence'] = Variable<int>(amountPence.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (dateTz.present) {
      map['date_tz'] = Variable<String>(dateTz.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('type: $type, ')
          ..write('amountPence: $amountPence, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('dateTz: $dateTz')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPenceMeta = const VerificationMeta(
    'targetPence',
  );
  @override
  late final GeneratedColumn<int> targetPence = GeneratedColumn<int>(
    'target_pence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedPenceMeta = const VerificationMeta(
    'savedPence',
  );
  @override
  late final GeneratedColumn<int> savedPence = GeneratedColumn<int>(
    'saved_pence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    childId,
    title,
    targetPence,
    savedPence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_pence')) {
      context.handle(
        _targetPenceMeta,
        targetPence.isAcceptableOrUnknown(
          data['target_pence']!,
          _targetPenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPenceMeta);
    }
    if (data.containsKey('saved_pence')) {
      context.handle(
        _savedPenceMeta,
        savedPence.isAcceptableOrUnknown(data['saved_pence']!, _savedPenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetPence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_pence'],
      )!,
      savedPence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_pence'],
      )!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final String id;
  final String familyId;
  final String childId;
  final String title;
  final int targetPence;
  final int savedPence;
  const SavingsGoal({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.title,
    required this.targetPence,
    required this.savedPence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['child_id'] = Variable<String>(childId);
    map['title'] = Variable<String>(title);
    map['target_pence'] = Variable<int>(targetPence);
    map['saved_pence'] = Variable<int>(savedPence);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      familyId: Value(familyId),
      childId: Value(childId),
      title: Value(title),
      targetPence: Value(targetPence),
      savedPence: Value(savedPence),
    );
  }

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      childId: serializer.fromJson<String>(json['childId']),
      title: serializer.fromJson<String>(json['title']),
      targetPence: serializer.fromJson<int>(json['targetPence']),
      savedPence: serializer.fromJson<int>(json['savedPence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'childId': serializer.toJson<String>(childId),
      'title': serializer.toJson<String>(title),
      'targetPence': serializer.toJson<int>(targetPence),
      'savedPence': serializer.toJson<int>(savedPence),
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? familyId,
    String? childId,
    String? title,
    int? targetPence,
    int? savedPence,
  }) => SavingsGoal(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    childId: childId ?? this.childId,
    title: title ?? this.title,
    targetPence: targetPence ?? this.targetPence,
    savedPence: savedPence ?? this.savedPence,
  );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      childId: data.childId.present ? data.childId.value : this.childId,
      title: data.title.present ? data.title.value : this.title,
      targetPence: data.targetPence.present
          ? data.targetPence.value
          : this.targetPence,
      savedPence: data.savedPence.present
          ? data.savedPence.value
          : this.savedPence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('title: $title, ')
          ..write('targetPence: $targetPence, ')
          ..write('savedPence: $savedPence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, familyId, childId, title, targetPence, savedPence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.childId == this.childId &&
          other.title == this.title &&
          other.targetPence == this.targetPence &&
          other.savedPence == this.savedPence);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> childId;
  final Value<String> title;
  final Value<int> targetPence;
  final Value<int> savedPence;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.childId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetPence = const Value.absent(),
    this.savedPence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    required String id,
    required String familyId,
    required String childId,
    required String title,
    required int targetPence,
    this.savedPence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       childId = Value(childId),
       title = Value(title),
       targetPence = Value(targetPence);
  static Insertable<SavingsGoal> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? childId,
    Expression<String>? title,
    Expression<int>? targetPence,
    Expression<int>? savedPence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (childId != null) 'child_id': childId,
      if (title != null) 'title': title,
      if (targetPence != null) 'target_pence': targetPence,
      if (savedPence != null) 'saved_pence': savedPence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? childId,
    Value<String>? title,
    Value<int>? targetPence,
    Value<int>? savedPence,
    Value<int>? rowid,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      targetPence: targetPence ?? this.targetPence,
      savedPence: savedPence ?? this.savedPence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetPence.present) {
      map['target_pence'] = Variable<int>(targetPence.value);
    }
    if (savedPence.present) {
      map['saved_pence'] = Variable<int>(savedPence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('title: $title, ')
          ..write('targetPence: $targetPence, ')
          ..write('savedPence: $savedPence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RewardsTable extends Rewards with TableInfo<$RewardsTable, Reward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RewardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gift'),
  );
  static const VerificationMeta _coinPriceMeta = const VerificationMeta(
    'coinPrice',
  );
  @override
  late final GeneratedColumn<int> coinPrice = GeneratedColumn<int>(
    'coin_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsOkMeta = const VerificationMeta(
    'needsOk',
  );
  @override
  late final GeneratedColumn<bool> needsOk = GeneratedColumn<bool>(
    'needs_ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_ok" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    title,
    icon,
    coinPrice,
    needsOk,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rewards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reward> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('coin_price')) {
      context.handle(
        _coinPriceMeta,
        coinPrice.isAcceptableOrUnknown(data['coin_price']!, _coinPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_coinPriceMeta);
    }
    if (data.containsKey('needs_ok')) {
      context.handle(
        _needsOkMeta,
        needsOk.isAcceptableOrUnknown(data['needs_ok']!, _needsOkMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reward(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      coinPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coin_price'],
      )!,
      needsOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_ok'],
      )!,
    );
  }

  @override
  $RewardsTable createAlias(String alias) {
    return $RewardsTable(attachedDatabase, alias);
  }
}

class Reward extends DataClass implements Insertable<Reward> {
  final String id;
  final String familyId;
  final String title;
  final String icon;
  final int coinPrice;
  final bool needsOk;
  const Reward({
    required this.id,
    required this.familyId,
    required this.title,
    required this.icon,
    required this.coinPrice,
    required this.needsOk,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['title'] = Variable<String>(title);
    map['icon'] = Variable<String>(icon);
    map['coin_price'] = Variable<int>(coinPrice);
    map['needs_ok'] = Variable<bool>(needsOk);
    return map;
  }

  RewardsCompanion toCompanion(bool nullToAbsent) {
    return RewardsCompanion(
      id: Value(id),
      familyId: Value(familyId),
      title: Value(title),
      icon: Value(icon),
      coinPrice: Value(coinPrice),
      needsOk: Value(needsOk),
    );
  }

  factory Reward.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reward(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String>(json['icon']),
      coinPrice: serializer.fromJson<int>(json['coinPrice']),
      needsOk: serializer.fromJson<bool>(json['needsOk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String>(icon),
      'coinPrice': serializer.toJson<int>(coinPrice),
      'needsOk': serializer.toJson<bool>(needsOk),
    };
  }

  Reward copyWith({
    String? id,
    String? familyId,
    String? title,
    String? icon,
    int? coinPrice,
    bool? needsOk,
  }) => Reward(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    coinPrice: coinPrice ?? this.coinPrice,
    needsOk: needsOk ?? this.needsOk,
  );
  Reward copyWithCompanion(RewardsCompanion data) {
    return Reward(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coinPrice: data.coinPrice.present ? data.coinPrice.value : this.coinPrice,
      needsOk: data.needsOk.present ? data.needsOk.value : this.needsOk,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reward(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coinPrice: $coinPrice, ')
          ..write('needsOk: $needsOk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, familyId, title, icon, coinPrice, needsOk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reward &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coinPrice == this.coinPrice &&
          other.needsOk == this.needsOk);
}

class RewardsCompanion extends UpdateCompanion<Reward> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> title;
  final Value<String> icon;
  final Value<int> coinPrice;
  final Value<bool> needsOk;
  final Value<int> rowid;
  const RewardsCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coinPrice = const Value.absent(),
    this.needsOk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RewardsCompanion.insert({
    required String id,
    required String familyId,
    required String title,
    this.icon = const Value.absent(),
    required int coinPrice,
    this.needsOk = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       title = Value(title),
       coinPrice = Value(coinPrice);
  static Insertable<Reward> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<int>? coinPrice,
    Expression<bool>? needsOk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coinPrice != null) 'coin_price': coinPrice,
      if (needsOk != null) 'needs_ok': needsOk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RewardsCompanion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? title,
    Value<String>? icon,
    Value<int>? coinPrice,
    Value<bool>? needsOk,
    Value<int>? rowid,
  }) {
    return RewardsCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coinPrice: coinPrice ?? this.coinPrice,
      needsOk: needsOk ?? this.needsOk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coinPrice.present) {
      map['coin_price'] = Variable<int>(coinPrice.value);
    }
    if (needsOk.present) {
      map['needs_ok'] = Variable<bool>(needsOk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RewardsCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coinPrice: $coinPrice, ')
          ..write('needsOk: $needsOk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RewardRedemptionsTable extends RewardRedemptions
    with TableInfo<$RewardRedemptionsTable, RewardRedemption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RewardRedemptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rewardIdMeta = const VerificationMeta(
    'rewardId',
  );
  @override
  late final GeneratedColumn<String> rewardId = GeneratedColumn<String>(
    'reward_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rewards (id)',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('requested'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtTzMeta = const VerificationMeta(
    'createdAtTz',
  );
  @override
  late final GeneratedColumn<String> createdAtTz = GeneratedColumn<String>(
    'created_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rewardId,
    childId,
    familyId,
    status,
    createdAt,
    createdAtTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reward_redemptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RewardRedemption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reward_id')) {
      context.handle(
        _rewardIdMeta,
        rewardId.isAcceptableOrUnknown(data['reward_id']!, _rewardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rewardIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('created_at_tz')) {
      context.handle(
        _createdAtTzMeta,
        createdAtTz.isAcceptableOrUnknown(
          data['created_at_tz']!,
          _createdAtTzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RewardRedemption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RewardRedemption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rewardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reward_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      createdAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at_tz'],
      )!,
    );
  }

  @override
  $RewardRedemptionsTable createAlias(String alias) {
    return $RewardRedemptionsTable(attachedDatabase, alias);
  }
}

class RewardRedemption extends DataClass
    implements Insertable<RewardRedemption> {
  final int id;
  final String rewardId;
  final String childId;
  final String familyId;
  final String status;
  final DateTime createdAt;
  final String createdAtTz;
  const RewardRedemption({
    required this.id,
    required this.rewardId,
    required this.childId,
    required this.familyId,
    required this.status,
    required this.createdAt,
    required this.createdAtTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reward_id'] = Variable<String>(rewardId);
    map['child_id'] = Variable<String>(childId);
    map['family_id'] = Variable<String>(familyId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['created_at_tz'] = Variable<String>(createdAtTz);
    return map;
  }

  RewardRedemptionsCompanion toCompanion(bool nullToAbsent) {
    return RewardRedemptionsCompanion(
      id: Value(id),
      rewardId: Value(rewardId),
      childId: Value(childId),
      familyId: Value(familyId),
      status: Value(status),
      createdAt: Value(createdAt),
      createdAtTz: Value(createdAtTz),
    );
  }

  factory RewardRedemption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RewardRedemption(
      id: serializer.fromJson<int>(json['id']),
      rewardId: serializer.fromJson<String>(json['rewardId']),
      childId: serializer.fromJson<String>(json['childId']),
      familyId: serializer.fromJson<String>(json['familyId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdAtTz: serializer.fromJson<String>(json['createdAtTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rewardId': serializer.toJson<String>(rewardId),
      'childId': serializer.toJson<String>(childId),
      'familyId': serializer.toJson<String>(familyId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdAtTz': serializer.toJson<String>(createdAtTz),
    };
  }

  RewardRedemption copyWith({
    int? id,
    String? rewardId,
    String? childId,
    String? familyId,
    String? status,
    DateTime? createdAt,
    String? createdAtTz,
  }) => RewardRedemption(
    id: id ?? this.id,
    rewardId: rewardId ?? this.rewardId,
    childId: childId ?? this.childId,
    familyId: familyId ?? this.familyId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    createdAtTz: createdAtTz ?? this.createdAtTz,
  );
  RewardRedemption copyWithCompanion(RewardRedemptionsCompanion data) {
    return RewardRedemption(
      id: data.id.present ? data.id.value : this.id,
      rewardId: data.rewardId.present ? data.rewardId.value : this.rewardId,
      childId: data.childId.present ? data.childId.value : this.childId,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdAtTz: data.createdAtTz.present
          ? data.createdAtTz.value
          : this.createdAtTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RewardRedemption(')
          ..write('id: $id, ')
          ..write('rewardId: $rewardId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdAtTz: $createdAtTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rewardId,
    childId,
    familyId,
    status,
    createdAt,
    createdAtTz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RewardRedemption &&
          other.id == this.id &&
          other.rewardId == this.rewardId &&
          other.childId == this.childId &&
          other.familyId == this.familyId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.createdAtTz == this.createdAtTz);
}

class RewardRedemptionsCompanion extends UpdateCompanion<RewardRedemption> {
  final Value<int> id;
  final Value<String> rewardId;
  final Value<String> childId;
  final Value<String> familyId;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String> createdAtTz;
  const RewardRedemptionsCompanion({
    this.id = const Value.absent(),
    this.rewardId = const Value.absent(),
    this.childId = const Value.absent(),
    this.familyId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdAtTz = const Value.absent(),
  });
  RewardRedemptionsCompanion.insert({
    this.id = const Value.absent(),
    required String rewardId,
    required String childId,
    required String familyId,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdAtTz = const Value.absent(),
  }) : rewardId = Value(rewardId),
       childId = Value(childId),
       familyId = Value(familyId);
  static Insertable<RewardRedemption> custom({
    Expression<int>? id,
    Expression<String>? rewardId,
    Expression<String>? childId,
    Expression<String>? familyId,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? createdAtTz,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rewardId != null) 'reward_id': rewardId,
      if (childId != null) 'child_id': childId,
      if (familyId != null) 'family_id': familyId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (createdAtTz != null) 'created_at_tz': createdAtTz,
    });
  }

  RewardRedemptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? rewardId,
    Value<String>? childId,
    Value<String>? familyId,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String>? createdAtTz,
  }) {
    return RewardRedemptionsCompanion(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      childId: childId ?? this.childId,
      familyId: familyId ?? this.familyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdAtTz: createdAtTz ?? this.createdAtTz,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rewardId.present) {
      map['reward_id'] = Variable<String>(rewardId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdAtTz.present) {
      map['created_at_tz'] = Variable<String>(createdAtTz.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RewardRedemptionsCompanion(')
          ..write('id: $id, ')
          ..write('rewardId: $rewardId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdAtTz: $createdAtTz')
          ..write(')'))
        .toString();
  }
}

class $BadgesTable extends Badges with TableInfo<$BadgesTable, Badge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BadgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medal'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, icon, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'badges';
  @override
  VerificationContext validateIntegrity(
    Insertable<Badge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Badge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Badge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $BadgesTable createAlias(String alias) {
    return $BadgesTable(attachedDatabase, alias);
  }
}

class Badge extends DataClass implements Insertable<Badge> {
  final String id;
  final String title;
  final String icon;
  final String description;
  const Badge({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['icon'] = Variable<String>(icon);
    map['description'] = Variable<String>(description);
    return map;
  }

  BadgesCompanion toCompanion(bool nullToAbsent) {
    return BadgesCompanion(
      id: Value(id),
      title: Value(title),
      icon: Value(icon),
      description: Value(description),
    );
  }

  factory Badge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Badge(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String>(json['icon']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String>(icon),
      'description': serializer.toJson<String>(description),
    };
  }

  Badge copyWith({
    String? id,
    String? title,
    String? icon,
    String? description,
  }) => Badge(
    id: id ?? this.id,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    description: description ?? this.description,
  );
  Badge copyWithCompanion(BadgesCompanion data) {
    return Badge(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Badge(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, icon, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Badge &&
          other.id == this.id &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.description == this.description);
}

class BadgesCompanion extends UpdateCompanion<Badge> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> icon;
  final Value<String> description;
  final Value<int> rowid;
  const BadgesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BadgesCompanion.insert({
    required String id,
    required String title,
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Badge> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BadgesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? icon,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return BadgesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BadgesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EarnedBadgesTable extends EarnedBadges
    with TableInfo<$EarnedBadgesTable, EarnedBadge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EarnedBadgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _badgeIdMeta = const VerificationMeta(
    'badgeId',
  );
  @override
  late final GeneratedColumn<String> badgeId = GeneratedColumn<String>(
    'badge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES badges (id)',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _earnedAtTzMeta = const VerificationMeta(
    'earnedAtTz',
  );
  @override
  late final GeneratedColumn<String> earnedAtTz = GeneratedColumn<String>(
    'earned_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    badgeId,
    childId,
    familyId,
    earnedAt,
    earnedAtTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'earned_badges';
  @override
  VerificationContext validateIntegrity(
    Insertable<EarnedBadge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('badge_id')) {
      context.handle(
        _badgeIdMeta,
        badgeId.isAcceptableOrUnknown(data['badge_id']!, _badgeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_badgeIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    }
    if (data.containsKey('earned_at_tz')) {
      context.handle(
        _earnedAtTzMeta,
        earnedAtTz.isAcceptableOrUnknown(
          data['earned_at_tz']!,
          _earnedAtTzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EarnedBadge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EarnedBadge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      badgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badge_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}earned_at'],
      )!,
      earnedAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_at_tz'],
      )!,
    );
  }

  @override
  $EarnedBadgesTable createAlias(String alias) {
    return $EarnedBadgesTable(attachedDatabase, alias);
  }
}

class EarnedBadge extends DataClass implements Insertable<EarnedBadge> {
  final int id;
  final String badgeId;
  final String childId;
  final String familyId;
  final DateTime earnedAt;
  final String earnedAtTz;
  const EarnedBadge({
    required this.id,
    required this.badgeId,
    required this.childId,
    required this.familyId,
    required this.earnedAt,
    required this.earnedAtTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['badge_id'] = Variable<String>(badgeId);
    map['child_id'] = Variable<String>(childId);
    map['family_id'] = Variable<String>(familyId);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    map['earned_at_tz'] = Variable<String>(earnedAtTz);
    return map;
  }

  EarnedBadgesCompanion toCompanion(bool nullToAbsent) {
    return EarnedBadgesCompanion(
      id: Value(id),
      badgeId: Value(badgeId),
      childId: Value(childId),
      familyId: Value(familyId),
      earnedAt: Value(earnedAt),
      earnedAtTz: Value(earnedAtTz),
    );
  }

  factory EarnedBadge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EarnedBadge(
      id: serializer.fromJson<int>(json['id']),
      badgeId: serializer.fromJson<String>(json['badgeId']),
      childId: serializer.fromJson<String>(json['childId']),
      familyId: serializer.fromJson<String>(json['familyId']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
      earnedAtTz: serializer.fromJson<String>(json['earnedAtTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'badgeId': serializer.toJson<String>(badgeId),
      'childId': serializer.toJson<String>(childId),
      'familyId': serializer.toJson<String>(familyId),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
      'earnedAtTz': serializer.toJson<String>(earnedAtTz),
    };
  }

  EarnedBadge copyWith({
    int? id,
    String? badgeId,
    String? childId,
    String? familyId,
    DateTime? earnedAt,
    String? earnedAtTz,
  }) => EarnedBadge(
    id: id ?? this.id,
    badgeId: badgeId ?? this.badgeId,
    childId: childId ?? this.childId,
    familyId: familyId ?? this.familyId,
    earnedAt: earnedAt ?? this.earnedAt,
    earnedAtTz: earnedAtTz ?? this.earnedAtTz,
  );
  EarnedBadge copyWithCompanion(EarnedBadgesCompanion data) {
    return EarnedBadge(
      id: data.id.present ? data.id.value : this.id,
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      childId: data.childId.present ? data.childId.value : this.childId,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
      earnedAtTz: data.earnedAtTz.present
          ? data.earnedAtTz.value
          : this.earnedAtTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EarnedBadge(')
          ..write('id: $id, ')
          ..write('badgeId: $badgeId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('earnedAtTz: $earnedAtTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, badgeId, childId, familyId, earnedAt, earnedAtTz);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarnedBadge &&
          other.id == this.id &&
          other.badgeId == this.badgeId &&
          other.childId == this.childId &&
          other.familyId == this.familyId &&
          other.earnedAt == this.earnedAt &&
          other.earnedAtTz == this.earnedAtTz);
}

class EarnedBadgesCompanion extends UpdateCompanion<EarnedBadge> {
  final Value<int> id;
  final Value<String> badgeId;
  final Value<String> childId;
  final Value<String> familyId;
  final Value<DateTime> earnedAt;
  final Value<String> earnedAtTz;
  const EarnedBadgesCompanion({
    this.id = const Value.absent(),
    this.badgeId = const Value.absent(),
    this.childId = const Value.absent(),
    this.familyId = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.earnedAtTz = const Value.absent(),
  });
  EarnedBadgesCompanion.insert({
    this.id = const Value.absent(),
    required String badgeId,
    required String childId,
    required String familyId,
    this.earnedAt = const Value.absent(),
    this.earnedAtTz = const Value.absent(),
  }) : badgeId = Value(badgeId),
       childId = Value(childId),
       familyId = Value(familyId);
  static Insertable<EarnedBadge> custom({
    Expression<int>? id,
    Expression<String>? badgeId,
    Expression<String>? childId,
    Expression<String>? familyId,
    Expression<DateTime>? earnedAt,
    Expression<String>? earnedAtTz,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (badgeId != null) 'badge_id': badgeId,
      if (childId != null) 'child_id': childId,
      if (familyId != null) 'family_id': familyId,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (earnedAtTz != null) 'earned_at_tz': earnedAtTz,
    });
  }

  EarnedBadgesCompanion copyWith({
    Value<int>? id,
    Value<String>? badgeId,
    Value<String>? childId,
    Value<String>? familyId,
    Value<DateTime>? earnedAt,
    Value<String>? earnedAtTz,
  }) {
    return EarnedBadgesCompanion(
      id: id ?? this.id,
      badgeId: badgeId ?? this.badgeId,
      childId: childId ?? this.childId,
      familyId: familyId ?? this.familyId,
      earnedAt: earnedAt ?? this.earnedAt,
      earnedAtTz: earnedAtTz ?? this.earnedAtTz,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(badgeId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (earnedAtTz.present) {
      map['earned_at_tz'] = Variable<String>(earnedAtTz.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EarnedBadgesCompanion(')
          ..write('id: $id, ')
          ..write('badgeId: $badgeId, ')
          ..write('childId: $childId, ')
          ..write('familyId: $familyId, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('earnedAtTz: $earnedAtTz')
          ..write(')'))
        .toString();
  }
}

class $PipWardrobeTable extends PipWardrobe
    with TableInfo<$PipWardrobeTable, PipWardrobeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PipWardrobeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownedMeta = const VerificationMeta('owned');
  @override
  late final GeneratedColumn<bool> owned = GeneratedColumn<bool>(
    'owned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("owned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priceCoinsMeta = const VerificationMeta(
    'priceCoins',
  );
  @override
  late final GeneratedColumn<int> priceCoins = GeneratedColumn<int>(
    'price_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, childId, item, owned, priceCoins];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pip_wardrobe';
  @override
  VerificationContext validateIntegrity(
    Insertable<PipWardrobeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('owned')) {
      context.handle(
        _ownedMeta,
        owned.isAcceptableOrUnknown(data['owned']!, _ownedMeta),
      );
    }
    if (data.containsKey('price_coins')) {
      context.handle(
        _priceCoinsMeta,
        priceCoins.isAcceptableOrUnknown(data['price_coins']!, _priceCoinsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PipWardrobeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PipWardrobeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      owned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}owned'],
      )!,
      priceCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_coins'],
      )!,
    );
  }

  @override
  $PipWardrobeTable createAlias(String alias) {
    return $PipWardrobeTable(attachedDatabase, alias);
  }
}

class PipWardrobeData extends DataClass implements Insertable<PipWardrobeData> {
  final int id;
  final String childId;
  final String item;
  final bool owned;
  final int priceCoins;
  const PipWardrobeData({
    required this.id,
    required this.childId,
    required this.item,
    required this.owned,
    required this.priceCoins,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<String>(childId);
    map['item'] = Variable<String>(item);
    map['owned'] = Variable<bool>(owned);
    map['price_coins'] = Variable<int>(priceCoins);
    return map;
  }

  PipWardrobeCompanion toCompanion(bool nullToAbsent) {
    return PipWardrobeCompanion(
      id: Value(id),
      childId: Value(childId),
      item: Value(item),
      owned: Value(owned),
      priceCoins: Value(priceCoins),
    );
  }

  factory PipWardrobeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PipWardrobeData(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<String>(json['childId']),
      item: serializer.fromJson<String>(json['item']),
      owned: serializer.fromJson<bool>(json['owned']),
      priceCoins: serializer.fromJson<int>(json['priceCoins']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<String>(childId),
      'item': serializer.toJson<String>(item),
      'owned': serializer.toJson<bool>(owned),
      'priceCoins': serializer.toJson<int>(priceCoins),
    };
  }

  PipWardrobeData copyWith({
    int? id,
    String? childId,
    String? item,
    bool? owned,
    int? priceCoins,
  }) => PipWardrobeData(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    item: item ?? this.item,
    owned: owned ?? this.owned,
    priceCoins: priceCoins ?? this.priceCoins,
  );
  PipWardrobeData copyWithCompanion(PipWardrobeCompanion data) {
    return PipWardrobeData(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      item: data.item.present ? data.item.value : this.item,
      owned: data.owned.present ? data.owned.value : this.owned,
      priceCoins: data.priceCoins.present
          ? data.priceCoins.value
          : this.priceCoins,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PipWardrobeData(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('item: $item, ')
          ..write('owned: $owned, ')
          ..write('priceCoins: $priceCoins')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, childId, item, owned, priceCoins);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PipWardrobeData &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.item == this.item &&
          other.owned == this.owned &&
          other.priceCoins == this.priceCoins);
}

class PipWardrobeCompanion extends UpdateCompanion<PipWardrobeData> {
  final Value<int> id;
  final Value<String> childId;
  final Value<String> item;
  final Value<bool> owned;
  final Value<int> priceCoins;
  const PipWardrobeCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.item = const Value.absent(),
    this.owned = const Value.absent(),
    this.priceCoins = const Value.absent(),
  });
  PipWardrobeCompanion.insert({
    this.id = const Value.absent(),
    required String childId,
    required String item,
    this.owned = const Value.absent(),
    this.priceCoins = const Value.absent(),
  }) : childId = Value(childId),
       item = Value(item);
  static Insertable<PipWardrobeData> custom({
    Expression<int>? id,
    Expression<String>? childId,
    Expression<String>? item,
    Expression<bool>? owned,
    Expression<int>? priceCoins,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (item != null) 'item': item,
      if (owned != null) 'owned': owned,
      if (priceCoins != null) 'price_coins': priceCoins,
    });
  }

  PipWardrobeCompanion copyWith({
    Value<int>? id,
    Value<String>? childId,
    Value<String>? item,
    Value<bool>? owned,
    Value<int>? priceCoins,
  }) {
    return PipWardrobeCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      item: item ?? this.item,
      owned: owned ?? this.owned,
      priceCoins: priceCoins ?? this.priceCoins,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (owned.present) {
      map['owned'] = Variable<bool>(owned.value);
    }
    if (priceCoins.present) {
      map['price_coins'] = Variable<int>(priceCoins.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PipWardrobeCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('item: $item, ')
          ..write('owned: $owned, ')
          ..write('priceCoins: $priceCoins')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families (id)',
    ),
  );
  static const VerificationMeta _pocketMoneyModeMeta = const VerificationMeta(
    'pocketMoneyMode',
  );
  @override
  late final GeneratedColumn<String> pocketMoneyMode = GeneratedColumn<String>(
    'pocket_money_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('both'),
  );
  static const VerificationMeta _payoutDayMeta = const VerificationMeta(
    'payoutDay',
  );
  @override
  late final GeneratedColumn<int> payoutDay = GeneratedColumn<int>(
    'payout_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _coinValuePencePerCoinMeta =
      const VerificationMeta('coinValuePencePerCoin');
  @override
  late final GeneratedColumn<int> coinValuePencePerCoin = GeneratedColumn<int>(
    'coin_value_pence_per_coin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notifApprovalsMeta = const VerificationMeta(
    'notifApprovals',
  );
  @override
  late final GeneratedColumn<bool> notifApprovals = GeneratedColumn<bool>(
    'notif_approvals',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notif_approvals" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifPayoutMeta = const VerificationMeta(
    'notifPayout',
  );
  @override
  late final GeneratedColumn<bool> notifPayout = GeneratedColumn<bool>(
    'notif_payout',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notif_payout" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifSummaryMeta = const VerificationMeta(
    'notifSummary',
  );
  @override
  late final GeneratedColumn<bool> notifSummary = GeneratedColumn<bool>(
    'notif_summary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notif_summary" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _crashReportConsentMeta =
      const VerificationMeta('crashReportConsent');
  @override
  late final GeneratedColumn<bool> crashReportConsent = GeneratedColumn<bool>(
    'crash_report_consent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("crash_report_consent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _kidGateEnabledMeta = const VerificationMeta(
    'kidGateEnabled',
  );
  @override
  late final GeneratedColumn<bool> kidGateEnabled = GeneratedColumn<bool>(
    'kid_gate_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kid_gate_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtTzMeta = const VerificationMeta(
    'updatedAtTz',
  );
  @override
  late final GeneratedColumn<String> updatedAtTz = GeneratedColumn<String>(
    'updated_at_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    familyId,
    pocketMoneyMode,
    payoutDay,
    coinValuePencePerCoin,
    notifApprovals,
    notifPayout,
    notifSummary,
    crashReportConsent,
    kidGateEnabled,
    timeZone,
    updatedAt,
    updatedAtTz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('pocket_money_mode')) {
      context.handle(
        _pocketMoneyModeMeta,
        pocketMoneyMode.isAcceptableOrUnknown(
          data['pocket_money_mode']!,
          _pocketMoneyModeMeta,
        ),
      );
    }
    if (data.containsKey('payout_day')) {
      context.handle(
        _payoutDayMeta,
        payoutDay.isAcceptableOrUnknown(data['payout_day']!, _payoutDayMeta),
      );
    }
    if (data.containsKey('coin_value_pence_per_coin')) {
      context.handle(
        _coinValuePencePerCoinMeta,
        coinValuePencePerCoin.isAcceptableOrUnknown(
          data['coin_value_pence_per_coin']!,
          _coinValuePencePerCoinMeta,
        ),
      );
    }
    if (data.containsKey('notif_approvals')) {
      context.handle(
        _notifApprovalsMeta,
        notifApprovals.isAcceptableOrUnknown(
          data['notif_approvals']!,
          _notifApprovalsMeta,
        ),
      );
    }
    if (data.containsKey('notif_payout')) {
      context.handle(
        _notifPayoutMeta,
        notifPayout.isAcceptableOrUnknown(
          data['notif_payout']!,
          _notifPayoutMeta,
        ),
      );
    }
    if (data.containsKey('notif_summary')) {
      context.handle(
        _notifSummaryMeta,
        notifSummary.isAcceptableOrUnknown(
          data['notif_summary']!,
          _notifSummaryMeta,
        ),
      );
    }
    if (data.containsKey('crash_report_consent')) {
      context.handle(
        _crashReportConsentMeta,
        crashReportConsent.isAcceptableOrUnknown(
          data['crash_report_consent']!,
          _crashReportConsentMeta,
        ),
      );
    }
    if (data.containsKey('kid_gate_enabled')) {
      context.handle(
        _kidGateEnabledMeta,
        kidGateEnabled.isAcceptableOrUnknown(
          data['kid_gate_enabled']!,
          _kidGateEnabledMeta,
        ),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_at_tz')) {
      context.handle(
        _updatedAtTzMeta,
        updatedAtTz.isAcceptableOrUnknown(
          data['updated_at_tz']!,
          _updatedAtTzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {familyId};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      pocketMoneyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pocket_money_mode'],
      )!,
      payoutDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payout_day'],
      )!,
      coinValuePencePerCoin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coin_value_pence_per_coin'],
      )!,
      notifApprovals: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notif_approvals'],
      )!,
      notifPayout: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notif_payout'],
      )!,
      notifSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notif_summary'],
      )!,
      crashReportConsent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}crash_report_consent'],
      )!,
      kidGateEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kid_gate_enabled'],
      )!,
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      updatedAtTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at_tz'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String familyId;
  final String pocketMoneyMode;
  final int payoutDay;
  final int coinValuePencePerCoin;
  final bool notifApprovals;
  final bool notifPayout;
  final bool notifSummary;
  final bool crashReportConsent;
  final bool kidGateEnabled;
  final String timeZone;
  final DateTime? updatedAt;
  final String updatedAtTz;
  const Setting({
    required this.familyId,
    required this.pocketMoneyMode,
    required this.payoutDay,
    required this.coinValuePencePerCoin,
    required this.notifApprovals,
    required this.notifPayout,
    required this.notifSummary,
    required this.crashReportConsent,
    required this.kidGateEnabled,
    required this.timeZone,
    this.updatedAt,
    required this.updatedAtTz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['family_id'] = Variable<String>(familyId);
    map['pocket_money_mode'] = Variable<String>(pocketMoneyMode);
    map['payout_day'] = Variable<int>(payoutDay);
    map['coin_value_pence_per_coin'] = Variable<int>(coinValuePencePerCoin);
    map['notif_approvals'] = Variable<bool>(notifApprovals);
    map['notif_payout'] = Variable<bool>(notifPayout);
    map['notif_summary'] = Variable<bool>(notifSummary);
    map['crash_report_consent'] = Variable<bool>(crashReportConsent);
    map['kid_gate_enabled'] = Variable<bool>(kidGateEnabled);
    map['time_zone'] = Variable<String>(timeZone);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['updated_at_tz'] = Variable<String>(updatedAtTz);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      familyId: Value(familyId),
      pocketMoneyMode: Value(pocketMoneyMode),
      payoutDay: Value(payoutDay),
      coinValuePencePerCoin: Value(coinValuePencePerCoin),
      notifApprovals: Value(notifApprovals),
      notifPayout: Value(notifPayout),
      notifSummary: Value(notifSummary),
      crashReportConsent: Value(crashReportConsent),
      kidGateEnabled: Value(kidGateEnabled),
      timeZone: Value(timeZone),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      updatedAtTz: Value(updatedAtTz),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      familyId: serializer.fromJson<String>(json['familyId']),
      pocketMoneyMode: serializer.fromJson<String>(json['pocketMoneyMode']),
      payoutDay: serializer.fromJson<int>(json['payoutDay']),
      coinValuePencePerCoin: serializer.fromJson<int>(
        json['coinValuePencePerCoin'],
      ),
      notifApprovals: serializer.fromJson<bool>(json['notifApprovals']),
      notifPayout: serializer.fromJson<bool>(json['notifPayout']),
      notifSummary: serializer.fromJson<bool>(json['notifSummary']),
      crashReportConsent: serializer.fromJson<bool>(json['crashReportConsent']),
      kidGateEnabled: serializer.fromJson<bool>(json['kidGateEnabled']),
      timeZone: serializer.fromJson<String>(json['timeZone']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      updatedAtTz: serializer.fromJson<String>(json['updatedAtTz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'familyId': serializer.toJson<String>(familyId),
      'pocketMoneyMode': serializer.toJson<String>(pocketMoneyMode),
      'payoutDay': serializer.toJson<int>(payoutDay),
      'coinValuePencePerCoin': serializer.toJson<int>(coinValuePencePerCoin),
      'notifApprovals': serializer.toJson<bool>(notifApprovals),
      'notifPayout': serializer.toJson<bool>(notifPayout),
      'notifSummary': serializer.toJson<bool>(notifSummary),
      'crashReportConsent': serializer.toJson<bool>(crashReportConsent),
      'kidGateEnabled': serializer.toJson<bool>(kidGateEnabled),
      'timeZone': serializer.toJson<String>(timeZone),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'updatedAtTz': serializer.toJson<String>(updatedAtTz),
    };
  }

  Setting copyWith({
    String? familyId,
    String? pocketMoneyMode,
    int? payoutDay,
    int? coinValuePencePerCoin,
    bool? notifApprovals,
    bool? notifPayout,
    bool? notifSummary,
    bool? crashReportConsent,
    bool? kidGateEnabled,
    String? timeZone,
    Value<DateTime?> updatedAt = const Value.absent(),
    String? updatedAtTz,
  }) => Setting(
    familyId: familyId ?? this.familyId,
    pocketMoneyMode: pocketMoneyMode ?? this.pocketMoneyMode,
    payoutDay: payoutDay ?? this.payoutDay,
    coinValuePencePerCoin: coinValuePencePerCoin ?? this.coinValuePencePerCoin,
    notifApprovals: notifApprovals ?? this.notifApprovals,
    notifPayout: notifPayout ?? this.notifPayout,
    notifSummary: notifSummary ?? this.notifSummary,
    crashReportConsent: crashReportConsent ?? this.crashReportConsent,
    kidGateEnabled: kidGateEnabled ?? this.kidGateEnabled,
    timeZone: timeZone ?? this.timeZone,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    updatedAtTz: updatedAtTz ?? this.updatedAtTz,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      pocketMoneyMode: data.pocketMoneyMode.present
          ? data.pocketMoneyMode.value
          : this.pocketMoneyMode,
      payoutDay: data.payoutDay.present ? data.payoutDay.value : this.payoutDay,
      coinValuePencePerCoin: data.coinValuePencePerCoin.present
          ? data.coinValuePencePerCoin.value
          : this.coinValuePencePerCoin,
      notifApprovals: data.notifApprovals.present
          ? data.notifApprovals.value
          : this.notifApprovals,
      notifPayout: data.notifPayout.present
          ? data.notifPayout.value
          : this.notifPayout,
      notifSummary: data.notifSummary.present
          ? data.notifSummary.value
          : this.notifSummary,
      crashReportConsent: data.crashReportConsent.present
          ? data.crashReportConsent.value
          : this.crashReportConsent,
      kidGateEnabled: data.kidGateEnabled.present
          ? data.kidGateEnabled.value
          : this.kidGateEnabled,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedAtTz: data.updatedAtTz.present
          ? data.updatedAtTz.value
          : this.updatedAtTz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('familyId: $familyId, ')
          ..write('pocketMoneyMode: $pocketMoneyMode, ')
          ..write('payoutDay: $payoutDay, ')
          ..write('coinValuePencePerCoin: $coinValuePencePerCoin, ')
          ..write('notifApprovals: $notifApprovals, ')
          ..write('notifPayout: $notifPayout, ')
          ..write('notifSummary: $notifSummary, ')
          ..write('crashReportConsent: $crashReportConsent, ')
          ..write('kidGateEnabled: $kidGateEnabled, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedAtTz: $updatedAtTz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    familyId,
    pocketMoneyMode,
    payoutDay,
    coinValuePencePerCoin,
    notifApprovals,
    notifPayout,
    notifSummary,
    crashReportConsent,
    kidGateEnabled,
    timeZone,
    updatedAt,
    updatedAtTz,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.familyId == this.familyId &&
          other.pocketMoneyMode == this.pocketMoneyMode &&
          other.payoutDay == this.payoutDay &&
          other.coinValuePencePerCoin == this.coinValuePencePerCoin &&
          other.notifApprovals == this.notifApprovals &&
          other.notifPayout == this.notifPayout &&
          other.notifSummary == this.notifSummary &&
          other.crashReportConsent == this.crashReportConsent &&
          other.kidGateEnabled == this.kidGateEnabled &&
          other.timeZone == this.timeZone &&
          other.updatedAt == this.updatedAt &&
          other.updatedAtTz == this.updatedAtTz);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> familyId;
  final Value<String> pocketMoneyMode;
  final Value<int> payoutDay;
  final Value<int> coinValuePencePerCoin;
  final Value<bool> notifApprovals;
  final Value<bool> notifPayout;
  final Value<bool> notifSummary;
  final Value<bool> crashReportConsent;
  final Value<bool> kidGateEnabled;
  final Value<String> timeZone;
  final Value<DateTime?> updatedAt;
  final Value<String> updatedAtTz;
  final Value<int> rowid;
  const SettingsCompanion({
    this.familyId = const Value.absent(),
    this.pocketMoneyMode = const Value.absent(),
    this.payoutDay = const Value.absent(),
    this.coinValuePencePerCoin = const Value.absent(),
    this.notifApprovals = const Value.absent(),
    this.notifPayout = const Value.absent(),
    this.notifSummary = const Value.absent(),
    this.crashReportConsent = const Value.absent(),
    this.kidGateEnabled = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedAtTz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String familyId,
    this.pocketMoneyMode = const Value.absent(),
    this.payoutDay = const Value.absent(),
    this.coinValuePencePerCoin = const Value.absent(),
    this.notifApprovals = const Value.absent(),
    this.notifPayout = const Value.absent(),
    this.notifSummary = const Value.absent(),
    this.crashReportConsent = const Value.absent(),
    this.kidGateEnabled = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedAtTz = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : familyId = Value(familyId);
  static Insertable<Setting> custom({
    Expression<String>? familyId,
    Expression<String>? pocketMoneyMode,
    Expression<int>? payoutDay,
    Expression<int>? coinValuePencePerCoin,
    Expression<bool>? notifApprovals,
    Expression<bool>? notifPayout,
    Expression<bool>? notifSummary,
    Expression<bool>? crashReportConsent,
    Expression<bool>? kidGateEnabled,
    Expression<String>? timeZone,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedAtTz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (familyId != null) 'family_id': familyId,
      if (pocketMoneyMode != null) 'pocket_money_mode': pocketMoneyMode,
      if (payoutDay != null) 'payout_day': payoutDay,
      if (coinValuePencePerCoin != null)
        'coin_value_pence_per_coin': coinValuePencePerCoin,
      if (notifApprovals != null) 'notif_approvals': notifApprovals,
      if (notifPayout != null) 'notif_payout': notifPayout,
      if (notifSummary != null) 'notif_summary': notifSummary,
      if (crashReportConsent != null)
        'crash_report_consent': crashReportConsent,
      if (kidGateEnabled != null) 'kid_gate_enabled': kidGateEnabled,
      if (timeZone != null) 'time_zone': timeZone,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedAtTz != null) 'updated_at_tz': updatedAtTz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? familyId,
    Value<String>? pocketMoneyMode,
    Value<int>? payoutDay,
    Value<int>? coinValuePencePerCoin,
    Value<bool>? notifApprovals,
    Value<bool>? notifPayout,
    Value<bool>? notifSummary,
    Value<bool>? crashReportConsent,
    Value<bool>? kidGateEnabled,
    Value<String>? timeZone,
    Value<DateTime?>? updatedAt,
    Value<String>? updatedAtTz,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      familyId: familyId ?? this.familyId,
      pocketMoneyMode: pocketMoneyMode ?? this.pocketMoneyMode,
      payoutDay: payoutDay ?? this.payoutDay,
      coinValuePencePerCoin:
          coinValuePencePerCoin ?? this.coinValuePencePerCoin,
      notifApprovals: notifApprovals ?? this.notifApprovals,
      notifPayout: notifPayout ?? this.notifPayout,
      notifSummary: notifSummary ?? this.notifSummary,
      crashReportConsent: crashReportConsent ?? this.crashReportConsent,
      kidGateEnabled: kidGateEnabled ?? this.kidGateEnabled,
      timeZone: timeZone ?? this.timeZone,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedAtTz: updatedAtTz ?? this.updatedAtTz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (pocketMoneyMode.present) {
      map['pocket_money_mode'] = Variable<String>(pocketMoneyMode.value);
    }
    if (payoutDay.present) {
      map['payout_day'] = Variable<int>(payoutDay.value);
    }
    if (coinValuePencePerCoin.present) {
      map['coin_value_pence_per_coin'] = Variable<int>(
        coinValuePencePerCoin.value,
      );
    }
    if (notifApprovals.present) {
      map['notif_approvals'] = Variable<bool>(notifApprovals.value);
    }
    if (notifPayout.present) {
      map['notif_payout'] = Variable<bool>(notifPayout.value);
    }
    if (notifSummary.present) {
      map['notif_summary'] = Variable<bool>(notifSummary.value);
    }
    if (crashReportConsent.present) {
      map['crash_report_consent'] = Variable<bool>(crashReportConsent.value);
    }
    if (kidGateEnabled.present) {
      map['kid_gate_enabled'] = Variable<bool>(kidGateEnabled.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedAtTz.present) {
      map['updated_at_tz'] = Variable<String>(updatedAtTz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('familyId: $familyId, ')
          ..write('pocketMoneyMode: $pocketMoneyMode, ')
          ..write('payoutDay: $payoutDay, ')
          ..write('coinValuePencePerCoin: $coinValuePencePerCoin, ')
          ..write('notifApprovals: $notifApprovals, ')
          ..write('notifPayout: $notifPayout, ')
          ..write('notifSummary: $notifSummary, ')
          ..write('crashReportConsent: $crashReportConsent, ')
          ..write('kidGateEnabled: $kidGateEnabled, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedAtTz: $updatedAtTz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateTable extends AppState
    with TableInfo<$AppStateTable, AppStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<bool> onboardingComplete = GeneratedColumn<bool>(
    'onboarding_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _subscriptionStatusMeta =
      const VerificationMeta('subscriptionStatus');
  @override
  late final GeneratedColumn<String> subscriptionStatus =
      GeneratedColumn<String>(
        'subscription_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('trial'),
      );
  static const VerificationMeta _trialStartMeta = const VerificationMeta(
    'trialStart',
  );
  @override
  late final GeneratedColumn<DateTime> trialStart = GeneratedColumn<DateTime>(
    'trial_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trialStartTzMeta = const VerificationMeta(
    'trialStartTz',
  );
  @override
  late final GeneratedColumn<String> trialStartTz = GeneratedColumn<String>(
    'trial_start_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/London'),
  );
  static const VerificationMeta _activeChildIdMeta = const VerificationMeta(
    'activeChildId',
  );
  @override
  late final GeneratedColumn<String> activeChildId = GeneratedColumn<String>(
    'active_child_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appModeMeta = const VerificationMeta(
    'appMode',
  );
  @override
  late final GeneratedColumn<String> appMode = GeneratedColumn<String>(
    'app_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('parent'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    onboardingComplete,
    subscriptionStatus,
    trialStart,
    trialStartTz,
    activeChildId,
    appMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
        _onboardingCompleteMeta,
        onboardingComplete.isAcceptableOrUnknown(
          data['onboarding_complete']!,
          _onboardingCompleteMeta,
        ),
      );
    }
    if (data.containsKey('subscription_status')) {
      context.handle(
        _subscriptionStatusMeta,
        subscriptionStatus.isAcceptableOrUnknown(
          data['subscription_status']!,
          _subscriptionStatusMeta,
        ),
      );
    }
    if (data.containsKey('trial_start')) {
      context.handle(
        _trialStartMeta,
        trialStart.isAcceptableOrUnknown(data['trial_start']!, _trialStartMeta),
      );
    }
    if (data.containsKey('trial_start_tz')) {
      context.handle(
        _trialStartTzMeta,
        trialStartTz.isAcceptableOrUnknown(
          data['trial_start_tz']!,
          _trialStartTzMeta,
        ),
      );
    }
    if (data.containsKey('active_child_id')) {
      context.handle(
        _activeChildIdMeta,
        activeChildId.isAcceptableOrUnknown(
          data['active_child_id']!,
          _activeChildIdMeta,
        ),
      );
    }
    if (data.containsKey('app_mode')) {
      context.handle(
        _appModeMeta,
        appMode.isAcceptableOrUnknown(data['app_mode']!, _appModeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      onboardingComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_complete'],
      )!,
      subscriptionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_status'],
      )!,
      trialStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trial_start'],
      ),
      trialStartTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trial_start_tz'],
      )!,
      activeChildId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_child_id'],
      ),
      appMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_mode'],
      )!,
    );
  }

  @override
  $AppStateTable createAlias(String alias) {
    return $AppStateTable(attachedDatabase, alias);
  }
}

class AppStateData extends DataClass implements Insertable<AppStateData> {
  final int id;
  final bool onboardingComplete;
  final String subscriptionStatus;
  final DateTime? trialStart;
  final String trialStartTz;
  final String? activeChildId;
  final String appMode;
  const AppStateData({
    required this.id,
    required this.onboardingComplete,
    required this.subscriptionStatus,
    this.trialStart,
    required this.trialStartTz,
    this.activeChildId,
    required this.appMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['subscription_status'] = Variable<String>(subscriptionStatus);
    if (!nullToAbsent || trialStart != null) {
      map['trial_start'] = Variable<DateTime>(trialStart);
    }
    map['trial_start_tz'] = Variable<String>(trialStartTz);
    if (!nullToAbsent || activeChildId != null) {
      map['active_child_id'] = Variable<String>(activeChildId);
    }
    map['app_mode'] = Variable<String>(appMode);
    return map;
  }

  AppStateCompanion toCompanion(bool nullToAbsent) {
    return AppStateCompanion(
      id: Value(id),
      onboardingComplete: Value(onboardingComplete),
      subscriptionStatus: Value(subscriptionStatus),
      trialStart: trialStart == null && nullToAbsent
          ? const Value.absent()
          : Value(trialStart),
      trialStartTz: Value(trialStartTz),
      activeChildId: activeChildId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeChildId),
      appMode: Value(appMode),
    );
  }

  factory AppStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateData(
      id: serializer.fromJson<int>(json['id']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      subscriptionStatus: serializer.fromJson<String>(
        json['subscriptionStatus'],
      ),
      trialStart: serializer.fromJson<DateTime?>(json['trialStart']),
      trialStartTz: serializer.fromJson<String>(json['trialStartTz']),
      activeChildId: serializer.fromJson<String?>(json['activeChildId']),
      appMode: serializer.fromJson<String>(json['appMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'subscriptionStatus': serializer.toJson<String>(subscriptionStatus),
      'trialStart': serializer.toJson<DateTime?>(trialStart),
      'trialStartTz': serializer.toJson<String>(trialStartTz),
      'activeChildId': serializer.toJson<String?>(activeChildId),
      'appMode': serializer.toJson<String>(appMode),
    };
  }

  AppStateData copyWith({
    int? id,
    bool? onboardingComplete,
    String? subscriptionStatus,
    Value<DateTime?> trialStart = const Value.absent(),
    String? trialStartTz,
    Value<String?> activeChildId = const Value.absent(),
    String? appMode,
  }) => AppStateData(
    id: id ?? this.id,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    trialStart: trialStart.present ? trialStart.value : this.trialStart,
    trialStartTz: trialStartTz ?? this.trialStartTz,
    activeChildId: activeChildId.present
        ? activeChildId.value
        : this.activeChildId,
    appMode: appMode ?? this.appMode,
  );
  AppStateData copyWithCompanion(AppStateCompanion data) {
    return AppStateData(
      id: data.id.present ? data.id.value : this.id,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      subscriptionStatus: data.subscriptionStatus.present
          ? data.subscriptionStatus.value
          : this.subscriptionStatus,
      trialStart: data.trialStart.present
          ? data.trialStart.value
          : this.trialStart,
      trialStartTz: data.trialStartTz.present
          ? data.trialStartTz.value
          : this.trialStartTz,
      activeChildId: data.activeChildId.present
          ? data.activeChildId.value
          : this.activeChildId,
      appMode: data.appMode.present ? data.appMode.value : this.appMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateData(')
          ..write('id: $id, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('trialStart: $trialStart, ')
          ..write('trialStartTz: $trialStartTz, ')
          ..write('activeChildId: $activeChildId, ')
          ..write('appMode: $appMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    onboardingComplete,
    subscriptionStatus,
    trialStart,
    trialStartTz,
    activeChildId,
    appMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppStateData &&
          other.id == this.id &&
          other.onboardingComplete == this.onboardingComplete &&
          other.subscriptionStatus == this.subscriptionStatus &&
          other.trialStart == this.trialStart &&
          other.trialStartTz == this.trialStartTz &&
          other.activeChildId == this.activeChildId &&
          other.appMode == this.appMode);
}

class AppStateCompanion extends UpdateCompanion<AppStateData> {
  final Value<int> id;
  final Value<bool> onboardingComplete;
  final Value<String> subscriptionStatus;
  final Value<DateTime?> trialStart;
  final Value<String> trialStartTz;
  final Value<String?> activeChildId;
  final Value<String> appMode;
  const AppStateCompanion({
    this.id = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.trialStart = const Value.absent(),
    this.trialStartTz = const Value.absent(),
    this.activeChildId = const Value.absent(),
    this.appMode = const Value.absent(),
  });
  AppStateCompanion.insert({
    this.id = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.trialStart = const Value.absent(),
    this.trialStartTz = const Value.absent(),
    this.activeChildId = const Value.absent(),
    this.appMode = const Value.absent(),
  });
  static Insertable<AppStateData> custom({
    Expression<int>? id,
    Expression<bool>? onboardingComplete,
    Expression<String>? subscriptionStatus,
    Expression<DateTime>? trialStart,
    Expression<String>? trialStartTz,
    Expression<String>? activeChildId,
    Expression<String>? appMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      if (trialStart != null) 'trial_start': trialStart,
      if (trialStartTz != null) 'trial_start_tz': trialStartTz,
      if (activeChildId != null) 'active_child_id': activeChildId,
      if (appMode != null) 'app_mode': appMode,
    });
  }

  AppStateCompanion copyWith({
    Value<int>? id,
    Value<bool>? onboardingComplete,
    Value<String>? subscriptionStatus,
    Value<DateTime?>? trialStart,
    Value<String>? trialStartTz,
    Value<String?>? activeChildId,
    Value<String>? appMode,
  }) {
    return AppStateCompanion(
      id: id ?? this.id,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialStart: trialStart ?? this.trialStart,
      trialStartTz: trialStartTz ?? this.trialStartTz,
      activeChildId: activeChildId ?? this.activeChildId,
      appMode: appMode ?? this.appMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (subscriptionStatus.present) {
      map['subscription_status'] = Variable<String>(subscriptionStatus.value);
    }
    if (trialStart.present) {
      map['trial_start'] = Variable<DateTime>(trialStart.value);
    }
    if (trialStartTz.present) {
      map['trial_start_tz'] = Variable<String>(trialStartTz.value);
    }
    if (activeChildId.present) {
      map['active_child_id'] = Variable<String>(activeChildId.value);
    }
    if (appMode.present) {
      map['app_mode'] = Variable<String>(appMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppStateCompanion(')
          ..write('id: $id, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('trialStart: $trialStart, ')
          ..write('trialStartTz: $trialStartTz, ')
          ..write('activeChildId: $activeChildId, ')
          ..write('appMode: $appMode')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FamiliesTable families = $FamiliesTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $QuestsTable quests = $QuestsTable(this);
  late final $QuestCompletionsTable questCompletions = $QuestCompletionsTable(
    this,
  );
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $RewardsTable rewards = $RewardsTable(this);
  late final $RewardRedemptionsTable rewardRedemptions =
      $RewardRedemptionsTable(this);
  late final $BadgesTable badges = $BadgesTable(this);
  late final $EarnedBadgesTable earnedBadges = $EarnedBadgesTable(this);
  late final $PipWardrobeTable pipWardrobe = $PipWardrobeTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AppStateTable appState = $AppStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    families,
    members,
    children,
    quests,
    questCompletions,
    ledgerEntries,
    savingsGoals,
    rewards,
    rewardRedemptions,
    badges,
    earnedBadges,
    pipWardrobe,
    settings,
    appState,
  ];
}

typedef $$FamiliesTableCreateCompanionBuilder = FamiliesCompanion Function({
  required String id,
  Value<String> name,
  Value<int> payoutDay,
  Value<int> coinValuePencePerCoin,
  Value<String> pocketMoneyMode,
  Value<String> timeZone,
  Value<DateTime?> updatedAt,
  Value<String> updatedAtTz,
  Value<int> rowid,
});
typedef $$FamiliesTableUpdateCompanionBuilder = FamiliesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> payoutDay,
  Value<int> coinValuePencePerCoin,
  Value<String> pocketMoneyMode,
  Value<String> timeZone,
  Value<DateTime?> updatedAt,
  Value<String> updatedAtTz,
  Value<int> rowid,
});

final class $$FamiliesTableReferences
    extends BaseReferences<_$AppDatabase, $FamiliesTable, Family> {
  $$FamiliesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<Member>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'families__id__members__family_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChildrenTable, List<ChildrenData>>
  _childrenRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.children,
    aliasName: 'families__id__children__family_id',
  );

  $$ChildrenTableProcessedTableManager get childrenRefs {
    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_childrenRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuestsTable, List<Quest>> _questsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.quests,
    aliasName: 'families__id__quests__family_id',
  );

  $$QuestsTableProcessedTableManager get questsRefs {
    final manager = $$QuestsTableTableManager(
      $_db,
      $_db.quests,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuestCompletionsTable, List<QuestCompletion>>
  _questCompletionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questCompletions,
    aliasName: 'families__id__quest_completions__family_id',
  );

  $$QuestCompletionsTableProcessedTableManager get questCompletionsRefs {
    final manager = $$QuestCompletionsTableTableManager(
      $_db,
      $_db.questCompletions,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _questCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'families__id__ledger_entries__family_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavingsGoalsTable, List<SavingsGoal>>
  _savingsGoalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savingsGoals,
    aliasName: 'families__id__savings_goals__family_id',
  );

  $$SavingsGoalsTableProcessedTableManager get savingsGoalsRefs {
    final manager = $$SavingsGoalsTableTableManager(
      $_db,
      $_db.savingsGoals,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savingsGoalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RewardsTable, List<Reward>> _rewardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rewards,
    aliasName: 'families__id__rewards__family_id',
  );

  $$RewardsTableProcessedTableManager get rewardsRefs {
    final manager = $$RewardsTableTableManager(
      $_db,
      $_db.rewards,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rewardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RewardRedemptionsTable, List<RewardRedemption>>
  _rewardRedemptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rewardRedemptions,
        aliasName: 'families__id__reward_redemptions__family_id',
      );

  $$RewardRedemptionsTableProcessedTableManager get rewardRedemptionsRefs {
    final manager = $$RewardRedemptionsTableTableManager(
      $_db,
      $_db.rewardRedemptions,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rewardRedemptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EarnedBadgesTable, List<EarnedBadge>>
  _earnedBadgesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.earnedBadges,
    aliasName: 'families__id__earned_badges__family_id',
  );

  $$EarnedBadgesTableProcessedTableManager get earnedBadgesRefs {
    final manager = $$EarnedBadgesTableTableManager(
      $_db,
      $_db.earnedBadges,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_earnedBadgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettingsTable, List<Setting>> _settingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.settings,
    aliasName: 'families__id__settings__family_id',
  );

  $$SettingsTableProcessedTableManager get settingsRefs {
    final manager = $$SettingsTableTableManager(
      $_db,
      $_db.settings,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_settingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FamiliesTableFilterComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payoutDay => $composableBuilder(
    column: $table.payoutDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> childrenRefs(
    Expression<bool> Function($$ChildrenTableFilterComposer f) f,
  ) {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> questsRefs(
    Expression<bool> Function($$QuestsTableFilterComposer f) f,
  ) {
    final $$QuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableFilterComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> questCompletionsRefs(
    Expression<bool> Function($$QuestCompletionsTableFilterComposer f) f,
  ) {
    final $$QuestCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savingsGoalsRefs(
    Expression<bool> Function($$SavingsGoalsTableFilterComposer f) f,
  ) {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rewardsRefs(
    Expression<bool> Function($$RewardsTableFilterComposer f) f,
  ) {
    final $$RewardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rewards,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardsTableFilterComposer(
            $db: $db,
            $table: $db.rewards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rewardRedemptionsRefs(
    Expression<bool> Function($$RewardRedemptionsTableFilterComposer f) f,
  ) {
    final $$RewardRedemptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rewardRedemptions,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardRedemptionsTableFilterComposer(
            $db: $db,
            $table: $db.rewardRedemptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> earnedBadgesRefs(
    Expression<bool> Function($$EarnedBadgesTableFilterComposer f) f,
  ) {
    final $$EarnedBadgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableFilterComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settingsRefs(
    Expression<bool> Function($$SettingsTableFilterComposer f) f,
  ) {
    final $$SettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settings,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettingsTableFilterComposer(
            $db: $db,
            $table: $db.settings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamiliesTableOrderingComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payoutDay => $composableBuilder(
    column: $table.payoutDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamiliesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get payoutDay =>
      $composableBuilder(column: $table.payoutDay, builder: (column) => column);

  GeneratedColumn<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => column,
  );

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> childrenRefs<T extends Object>(
    Expression<T> Function($$ChildrenTableAnnotationComposer a) f,
  ) {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> questsRefs<T extends Object>(
    Expression<T> Function($$QuestsTableAnnotationComposer a) f,
  ) {
    final $$QuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> questCompletionsRefs<T extends Object>(
    Expression<T> Function($$QuestCompletionsTableAnnotationComposer a) f,
  ) {
    final $$QuestCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savingsGoalsRefs<T extends Object>(
    Expression<T> Function($$SavingsGoalsTableAnnotationComposer a) f,
  ) {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rewardsRefs<T extends Object>(
    Expression<T> Function($$RewardsTableAnnotationComposer a) f,
  ) {
    final $$RewardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rewards,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardsTableAnnotationComposer(
            $db: $db,
            $table: $db.rewards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rewardRedemptionsRefs<T extends Object>(
    Expression<T> Function($$RewardRedemptionsTableAnnotationComposer a) f,
  ) {
    final $$RewardRedemptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rewardRedemptions,
          getReferencedColumn: (t) => t.familyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RewardRedemptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.rewardRedemptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> earnedBadgesRefs<T extends Object>(
    Expression<T> Function($$EarnedBadgesTableAnnotationComposer a) f,
  ) {
    final $$EarnedBadgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableAnnotationComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settingsRefs<T extends Object>(
    Expression<T> Function($$SettingsTableAnnotationComposer a) f,
  ) {
    final $$SettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settings,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.settings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamiliesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamiliesTable,
          Family,
          $$FamiliesTableFilterComposer,
          $$FamiliesTableOrderingComposer,
          $$FamiliesTableAnnotationComposer,
          $$FamiliesTableCreateCompanionBuilder,
          $$FamiliesTableUpdateCompanionBuilder,
          (Family, $$FamiliesTableReferences),
          Family,
          PrefetchHooks Function({
            bool membersRefs,
            bool childrenRefs,
            bool questsRefs,
            bool questCompletionsRefs,
            bool ledgerEntriesRefs,
            bool savingsGoalsRefs,
            bool rewardsRefs,
            bool rewardRedemptionsRefs,
            bool earnedBadgesRefs,
            bool settingsRefs,
          })
        > {
  $$FamiliesTableTableManager(_$AppDatabase db, $FamiliesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamiliesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamiliesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamiliesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> payoutDay = const Value.absent(),
                Value<int> coinValuePencePerCoin = const Value.absent(),
                Value<String> pocketMoneyMode = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String> updatedAtTz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesCompanion(
                id: id,
                name: name,
                payoutDay: payoutDay,
                coinValuePencePerCoin: coinValuePencePerCoin,
                pocketMoneyMode: pocketMoneyMode,
                timeZone: timeZone,
                updatedAt: updatedAt,
                updatedAtTz: updatedAtTz,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<int> payoutDay = const Value.absent(),
                Value<int> coinValuePencePerCoin = const Value.absent(),
                Value<String> pocketMoneyMode = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String> updatedAtTz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesCompanion.insert(
                id: id,
                name: name,
                payoutDay: payoutDay,
                coinValuePencePerCoin: coinValuePencePerCoin,
                pocketMoneyMode: pocketMoneyMode,
                timeZone: timeZone,
                updatedAt: updatedAt,
                updatedAtTz: updatedAtTz,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FamiliesTable, Family>(table),
                  $$FamiliesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membersRefs = false,
                childrenRefs = false,
                questsRefs = false,
                questCompletionsRefs = false,
                ledgerEntriesRefs = false,
                savingsGoalsRefs = false,
                rewardsRefs = false,
                rewardRedemptionsRefs = false,
                earnedBadgesRefs = false,
                settingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (childrenRefs) db.children,
                    if (questsRefs) db.quests,
                    if (questCompletionsRefs) db.questCompletions,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (savingsGoalsRefs) db.savingsGoals,
                    if (rewardsRefs) db.rewards,
                    if (rewardRedemptionsRefs) db.rewardRedemptions,
                    if (earnedBadgesRefs) db.earnedBadges,
                    if (settingsRefs) db.settings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          Member
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (childrenRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          ChildrenData
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._childrenRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).childrenRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (questsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          Quest
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._questsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).questsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (questCompletionsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          QuestCompletion
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._questCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).questCompletionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          LedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savingsGoalsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          SavingsGoal
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._savingsGoalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).savingsGoalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rewardsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          Reward
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._rewardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).rewardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rewardRedemptionsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          RewardRedemption
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._rewardRedemptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).rewardRedemptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (earnedBadgesRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          EarnedBadge
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._earnedBadgesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).earnedBadgesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (settingsRefs)
                        await $_getPrefetchedData<
                          Family,
                          $FamiliesTable,
                          Setting
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesTableReferences
                              ._settingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesTableReferences(
                                db,
                                table,
                                p0,
                              ).settingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FamiliesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamiliesTable,
      Family,
      $$FamiliesTableFilterComposer,
      $$FamiliesTableOrderingComposer,
      $$FamiliesTableAnnotationComposer,
      $$FamiliesTableCreateCompanionBuilder,
      $$FamiliesTableUpdateCompanionBuilder,
      (Family, $$FamiliesTableReferences),
      Family,
      PrefetchHooks Function({
        bool membersRefs,
        bool childrenRefs,
        bool questsRefs,
        bool questCompletionsRefs,
        bool ledgerEntriesRefs,
        bool savingsGoalsRefs,
        bool rewardsRefs,
        bool rewardRedemptionsRefs,
        bool earnedBadgesRefs,
        bool settingsRefs,
      })
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String familyId,
  required String name,
  Value<String> role,
  Value<String> inviteStatus,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> familyId,
  Value<String> name,
  Value<String> role,
  Value<String> inviteStatus,
  Value<int> rowid,
});

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('members__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteStatus => $composableBuilder(
    column: $table.inviteStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteStatus => $composableBuilder(
    column: $table.inviteStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get inviteStatus => $composableBuilder(
    column: $table.inviteStatus,
    builder: (column) => column,
  );

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, $$MembersTableReferences),
          Member,
          PrefetchHooks Function({bool familyId})
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> inviteStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                familyId: familyId,
                name: name,
                role: role,
                inviteStatus: inviteStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String name,
                Value<String> role = const Value.absent(),
                Value<String> inviteStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                familyId: familyId,
                name: name,
                role: role,
                inviteStatus: inviteStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembersTable, Member>(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({familyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (familyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.familyId,
                        referencedTable: $$MembersTableReferences
                            ._familyIdTable(db),
                        referencedColumn: $$MembersTableReferences
                            ._familyIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, $$MembersTableReferences),
      Member,
      PrefetchHooks Function({bool familyId})
    >;
typedef $$ChildrenTableCreateCompanionBuilder = ChildrenCompanion Function({
  required String id,
  required String familyId,
  required String nickname,
  Value<String> ageBand,
  Value<int> ageYears,
  Value<String> avatarColour,
  Value<String?> pinHash,
  Value<String> pipStyle,
  Value<String> pipSkin,
  Value<String> pipAccessory,
  Value<int> pipStage,
  Value<int> pipTotalCoins,
  Value<int> coins,
  Value<int> happiness,
  Value<int> happyDays,
  Value<int> weeklyBasePence,
  Value<int> rowid,
});
typedef $$ChildrenTableUpdateCompanionBuilder = ChildrenCompanion Function({
  Value<String> id,
  Value<String> familyId,
  Value<String> nickname,
  Value<String> ageBand,
  Value<int> ageYears,
  Value<String> avatarColour,
  Value<String?> pinHash,
  Value<String> pipStyle,
  Value<String> pipSkin,
  Value<String> pipAccessory,
  Value<int> pipStage,
  Value<int> pipTotalCoins,
  Value<int> coins,
  Value<int> happiness,
  Value<int> happyDays,
  Value<int> weeklyBasePence,
  Value<int> rowid,
});

final class $$ChildrenTableReferences
    extends BaseReferences<_$AppDatabase, $ChildrenTable, ChildrenData> {
  $$ChildrenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('children__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestCompletionsTable, List<QuestCompletion>>
  _questCompletionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questCompletions,
    aliasName: 'children__id__quest_completions__child_id',
  );

  $$QuestCompletionsTableProcessedTableManager get questCompletionsRefs {
    final manager = $$QuestCompletionsTableTableManager(
      $_db,
      $_db.questCompletions,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _questCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'children__id__ledger_entries__child_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavingsGoalsTable, List<SavingsGoal>>
  _savingsGoalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savingsGoals,
    aliasName: 'children__id__savings_goals__child_id',
  );

  $$SavingsGoalsTableProcessedTableManager get savingsGoalsRefs {
    final manager = $$SavingsGoalsTableTableManager(
      $_db,
      $_db.savingsGoals,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savingsGoalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RewardRedemptionsTable, List<RewardRedemption>>
  _rewardRedemptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rewardRedemptions,
        aliasName: 'children__id__reward_redemptions__child_id',
      );

  $$RewardRedemptionsTableProcessedTableManager get rewardRedemptionsRefs {
    final manager = $$RewardRedemptionsTableTableManager(
      $_db,
      $_db.rewardRedemptions,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rewardRedemptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EarnedBadgesTable, List<EarnedBadge>>
  _earnedBadgesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.earnedBadges,
    aliasName: 'children__id__earned_badges__child_id',
  );

  $$EarnedBadgesTableProcessedTableManager get earnedBadgesRefs {
    final manager = $$EarnedBadgesTableTableManager(
      $_db,
      $_db.earnedBadges,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_earnedBadgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PipWardrobeTable, List<PipWardrobeData>>
  _pipWardrobeRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pipWardrobe,
    aliasName: 'children__id__pip_wardrobe__child_id',
  );

  $$PipWardrobeTableProcessedTableManager get pipWardrobeRefs {
    final manager = $$PipWardrobeTableTableManager(
      $_db,
      $_db.pipWardrobe,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pipWardrobeRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pipStyle => $composableBuilder(
    column: $table.pipStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pipSkin => $composableBuilder(
    column: $table.pipSkin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pipAccessory => $composableBuilder(
    column: $table.pipAccessory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pipStage => $composableBuilder(
    column: $table.pipStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pipTotalCoins => $composableBuilder(
    column: $table.pipTotalCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get happyDays => $composableBuilder(
    column: $table.happyDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklyBasePence => $composableBuilder(
    column: $table.weeklyBasePence,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questCompletionsRefs(
    Expression<bool> Function($$QuestCompletionsTableFilterComposer f) f,
  ) {
    final $$QuestCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savingsGoalsRefs(
    Expression<bool> Function($$SavingsGoalsTableFilterComposer f) f,
  ) {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rewardRedemptionsRefs(
    Expression<bool> Function($$RewardRedemptionsTableFilterComposer f) f,
  ) {
    final $$RewardRedemptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rewardRedemptions,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardRedemptionsTableFilterComposer(
            $db: $db,
            $table: $db.rewardRedemptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> earnedBadgesRefs(
    Expression<bool> Function($$EarnedBadgesTableFilterComposer f) f,
  ) {
    final $$EarnedBadgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableFilterComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pipWardrobeRefs(
    Expression<bool> Function($$PipWardrobeTableFilterComposer f) f,
  ) {
    final $$PipWardrobeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pipWardrobe,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PipWardrobeTableFilterComposer(
            $db: $db,
            $table: $db.pipWardrobe,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pipStyle => $composableBuilder(
    column: $table.pipStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pipSkin => $composableBuilder(
    column: $table.pipSkin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pipAccessory => $composableBuilder(
    column: $table.pipAccessory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pipStage => $composableBuilder(
    column: $table.pipStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pipTotalCoins => $composableBuilder(
    column: $table.pipTotalCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get happyDays => $composableBuilder(
    column: $table.happyDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyBasePence => $composableBuilder(
    column: $table.weeklyBasePence,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get ageBand =>
      $composableBuilder(column: $table.ageBand, builder: (column) => column);

  GeneratedColumn<int> get ageYears =>
      $composableBuilder(column: $table.ageYears, builder: (column) => column);

  GeneratedColumn<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get pipStyle =>
      $composableBuilder(column: $table.pipStyle, builder: (column) => column);

  GeneratedColumn<String> get pipSkin =>
      $composableBuilder(column: $table.pipSkin, builder: (column) => column);

  GeneratedColumn<String> get pipAccessory => $composableBuilder(
    column: $table.pipAccessory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pipStage =>
      $composableBuilder(column: $table.pipStage, builder: (column) => column);

  GeneratedColumn<int> get pipTotalCoins => $composableBuilder(
    column: $table.pipTotalCoins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coins =>
      $composableBuilder(column: $table.coins, builder: (column) => column);

  GeneratedColumn<int> get happiness =>
      $composableBuilder(column: $table.happiness, builder: (column) => column);

  GeneratedColumn<int> get happyDays =>
      $composableBuilder(column: $table.happyDays, builder: (column) => column);

  GeneratedColumn<int> get weeklyBasePence => $composableBuilder(
    column: $table.weeklyBasePence,
    builder: (column) => column,
  );

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questCompletionsRefs<T extends Object>(
    Expression<T> Function($$QuestCompletionsTableAnnotationComposer a) f,
  ) {
    final $$QuestCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savingsGoalsRefs<T extends Object>(
    Expression<T> Function($$SavingsGoalsTableAnnotationComposer a) f,
  ) {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rewardRedemptionsRefs<T extends Object>(
    Expression<T> Function($$RewardRedemptionsTableAnnotationComposer a) f,
  ) {
    final $$RewardRedemptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rewardRedemptions,
          getReferencedColumn: (t) => t.childId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RewardRedemptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.rewardRedemptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> earnedBadgesRefs<T extends Object>(
    Expression<T> Function($$EarnedBadgesTableAnnotationComposer a) f,
  ) {
    final $$EarnedBadgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableAnnotationComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pipWardrobeRefs<T extends Object>(
    Expression<T> Function($$PipWardrobeTableAnnotationComposer a) f,
  ) {
    final $$PipWardrobeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pipWardrobe,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PipWardrobeTableAnnotationComposer(
            $db: $db,
            $table: $db.pipWardrobe,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          ChildrenData,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (ChildrenData, $$ChildrenTableReferences),
          ChildrenData,
          PrefetchHooks Function({
            bool familyId,
            bool questCompletionsRefs,
            bool ledgerEntriesRefs,
            bool savingsGoalsRefs,
            bool rewardRedemptionsRefs,
            bool earnedBadgesRefs,
            bool pipWardrobeRefs,
          })
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> ageBand = const Value.absent(),
                Value<int> ageYears = const Value.absent(),
                Value<String> avatarColour = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<String> pipStyle = const Value.absent(),
                Value<String> pipSkin = const Value.absent(),
                Value<String> pipAccessory = const Value.absent(),
                Value<int> pipStage = const Value.absent(),
                Value<int> pipTotalCoins = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<int> happiness = const Value.absent(),
                Value<int> happyDays = const Value.absent(),
                Value<int> weeklyBasePence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion(
                id: id,
                familyId: familyId,
                nickname: nickname,
                ageBand: ageBand,
                ageYears: ageYears,
                avatarColour: avatarColour,
                pinHash: pinHash,
                pipStyle: pipStyle,
                pipSkin: pipSkin,
                pipAccessory: pipAccessory,
                pipStage: pipStage,
                pipTotalCoins: pipTotalCoins,
                coins: coins,
                happiness: happiness,
                happyDays: happyDays,
                weeklyBasePence: weeklyBasePence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String nickname,
                Value<String> ageBand = const Value.absent(),
                Value<int> ageYears = const Value.absent(),
                Value<String> avatarColour = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<String> pipStyle = const Value.absent(),
                Value<String> pipSkin = const Value.absent(),
                Value<String> pipAccessory = const Value.absent(),
                Value<int> pipStage = const Value.absent(),
                Value<int> pipTotalCoins = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<int> happiness = const Value.absent(),
                Value<int> happyDays = const Value.absent(),
                Value<int> weeklyBasePence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion.insert(
                id: id,
                familyId: familyId,
                nickname: nickname,
                ageBand: ageBand,
                ageYears: ageYears,
                avatarColour: avatarColour,
                pinHash: pinHash,
                pipStyle: pipStyle,
                pipSkin: pipSkin,
                pipAccessory: pipAccessory,
                pipStage: pipStage,
                pipTotalCoins: pipTotalCoins,
                coins: coins,
                happiness: happiness,
                happyDays: happyDays,
                weeklyBasePence: weeklyBasePence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildrenTable, ChildrenData>(table),
                  $$ChildrenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                familyId = false,
                questCompletionsRefs = false,
                ledgerEntriesRefs = false,
                savingsGoalsRefs = false,
                rewardRedemptionsRefs = false,
                earnedBadgesRefs = false,
                pipWardrobeRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questCompletionsRefs) db.questCompletions,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (savingsGoalsRefs) db.savingsGoals,
                    if (rewardRedemptionsRefs) db.rewardRedemptions,
                    if (earnedBadgesRefs) db.earnedBadges,
                    if (pipWardrobeRefs) db.pipWardrobe,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$ChildrenTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$ChildrenTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questCompletionsRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          QuestCompletion
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._questCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).questCompletionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          LedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savingsGoalsRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          SavingsGoal
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._savingsGoalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).savingsGoalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rewardRedemptionsRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          RewardRedemption
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._rewardRedemptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).rewardRedemptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (earnedBadgesRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          EarnedBadge
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._earnedBadgesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).earnedBadgesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pipWardrobeRefs)
                        await $_getPrefetchedData<
                          ChildrenData,
                          $ChildrenTable,
                          PipWardrobeData
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._pipWardrobeRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).pipWardrobeRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      ChildrenData,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (ChildrenData, $$ChildrenTableReferences),
      ChildrenData,
      PrefetchHooks Function({
        bool familyId,
        bool questCompletionsRefs,
        bool ledgerEntriesRefs,
        bool savingsGoalsRefs,
        bool rewardRedemptionsRefs,
        bool earnedBadgesRefs,
        bool pipWardrobeRefs,
      })
    >;
typedef $$QuestsTableCreateCompanionBuilder = QuestsCompanion Function({
  required String id,
  required String familyId,
  required String title,
  Value<String> icon,
  Value<int> coins,
  Value<String> repeatRule,
  Value<String> days,
  Value<String?> dueLabel,
  Value<String?> dueTimeLocal,
  Value<bool> needsApproval,
  Value<String?> assigneeChildId,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$QuestsTableUpdateCompanionBuilder = QuestsCompanion Function({
  Value<String> id,
  Value<String> familyId,
  Value<String> title,
  Value<String> icon,
  Value<int> coins,
  Value<String> repeatRule,
  Value<String> days,
  Value<String?> dueLabel,
  Value<String?> dueTimeLocal,
  Value<bool> needsApproval,
  Value<String?> assigneeChildId,
  Value<bool> active,
  Value<int> rowid,
});

final class $$QuestsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestsTable, Quest> {
  $$QuestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('quests__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestCompletionsTable, List<QuestCompletion>>
  _questCompletionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questCompletions,
    aliasName: 'quests__id__quest_completions__quest_id',
  );

  $$QuestCompletionsTableProcessedTableManager get questCompletionsRefs {
    final manager = $$QuestCompletionsTableTableManager(
      $_db,
      $_db.questCompletions,
    ).filter((f) => f.questId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _questCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueLabel => $composableBuilder(
    column: $table.dueLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTimeLocal => $composableBuilder(
    column: $table.dueTimeLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsApproval => $composableBuilder(
    column: $table.needsApproval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeChildId => $composableBuilder(
    column: $table.assigneeChildId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questCompletionsRefs(
    Expression<bool> Function($$QuestCompletionsTableFilterComposer f) f,
  ) {
    final $$QuestCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueLabel => $composableBuilder(
    column: $table.dueLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTimeLocal => $composableBuilder(
    column: $table.dueTimeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsApproval => $composableBuilder(
    column: $table.needsApproval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeChildId => $composableBuilder(
    column: $table.assigneeChildId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get coins =>
      $composableBuilder(column: $table.coins, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<String> get dueLabel =>
      $composableBuilder(column: $table.dueLabel, builder: (column) => column);

  GeneratedColumn<String> get dueTimeLocal => $composableBuilder(
    column: $table.dueTimeLocal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsApproval => $composableBuilder(
    column: $table.needsApproval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeChildId => $composableBuilder(
    column: $table.assigneeChildId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questCompletionsRefs<T extends Object>(
    Expression<T> Function($$QuestCompletionsTableAnnotationComposer a) f,
  ) {
    final $$QuestCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questCompletions,
      getReferencedColumn: (t) => t.questId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestsTable,
          Quest,
          $$QuestsTableFilterComposer,
          $$QuestsTableOrderingComposer,
          $$QuestsTableAnnotationComposer,
          $$QuestsTableCreateCompanionBuilder,
          $$QuestsTableUpdateCompanionBuilder,
          (Quest, $$QuestsTableReferences),
          Quest,
          PrefetchHooks Function({bool familyId, bool questCompletionsRefs})
        > {
  $$QuestsTableTableManager(_$AppDatabase db, $QuestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<String> repeatRule = const Value.absent(),
                Value<String> days = const Value.absent(),
                Value<String?> dueLabel = const Value.absent(),
                Value<String?> dueTimeLocal = const Value.absent(),
                Value<bool> needsApproval = const Value.absent(),
                Value<String?> assigneeChildId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestsCompanion(
                id: id,
                familyId: familyId,
                title: title,
                icon: icon,
                coins: coins,
                repeatRule: repeatRule,
                days: days,
                dueLabel: dueLabel,
                dueTimeLocal: dueTimeLocal,
                needsApproval: needsApproval,
                assigneeChildId: assigneeChildId,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String title,
                Value<String> icon = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<String> repeatRule = const Value.absent(),
                Value<String> days = const Value.absent(),
                Value<String?> dueLabel = const Value.absent(),
                Value<String?> dueTimeLocal = const Value.absent(),
                Value<bool> needsApproval = const Value.absent(),
                Value<String?> assigneeChildId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestsCompanion.insert(
                id: id,
                familyId: familyId,
                title: title,
                icon: icon,
                coins: coins,
                repeatRule: repeatRule,
                days: days,
                dueLabel: dueLabel,
                dueTimeLocal: dueTimeLocal,
                needsApproval: needsApproval,
                assigneeChildId: assigneeChildId,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestsTable, Quest>(table),
                  $$QuestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({familyId = false, questCompletionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questCompletionsRefs) db.questCompletions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$QuestsTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$QuestsTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questCompletionsRefs)
                        await $_getPrefetchedData<
                          Quest,
                          $QuestsTable,
                          QuestCompletion
                        >(
                          currentTable: table,
                          referencedTable: $$QuestsTableReferences
                              ._questCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestsTableReferences(
                                db,
                                table,
                                p0,
                              ).questCompletionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$QuestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestsTable,
      Quest,
      $$QuestsTableFilterComposer,
      $$QuestsTableOrderingComposer,
      $$QuestsTableAnnotationComposer,
      $$QuestsTableCreateCompanionBuilder,
      $$QuestsTableUpdateCompanionBuilder,
      (Quest, $$QuestsTableReferences),
      Quest,
      PrefetchHooks Function({bool familyId, bool questCompletionsRefs})
    >;
typedef $$QuestCompletionsTableCreateCompanionBuilder =
    QuestCompletionsCompanion Function({
      Value<int> id,
      required String questId,
      required String childId,
      required String familyId,
      Value<String> status,
      Value<int> coins,
      Value<DateTime> createdAt,
      Value<String> createdAtTz,
      Value<DateTime?> decidedAt,
      Value<String> decidedAtTz,
    });
typedef $$QuestCompletionsTableUpdateCompanionBuilder =
    QuestCompletionsCompanion Function({
      Value<int> id,
      Value<String> questId,
      Value<String> childId,
      Value<String> familyId,
      Value<String> status,
      Value<int> coins,
      Value<DateTime> createdAt,
      Value<String> createdAtTz,
      Value<DateTime?> decidedAt,
      Value<String> decidedAtTz,
    });

final class $$QuestCompletionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $QuestCompletionsTable, QuestCompletion> {
  $$QuestCompletionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestsTable _questIdTable(_$AppDatabase db) =>
      db.quests.createAlias('quest_completions__quest_id__quests__id');

  $$QuestsTableProcessedTableManager get questId {
    final $_column = $_itemColumn<String>('quest_id')!;

    final manager = $$QuestsTableTableManager(
      $_db,
      $_db.quests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('quest_completions__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('quest_completions__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedAtTz => $composableBuilder(
    column: $table.decidedAtTz,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestsTableFilterComposer get questId {
    final $$QuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableFilterComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedAtTz => $composableBuilder(
    column: $table.decidedAtTz,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestsTableOrderingComposer get questId {
    final $$QuestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableOrderingComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestCompletionsTable> {
  $$QuestCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get coins =>
      $composableBuilder(column: $table.coins, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get decidedAtTz => $composableBuilder(
    column: $table.decidedAtTz,
    builder: (column) => column,
  );

  $$QuestsTableAnnotationComposer get questId {
    final $$QuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questId,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestCompletionsTable,
          QuestCompletion,
          $$QuestCompletionsTableFilterComposer,
          $$QuestCompletionsTableOrderingComposer,
          $$QuestCompletionsTableAnnotationComposer,
          $$QuestCompletionsTableCreateCompanionBuilder,
          $$QuestCompletionsTableUpdateCompanionBuilder,
          (QuestCompletion, $$QuestCompletionsTableReferences),
          QuestCompletion,
          PrefetchHooks Function({bool questId, bool childId, bool familyId})
        > {
  $$QuestCompletionsTableTableManager(
    _$AppDatabase db,
    $QuestCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdAtTz = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String> decidedAtTz = const Value.absent(),
              }) => QuestCompletionsCompanion(
                id: id,
                questId: questId,
                childId: childId,
                familyId: familyId,
                status: status,
                coins: coins,
                createdAt: createdAt,
                createdAtTz: createdAtTz,
                decidedAt: decidedAt,
                decidedAtTz: decidedAtTz,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questId,
                required String childId,
                required String familyId,
                Value<String> status = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdAtTz = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String> decidedAtTz = const Value.absent(),
              }) => QuestCompletionsCompanion.insert(
                id: id,
                questId: questId,
                childId: childId,
                familyId: familyId,
                status: status,
                coins: coins,
                createdAt: createdAt,
                createdAtTz: createdAtTz,
                decidedAt: decidedAt,
                decidedAtTz: decidedAtTz,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestCompletionsTable, QuestCompletion>(table),
                  $$QuestCompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({questId = false, childId = false, familyId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (questId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.questId,
                            referencedTable: $$QuestCompletionsTableReferences
                                ._questIdTable(db),
                            referencedColumn: $$QuestCompletionsTableReferences
                                ._questIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (childId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.childId,
                            referencedTable: $$QuestCompletionsTableReferences
                                ._childIdTable(db),
                            referencedColumn: $$QuestCompletionsTableReferences
                                ._childIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$QuestCompletionsTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$QuestCompletionsTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$QuestCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestCompletionsTable,
      QuestCompletion,
      $$QuestCompletionsTableFilterComposer,
      $$QuestCompletionsTableOrderingComposer,
      $$QuestCompletionsTableAnnotationComposer,
      $$QuestCompletionsTableCreateCompanionBuilder,
      $$QuestCompletionsTableUpdateCompanionBuilder,
      (QuestCompletion, $$QuestCompletionsTableReferences),
      QuestCompletion,
      PrefetchHooks Function({bool questId, bool childId, bool familyId})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      required String familyId,
      required String childId,
      required String type,
      required int amountPence,
      Value<String> note,
      Value<DateTime> date,
      Value<String> dateTz,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      Value<String> familyId,
      Value<String> childId,
      Value<String> type,
      Value<int> amountPence,
      Value<String> note,
      Value<DateTime> date,
      Value<String> dateTz,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('ledger_entries__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('ledger_entries__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateTz => $composableBuilder(
    column: $table.dateTz,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateTz => $composableBuilder(
    column: $table.dateTz,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dateTz =>
      $composableBuilder(column: $table.dateTz, builder: (column) => column);

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (LedgerEntry, $$LedgerEntriesTableReferences),
          LedgerEntry,
          PrefetchHooks Function({bool familyId, bool childId})
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountPence = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> dateTz = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                familyId: familyId,
                childId: childId,
                type: type,
                amountPence: amountPence,
                note: note,
                date: date,
                dateTz: dateTz,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String familyId,
                required String childId,
                required String type,
                required int amountPence,
                Value<String> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> dateTz = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                familyId: familyId,
                childId: childId,
                type: type,
                amountPence: amountPence,
                note: note,
                date: date,
                dateTz: dateTz,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntry>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({familyId = false, childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (familyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.familyId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._familyIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._familyIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (LedgerEntry, $$LedgerEntriesTableReferences),
      LedgerEntry,
      PrefetchHooks Function({bool familyId, bool childId})
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      required String id,
      required String familyId,
      required String childId,
      required String title,
      required int targetPence,
      Value<int> savedPence,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<String> id,
      Value<String> familyId,
      Value<String> childId,
      Value<String> title,
      Value<int> targetPence,
      Value<int> savedPence,
      Value<int> rowid,
    });

final class $$SavingsGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal> {
  $$SavingsGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('savings_goals__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('savings_goals__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPence => $composableBuilder(
    column: $table.targetPence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedPence => $composableBuilder(
    column: $table.savedPence,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPence => $composableBuilder(
    column: $table.targetPence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedPence => $composableBuilder(
    column: $table.savedPence,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetPence => $composableBuilder(
    column: $table.targetPence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedPence => $composableBuilder(
    column: $table.savedPence,
    builder: (column) => column,
  );

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoal,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (SavingsGoal, $$SavingsGoalsTableReferences),
          SavingsGoal,
          PrefetchHooks Function({bool familyId, bool childId})
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetPence = const Value.absent(),
                Value<int> savedPence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                familyId: familyId,
                childId: childId,
                title: title,
                targetPence: targetPence,
                savedPence: savedPence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String childId,
                required String title,
                required int targetPence,
                Value<int> savedPence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                familyId: familyId,
                childId: childId,
                title: title,
                targetPence: targetPence,
                savedPence: savedPence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsGoalsTable, SavingsGoal>(table),
                  $$SavingsGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({familyId = false, childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (familyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.familyId,
                        referencedTable: $$SavingsGoalsTableReferences
                            ._familyIdTable(db),
                        referencedColumn: $$SavingsGoalsTableReferences
                            ._familyIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$SavingsGoalsTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$SavingsGoalsTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoal,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (SavingsGoal, $$SavingsGoalsTableReferences),
      SavingsGoal,
      PrefetchHooks Function({bool familyId, bool childId})
    >;
typedef $$RewardsTableCreateCompanionBuilder = RewardsCompanion Function({
  required String id,
  required String familyId,
  required String title,
  Value<String> icon,
  required int coinPrice,
  Value<bool> needsOk,
  Value<int> rowid,
});
typedef $$RewardsTableUpdateCompanionBuilder = RewardsCompanion Function({
  Value<String> id,
  Value<String> familyId,
  Value<String> title,
  Value<String> icon,
  Value<int> coinPrice,
  Value<bool> needsOk,
  Value<int> rowid,
});

final class $$RewardsTableReferences
    extends BaseReferences<_$AppDatabase, $RewardsTable, Reward> {
  $$RewardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('rewards__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RewardRedemptionsTable, List<RewardRedemption>>
  _rewardRedemptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rewardRedemptions,
        aliasName: 'rewards__id__reward_redemptions__reward_id',
      );

  $$RewardRedemptionsTableProcessedTableManager get rewardRedemptionsRefs {
    final manager = $$RewardRedemptionsTableTableManager(
      $_db,
      $_db.rewardRedemptions,
    ).filter((f) => f.rewardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rewardRedemptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RewardsTableFilterComposer
    extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinPrice => $composableBuilder(
    column: $table.coinPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsOk => $composableBuilder(
    column: $table.needsOk,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rewardRedemptionsRefs(
    Expression<bool> Function($$RewardRedemptionsTableFilterComposer f) f,
  ) {
    final $$RewardRedemptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rewardRedemptions,
      getReferencedColumn: (t) => t.rewardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardRedemptionsTableFilterComposer(
            $db: $db,
            $table: $db.rewardRedemptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RewardsTableOrderingComposer
    extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinPrice => $composableBuilder(
    column: $table.coinPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsOk => $composableBuilder(
    column: $table.needsOk,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RewardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get coinPrice =>
      $composableBuilder(column: $table.coinPrice, builder: (column) => column);

  GeneratedColumn<bool> get needsOk =>
      $composableBuilder(column: $table.needsOk, builder: (column) => column);

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rewardRedemptionsRefs<T extends Object>(
    Expression<T> Function($$RewardRedemptionsTableAnnotationComposer a) f,
  ) {
    final $$RewardRedemptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rewardRedemptions,
          getReferencedColumn: (t) => t.rewardId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RewardRedemptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.rewardRedemptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RewardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RewardsTable,
          Reward,
          $$RewardsTableFilterComposer,
          $$RewardsTableOrderingComposer,
          $$RewardsTableAnnotationComposer,
          $$RewardsTableCreateCompanionBuilder,
          $$RewardsTableUpdateCompanionBuilder,
          (Reward, $$RewardsTableReferences),
          Reward,
          PrefetchHooks Function({bool familyId, bool rewardRedemptionsRefs})
        > {
  $$RewardsTableTableManager(_$AppDatabase db, $RewardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RewardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RewardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> coinPrice = const Value.absent(),
                Value<bool> needsOk = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RewardsCompanion(
                id: id,
                familyId: familyId,
                title: title,
                icon: icon,
                coinPrice: coinPrice,
                needsOk: needsOk,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String title,
                Value<String> icon = const Value.absent(),
                required int coinPrice,
                Value<bool> needsOk = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RewardsCompanion.insert(
                id: id,
                familyId: familyId,
                title: title,
                icon: icon,
                coinPrice: coinPrice,
                needsOk: needsOk,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RewardsTable, Reward>(table),
                  $$RewardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({familyId = false, rewardRedemptionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rewardRedemptionsRefs) db.rewardRedemptions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$RewardsTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$RewardsTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rewardRedemptionsRefs)
                        await $_getPrefetchedData<
                          Reward,
                          $RewardsTable,
                          RewardRedemption
                        >(
                          currentTable: table,
                          referencedTable: $$RewardsTableReferences
                              ._rewardRedemptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RewardsTableReferences(
                                db,
                                table,
                                p0,
                              ).rewardRedemptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rewardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RewardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RewardsTable,
      Reward,
      $$RewardsTableFilterComposer,
      $$RewardsTableOrderingComposer,
      $$RewardsTableAnnotationComposer,
      $$RewardsTableCreateCompanionBuilder,
      $$RewardsTableUpdateCompanionBuilder,
      (Reward, $$RewardsTableReferences),
      Reward,
      PrefetchHooks Function({bool familyId, bool rewardRedemptionsRefs})
    >;
typedef $$RewardRedemptionsTableCreateCompanionBuilder =
    RewardRedemptionsCompanion Function({
      Value<int> id,
      required String rewardId,
      required String childId,
      required String familyId,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String> createdAtTz,
    });
typedef $$RewardRedemptionsTableUpdateCompanionBuilder =
    RewardRedemptionsCompanion Function({
      Value<int> id,
      Value<String> rewardId,
      Value<String> childId,
      Value<String> familyId,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String> createdAtTz,
    });

final class $$RewardRedemptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RewardRedemptionsTable,
          RewardRedemption
        > {
  $$RewardRedemptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RewardsTable _rewardIdTable(_$AppDatabase db) =>
      db.rewards.createAlias('reward_redemptions__reward_id__rewards__id');

  $$RewardsTableProcessedTableManager get rewardId {
    final $_column = $_itemColumn<String>('reward_id')!;

    final manager = $$RewardsTableTableManager(
      $_db,
      $_db.rewards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rewardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('reward_redemptions__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('reward_redemptions__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RewardRedemptionsTableFilterComposer
    extends Composer<_$AppDatabase, $RewardRedemptionsTable> {
  $$RewardRedemptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => ColumnFilters(column),
  );

  $$RewardsTableFilterComposer get rewardId {
    final $$RewardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rewardId,
      referencedTable: $db.rewards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardsTableFilterComposer(
            $db: $db,
            $table: $db.rewards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RewardRedemptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RewardRedemptionsTable> {
  $$RewardRedemptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => ColumnOrderings(column),
  );

  $$RewardsTableOrderingComposer get rewardId {
    final $$RewardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rewardId,
      referencedTable: $db.rewards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardsTableOrderingComposer(
            $db: $db,
            $table: $db.rewards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RewardRedemptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RewardRedemptionsTable> {
  $$RewardRedemptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdAtTz => $composableBuilder(
    column: $table.createdAtTz,
    builder: (column) => column,
  );

  $$RewardsTableAnnotationComposer get rewardId {
    final $$RewardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rewardId,
      referencedTable: $db.rewards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RewardsTableAnnotationComposer(
            $db: $db,
            $table: $db.rewards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RewardRedemptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RewardRedemptionsTable,
          RewardRedemption,
          $$RewardRedemptionsTableFilterComposer,
          $$RewardRedemptionsTableOrderingComposer,
          $$RewardRedemptionsTableAnnotationComposer,
          $$RewardRedemptionsTableCreateCompanionBuilder,
          $$RewardRedemptionsTableUpdateCompanionBuilder,
          (RewardRedemption, $$RewardRedemptionsTableReferences),
          RewardRedemption,
          PrefetchHooks Function({bool rewardId, bool childId, bool familyId})
        > {
  $$RewardRedemptionsTableTableManager(
    _$AppDatabase db,
    $RewardRedemptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RewardRedemptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RewardRedemptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RewardRedemptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> rewardId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdAtTz = const Value.absent(),
              }) => RewardRedemptionsCompanion(
                id: id,
                rewardId: rewardId,
                childId: childId,
                familyId: familyId,
                status: status,
                createdAt: createdAt,
                createdAtTz: createdAtTz,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String rewardId,
                required String childId,
                required String familyId,
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdAtTz = const Value.absent(),
              }) => RewardRedemptionsCompanion.insert(
                id: id,
                rewardId: rewardId,
                childId: childId,
                familyId: familyId,
                status: status,
                createdAt: createdAt,
                createdAtTz: createdAtTz,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RewardRedemptionsTable, RewardRedemption>(table),
                  $$RewardRedemptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({rewardId = false, childId = false, familyId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (rewardId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.rewardId,
                            referencedTable: $$RewardRedemptionsTableReferences
                                ._rewardIdTable(db),
                            referencedColumn: $$RewardRedemptionsTableReferences
                                ._rewardIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (childId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.childId,
                            referencedTable: $$RewardRedemptionsTableReferences
                                ._childIdTable(db),
                            referencedColumn: $$RewardRedemptionsTableReferences
                                ._childIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$RewardRedemptionsTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$RewardRedemptionsTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RewardRedemptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RewardRedemptionsTable,
      RewardRedemption,
      $$RewardRedemptionsTableFilterComposer,
      $$RewardRedemptionsTableOrderingComposer,
      $$RewardRedemptionsTableAnnotationComposer,
      $$RewardRedemptionsTableCreateCompanionBuilder,
      $$RewardRedemptionsTableUpdateCompanionBuilder,
      (RewardRedemption, $$RewardRedemptionsTableReferences),
      RewardRedemption,
      PrefetchHooks Function({bool rewardId, bool childId, bool familyId})
    >;
typedef $$BadgesTableCreateCompanionBuilder = BadgesCompanion Function({
  required String id,
  required String title,
  Value<String> icon,
  Value<String> description,
  Value<int> rowid,
});
typedef $$BadgesTableUpdateCompanionBuilder = BadgesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> icon,
  Value<String> description,
  Value<int> rowid,
});

final class $$BadgesTableReferences
    extends BaseReferences<_$AppDatabase, $BadgesTable, Badge> {
  $$BadgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EarnedBadgesTable, List<EarnedBadge>>
  _earnedBadgesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.earnedBadges,
    aliasName: 'badges__id__earned_badges__badge_id',
  );

  $$EarnedBadgesTableProcessedTableManager get earnedBadgesRefs {
    final manager = $$EarnedBadgesTableTableManager(
      $_db,
      $_db.earnedBadges,
    ).filter((f) => f.badgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_earnedBadgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BadgesTableFilterComposer
    extends Composer<_$AppDatabase, $BadgesTable> {
  $$BadgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> earnedBadgesRefs(
    Expression<bool> Function($$EarnedBadgesTableFilterComposer f) f,
  ) {
    final $$EarnedBadgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.badgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableFilterComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BadgesTableOrderingComposer
    extends Composer<_$AppDatabase, $BadgesTable> {
  $$BadgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BadgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BadgesTable> {
  $$BadgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  Expression<T> earnedBadgesRefs<T extends Object>(
    Expression<T> Function($$EarnedBadgesTableAnnotationComposer a) f,
  ) {
    final $$EarnedBadgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.earnedBadges,
      getReferencedColumn: (t) => t.badgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EarnedBadgesTableAnnotationComposer(
            $db: $db,
            $table: $db.earnedBadges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BadgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BadgesTable,
          Badge,
          $$BadgesTableFilterComposer,
          $$BadgesTableOrderingComposer,
          $$BadgesTableAnnotationComposer,
          $$BadgesTableCreateCompanionBuilder,
          $$BadgesTableUpdateCompanionBuilder,
          (Badge, $$BadgesTableReferences),
          Badge,
          PrefetchHooks Function({bool earnedBadgesRefs})
        > {
  $$BadgesTableTableManager(_$AppDatabase db, $BadgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BadgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BadgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BadgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BadgesCompanion(
                id: id,
                title: title,
                icon: icon,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> icon = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BadgesCompanion.insert(
                id: id,
                title: title,
                icon: icon,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BadgesTable, Badge>(table),
                  $$BadgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({earnedBadgesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (earnedBadgesRefs) db.earnedBadges],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (earnedBadgesRefs)
                    await $_getPrefetchedData<Badge, $BadgesTable, EarnedBadge>(
                      currentTable: table,
                      referencedTable: $$BadgesTableReferences
                          ._earnedBadgesRefsTable(db),
                      managerFromTypedResult: (p0) => $$BadgesTableReferences(
                        db,
                        table,
                        p0,
                      ).earnedBadgesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.badgeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BadgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BadgesTable,
      Badge,
      $$BadgesTableFilterComposer,
      $$BadgesTableOrderingComposer,
      $$BadgesTableAnnotationComposer,
      $$BadgesTableCreateCompanionBuilder,
      $$BadgesTableUpdateCompanionBuilder,
      (Badge, $$BadgesTableReferences),
      Badge,
      PrefetchHooks Function({bool earnedBadgesRefs})
    >;
typedef $$EarnedBadgesTableCreateCompanionBuilder =
    EarnedBadgesCompanion Function({
      Value<int> id,
      required String badgeId,
      required String childId,
      required String familyId,
      Value<DateTime> earnedAt,
      Value<String> earnedAtTz,
    });
typedef $$EarnedBadgesTableUpdateCompanionBuilder =
    EarnedBadgesCompanion Function({
      Value<int> id,
      Value<String> badgeId,
      Value<String> childId,
      Value<String> familyId,
      Value<DateTime> earnedAt,
      Value<String> earnedAtTz,
    });

final class $$EarnedBadgesTableReferences
    extends BaseReferences<_$AppDatabase, $EarnedBadgesTable, EarnedBadge> {
  $$EarnedBadgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BadgesTable _badgeIdTable(_$AppDatabase db) =>
      db.badges.createAlias('earned_badges__badge_id__badges__id');

  $$BadgesTableProcessedTableManager get badgeId {
    final $_column = $_itemColumn<String>('badge_id')!;

    final manager = $$BadgesTableTableManager(
      $_db,
      $_db.badges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_badgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('earned_badges__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('earned_badges__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EarnedBadgesTableFilterComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedAtTz => $composableBuilder(
    column: $table.earnedAtTz,
    builder: (column) => ColumnFilters(column),
  );

  $$BadgesTableFilterComposer get badgeId {
    final $$BadgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.badgeId,
      referencedTable: $db.badges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BadgesTableFilterComposer(
            $db: $db,
            $table: $db.badges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EarnedBadgesTableOrderingComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedAtTz => $composableBuilder(
    column: $table.earnedAtTz,
    builder: (column) => ColumnOrderings(column),
  );

  $$BadgesTableOrderingComposer get badgeId {
    final $$BadgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.badgeId,
      referencedTable: $db.badges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BadgesTableOrderingComposer(
            $db: $db,
            $table: $db.badges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EarnedBadgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EarnedBadgesTable> {
  $$EarnedBadgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

  GeneratedColumn<String> get earnedAtTz => $composableBuilder(
    column: $table.earnedAtTz,
    builder: (column) => column,
  );

  $$BadgesTableAnnotationComposer get badgeId {
    final $$BadgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.badgeId,
      referencedTable: $db.badges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BadgesTableAnnotationComposer(
            $db: $db,
            $table: $db.badges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EarnedBadgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EarnedBadgesTable,
          EarnedBadge,
          $$EarnedBadgesTableFilterComposer,
          $$EarnedBadgesTableOrderingComposer,
          $$EarnedBadgesTableAnnotationComposer,
          $$EarnedBadgesTableCreateCompanionBuilder,
          $$EarnedBadgesTableUpdateCompanionBuilder,
          (EarnedBadge, $$EarnedBadgesTableReferences),
          EarnedBadge,
          PrefetchHooks Function({bool badgeId, bool childId, bool familyId})
        > {
  $$EarnedBadgesTableTableManager(_$AppDatabase db, $EarnedBadgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EarnedBadgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EarnedBadgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EarnedBadgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> badgeId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
                Value<String> earnedAtTz = const Value.absent(),
              }) => EarnedBadgesCompanion(
                id: id,
                badgeId: badgeId,
                childId: childId,
                familyId: familyId,
                earnedAt: earnedAt,
                earnedAtTz: earnedAtTz,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String badgeId,
                required String childId,
                required String familyId,
                Value<DateTime> earnedAt = const Value.absent(),
                Value<String> earnedAtTz = const Value.absent(),
              }) => EarnedBadgesCompanion.insert(
                id: id,
                badgeId: badgeId,
                childId: childId,
                familyId: familyId,
                earnedAt: earnedAt,
                earnedAtTz: earnedAtTz,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EarnedBadgesTable, EarnedBadge>(table),
                  $$EarnedBadgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({badgeId = false, childId = false, familyId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (badgeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.badgeId,
                            referencedTable: $$EarnedBadgesTableReferences
                                ._badgeIdTable(db),
                            referencedColumn: $$EarnedBadgesTableReferences
                                ._badgeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (childId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.childId,
                            referencedTable: $$EarnedBadgesTableReferences
                                ._childIdTable(db),
                            referencedColumn: $$EarnedBadgesTableReferences
                                ._childIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (familyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.familyId,
                            referencedTable: $$EarnedBadgesTableReferences
                                ._familyIdTable(db),
                            referencedColumn: $$EarnedBadgesTableReferences
                                ._familyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EarnedBadgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EarnedBadgesTable,
      EarnedBadge,
      $$EarnedBadgesTableFilterComposer,
      $$EarnedBadgesTableOrderingComposer,
      $$EarnedBadgesTableAnnotationComposer,
      $$EarnedBadgesTableCreateCompanionBuilder,
      $$EarnedBadgesTableUpdateCompanionBuilder,
      (EarnedBadge, $$EarnedBadgesTableReferences),
      EarnedBadge,
      PrefetchHooks Function({bool badgeId, bool childId, bool familyId})
    >;
typedef $$PipWardrobeTableCreateCompanionBuilder =
    PipWardrobeCompanion Function({
      Value<int> id,
      required String childId,
      required String item,
      Value<bool> owned,
      Value<int> priceCoins,
    });
typedef $$PipWardrobeTableUpdateCompanionBuilder =
    PipWardrobeCompanion Function({
      Value<int> id,
      Value<String> childId,
      Value<String> item,
      Value<bool> owned,
      Value<int> priceCoins,
    });

final class $$PipWardrobeTableReferences
    extends BaseReferences<_$AppDatabase, $PipWardrobeTable, PipWardrobeData> {
  $$PipWardrobeTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('pip_wardrobe__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PipWardrobeTableFilterComposer
    extends Composer<_$AppDatabase, $PipWardrobeTable> {
  $$PipWardrobeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PipWardrobeTableOrderingComposer
    extends Composer<_$AppDatabase, $PipWardrobeTable> {
  $$PipWardrobeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PipWardrobeTableAnnotationComposer
    extends Composer<_$AppDatabase, $PipWardrobeTable> {
  $$PipWardrobeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<bool> get owned =>
      $composableBuilder(column: $table.owned, builder: (column) => column);

  GeneratedColumn<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => column,
  );

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PipWardrobeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PipWardrobeTable,
          PipWardrobeData,
          $$PipWardrobeTableFilterComposer,
          $$PipWardrobeTableOrderingComposer,
          $$PipWardrobeTableAnnotationComposer,
          $$PipWardrobeTableCreateCompanionBuilder,
          $$PipWardrobeTableUpdateCompanionBuilder,
          (PipWardrobeData, $$PipWardrobeTableReferences),
          PipWardrobeData,
          PrefetchHooks Function({bool childId})
        > {
  $$PipWardrobeTableTableManager(_$AppDatabase db, $PipWardrobeTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PipWardrobeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PipWardrobeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PipWardrobeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<bool> owned = const Value.absent(),
                Value<int> priceCoins = const Value.absent(),
              }) => PipWardrobeCompanion(
                id: id,
                childId: childId,
                item: item,
                owned: owned,
                priceCoins: priceCoins,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String childId,
                required String item,
                Value<bool> owned = const Value.absent(),
                Value<int> priceCoins = const Value.absent(),
              }) => PipWardrobeCompanion.insert(
                id: id,
                childId: childId,
                item: item,
                owned: owned,
                priceCoins: priceCoins,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PipWardrobeTable, PipWardrobeData>(table),
                  $$PipWardrobeTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$PipWardrobeTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$PipWardrobeTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PipWardrobeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PipWardrobeTable,
      PipWardrobeData,
      $$PipWardrobeTableFilterComposer,
      $$PipWardrobeTableOrderingComposer,
      $$PipWardrobeTableAnnotationComposer,
      $$PipWardrobeTableCreateCompanionBuilder,
      $$PipWardrobeTableUpdateCompanionBuilder,
      (PipWardrobeData, $$PipWardrobeTableReferences),
      PipWardrobeData,
      PrefetchHooks Function({bool childId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String familyId,
  Value<String> pocketMoneyMode,
  Value<int> payoutDay,
  Value<int> coinValuePencePerCoin,
  Value<bool> notifApprovals,
  Value<bool> notifPayout,
  Value<bool> notifSummary,
  Value<bool> crashReportConsent,
  Value<bool> kidGateEnabled,
  Value<String> timeZone,
  Value<DateTime?> updatedAt,
  Value<String> updatedAtTz,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> familyId,
  Value<String> pocketMoneyMode,
  Value<int> payoutDay,
  Value<int> coinValuePencePerCoin,
  Value<bool> notifApprovals,
  Value<bool> notifPayout,
  Value<bool> notifSummary,
  Value<bool> crashReportConsent,
  Value<bool> kidGateEnabled,
  Value<String> timeZone,
  Value<DateTime?> updatedAt,
  Value<String> updatedAtTz,
  Value<int> rowid,
});

final class $$SettingsTableReferences
    extends BaseReferences<_$AppDatabase, $SettingsTable, Setting> {
  $$SettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamiliesTable _familyIdTable(_$AppDatabase db) =>
      db.families.createAlias('settings__family_id__families__id');

  $$FamiliesTableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesTableTableManager(
      $_db,
      $_db.families,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payoutDay => $composableBuilder(
    column: $table.payoutDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifApprovals => $composableBuilder(
    column: $table.notifApprovals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifPayout => $composableBuilder(
    column: $table.notifPayout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifSummary => $composableBuilder(
    column: $table.notifSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get crashReportConsent => $composableBuilder(
    column: $table.crashReportConsent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kidGateEnabled => $composableBuilder(
    column: $table.kidGateEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesTableFilterComposer get familyId {
    final $$FamiliesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableFilterComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payoutDay => $composableBuilder(
    column: $table.payoutDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifApprovals => $composableBuilder(
    column: $table.notifApprovals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifPayout => $composableBuilder(
    column: $table.notifPayout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifSummary => $composableBuilder(
    column: $table.notifSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get crashReportConsent => $composableBuilder(
    column: $table.crashReportConsent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kidGateEnabled => $composableBuilder(
    column: $table.kidGateEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesTableOrderingComposer get familyId {
    final $$FamiliesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableOrderingComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pocketMoneyMode => $composableBuilder(
    column: $table.pocketMoneyMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payoutDay =>
      $composableBuilder(column: $table.payoutDay, builder: (column) => column);

  GeneratedColumn<int> get coinValuePencePerCoin => $composableBuilder(
    column: $table.coinValuePencePerCoin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifApprovals => $composableBuilder(
    column: $table.notifApprovals,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifPayout => $composableBuilder(
    column: $table.notifPayout,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifSummary => $composableBuilder(
    column: $table.notifSummary,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get crashReportConsent => $composableBuilder(
    column: $table.crashReportConsent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kidGateEnabled => $composableBuilder(
    column: $table.kidGateEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAtTz => $composableBuilder(
    column: $table.updatedAtTz,
    builder: (column) => column,
  );

  $$FamiliesTableAnnotationComposer get familyId {
    final $$FamiliesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.families,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesTableAnnotationComposer(
            $db: $db,
            $table: $db.families,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, $$SettingsTableReferences),
          Setting,
          PrefetchHooks Function({bool familyId})
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> familyId = const Value.absent(),
                Value<String> pocketMoneyMode = const Value.absent(),
                Value<int> payoutDay = const Value.absent(),
                Value<int> coinValuePencePerCoin = const Value.absent(),
                Value<bool> notifApprovals = const Value.absent(),
                Value<bool> notifPayout = const Value.absent(),
                Value<bool> notifSummary = const Value.absent(),
                Value<bool> crashReportConsent = const Value.absent(),
                Value<bool> kidGateEnabled = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String> updatedAtTz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                familyId: familyId,
                pocketMoneyMode: pocketMoneyMode,
                payoutDay: payoutDay,
                coinValuePencePerCoin: coinValuePencePerCoin,
                notifApprovals: notifApprovals,
                notifPayout: notifPayout,
                notifSummary: notifSummary,
                crashReportConsent: crashReportConsent,
                kidGateEnabled: kidGateEnabled,
                timeZone: timeZone,
                updatedAt: updatedAt,
                updatedAtTz: updatedAtTz,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String familyId,
                Value<String> pocketMoneyMode = const Value.absent(),
                Value<int> payoutDay = const Value.absent(),
                Value<int> coinValuePencePerCoin = const Value.absent(),
                Value<bool> notifApprovals = const Value.absent(),
                Value<bool> notifPayout = const Value.absent(),
                Value<bool> notifSummary = const Value.absent(),
                Value<bool> crashReportConsent = const Value.absent(),
                Value<bool> kidGateEnabled = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String> updatedAtTz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                familyId: familyId,
                pocketMoneyMode: pocketMoneyMode,
                payoutDay: payoutDay,
                coinValuePencePerCoin: coinValuePencePerCoin,
                notifApprovals: notifApprovals,
                notifPayout: notifPayout,
                notifSummary: notifSummary,
                crashReportConsent: crashReportConsent,
                kidGateEnabled: kidGateEnabled,
                timeZone: timeZone,
                updatedAt: updatedAt,
                updatedAtTz: updatedAtTz,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  $$SettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({familyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (familyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.familyId,
                        referencedTable: $$SettingsTableReferences
                            ._familyIdTable(db),
                        referencedColumn: $$SettingsTableReferences
                            ._familyIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, $$SettingsTableReferences),
      Setting,
      PrefetchHooks Function({bool familyId})
    >;
typedef $$AppStateTableCreateCompanionBuilder = AppStateCompanion Function({
  Value<int> id,
  Value<bool> onboardingComplete,
  Value<String> subscriptionStatus,
  Value<DateTime?> trialStart,
  Value<String> trialStartTz,
  Value<String?> activeChildId,
  Value<String> appMode,
});
typedef $$AppStateTableUpdateCompanionBuilder = AppStateCompanion Function({
  Value<int> id,
  Value<bool> onboardingComplete,
  Value<String> subscriptionStatus,
  Value<DateTime?> trialStart,
  Value<String> trialStartTz,
  Value<String?> activeChildId,
  Value<String> appMode,
});

class $$AppStateTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get trialStart => $composableBuilder(
    column: $table.trialStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trialStartTz => $composableBuilder(
    column: $table.trialStartTz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeChildId => $composableBuilder(
    column: $table.activeChildId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appMode => $composableBuilder(
    column: $table.appMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get trialStart => $composableBuilder(
    column: $table.trialStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trialStartTz => $composableBuilder(
    column: $table.trialStartTz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeChildId => $composableBuilder(
    column: $table.activeChildId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appMode => $composableBuilder(
    column: $table.appMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get trialStart => $composableBuilder(
    column: $table.trialStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trialStartTz => $composableBuilder(
    column: $table.trialStartTz,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeChildId => $composableBuilder(
    column: $table.activeChildId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appMode =>
      $composableBuilder(column: $table.appMode, builder: (column) => column);
}

class $$AppStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppStateTable,
          AppStateData,
          $$AppStateTableFilterComposer,
          $$AppStateTableOrderingComposer,
          $$AppStateTableAnnotationComposer,
          $$AppStateTableCreateCompanionBuilder,
          $$AppStateTableUpdateCompanionBuilder,
          (
            AppStateData,
            BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>,
          ),
          AppStateData,
          PrefetchHooks Function()
        > {
  $$AppStateTableTableManager(_$AppDatabase db, $AppStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<String> subscriptionStatus = const Value.absent(),
                Value<DateTime?> trialStart = const Value.absent(),
                Value<String> trialStartTz = const Value.absent(),
                Value<String?> activeChildId = const Value.absent(),
                Value<String> appMode = const Value.absent(),
              }) => AppStateCompanion(
                id: id,
                onboardingComplete: onboardingComplete,
                subscriptionStatus: subscriptionStatus,
                trialStart: trialStart,
                trialStartTz: trialStartTz,
                activeChildId: activeChildId,
                appMode: appMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<String> subscriptionStatus = const Value.absent(),
                Value<DateTime?> trialStart = const Value.absent(),
                Value<String> trialStartTz = const Value.absent(),
                Value<String?> activeChildId = const Value.absent(),
                Value<String> appMode = const Value.absent(),
              }) => AppStateCompanion.insert(
                id: id,
                onboardingComplete: onboardingComplete,
                subscriptionStatus: subscriptionStatus,
                trialStart: trialStart,
                trialStartTz: trialStartTz,
                activeChildId: activeChildId,
                appMode: appMode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppStateTable, AppStateData>(table),
                  BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppStateTable,
      AppStateData,
      $$AppStateTableFilterComposer,
      $$AppStateTableOrderingComposer,
      $$AppStateTableAnnotationComposer,
      $$AppStateTableCreateCompanionBuilder,
      $$AppStateTableUpdateCompanionBuilder,
      (
        AppStateData,
        BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>,
      ),
      AppStateData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FamiliesTableTableManager get families =>
      $$FamiliesTableTableManager(_db, _db.families);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$QuestsTableTableManager get quests =>
      $$QuestsTableTableManager(_db, _db.quests);
  $$QuestCompletionsTableTableManager get questCompletions =>
      $$QuestCompletionsTableTableManager(_db, _db.questCompletions);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$RewardsTableTableManager get rewards =>
      $$RewardsTableTableManager(_db, _db.rewards);
  $$RewardRedemptionsTableTableManager get rewardRedemptions =>
      $$RewardRedemptionsTableTableManager(_db, _db.rewardRedemptions);
  $$BadgesTableTableManager get badges =>
      $$BadgesTableTableManager(_db, _db.badges);
  $$EarnedBadgesTableTableManager get earnedBadges =>
      $$EarnedBadgesTableTableManager(_db, _db.earnedBadges);
  $$PipWardrobeTableTableManager get pipWardrobe =>
      $$PipWardrobeTableTableManager(_db, _db.pipWardrobe);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db, _db.appState);
}
