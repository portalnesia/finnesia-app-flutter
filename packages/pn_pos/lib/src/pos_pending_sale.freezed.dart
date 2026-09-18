// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_pending_sale.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingSaleReceipt {
  /// Null when the outlet's name was not known at the till. Printed only when present,
  /// matching `formatReceiptEscPos`.
  String? get outletName;
  String? get cashierName;
  num get subtotal;
  num get discountAmount;
  num get taxAmount;
  num get grandTotal;
  num get tenderedAmount;
  num get changeAmount;
  List<SalesInvoiceItem> get items;

  /// Create a copy of PendingSaleReceipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PendingSaleReceiptCopyWith<PendingSaleReceipt> get copyWith =>
      _$PendingSaleReceiptCopyWithImpl<PendingSaleReceipt>(
          this as PendingSaleReceipt, _$identity);

  /// Serializes this PendingSaleReceipt to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PendingSaleReceipt;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PendingSaleReceipt &&
            (identical(other.outletName, _this.outletName) ||
                other.outletName == _this.outletName) &&
            (identical(other.cashierName, _this.cashierName) ||
                other.cashierName == _this.cashierName) &&
            (identical(other.subtotal, _this.subtotal) ||
                other.subtotal == _this.subtotal) &&
            (identical(other.discountAmount, _this.discountAmount) ||
                other.discountAmount == _this.discountAmount) &&
            (identical(other.taxAmount, _this.taxAmount) ||
                other.taxAmount == _this.taxAmount) &&
            (identical(other.grandTotal, _this.grandTotal) ||
                other.grandTotal == _this.grandTotal) &&
            (identical(other.tenderedAmount, _this.tenderedAmount) ||
                other.tenderedAmount == _this.tenderedAmount) &&
            (identical(other.changeAmount, _this.changeAmount) ||
                other.changeAmount == _this.changeAmount) &&
            const DeepCollectionEquality().equals(other.items, _this.items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PendingSaleReceipt;
    return Object.hash(
        runtimeType,
        _this.outletName,
        _this.cashierName,
        _this.subtotal,
        _this.discountAmount,
        _this.taxAmount,
        _this.grandTotal,
        _this.tenderedAmount,
        _this.changeAmount,
        const DeepCollectionEquality().hash(_this.items));
  }

  @override
  String toString() {
    final _this = this as PendingSaleReceipt;
    return 'PendingSaleReceipt(outletName: ${_this.outletName}, cashierName: ${_this.cashierName}, subtotal: ${_this.subtotal}, discountAmount: ${_this.discountAmount}, taxAmount: ${_this.taxAmount}, grandTotal: ${_this.grandTotal}, tenderedAmount: ${_this.tenderedAmount}, changeAmount: ${_this.changeAmount}, items: ${_this.items})';
  }
}

/// @nodoc
abstract mixin class $PendingSaleReceiptCopyWith<$Res> {
  factory $PendingSaleReceiptCopyWith(
          PendingSaleReceipt value, $Res Function(PendingSaleReceipt) _then) =
      _$PendingSaleReceiptCopyWithImpl;
  @useResult
  $Res call(
      {String? outletName,
      String? cashierName,
      num subtotal,
      num discountAmount,
      num taxAmount,
      num grandTotal,
      num tenderedAmount,
      num changeAmount,
      List<SalesInvoiceItem> items});
}

/// @nodoc
class _$PendingSaleReceiptCopyWithImpl<$Res>
    implements $PendingSaleReceiptCopyWith<$Res> {
  _$PendingSaleReceiptCopyWithImpl(this._self, this._then);

  final PendingSaleReceipt _self;
  final $Res Function(PendingSaleReceipt) _then;

  /// Create a copy of PendingSaleReceipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outletName = freezed,
    Object? cashierName = freezed,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? taxAmount = null,
    Object? grandTotal = null,
    Object? tenderedAmount = null,
    Object? changeAmount = null,
    Object? items = null,
  }) {
    return _then(PendingSaleReceipt(
      outletName: freezed == outletName
          ? _self.outletName
          : outletName // ignore: cast_nullable_to_non_nullable
              as String?,
      cashierName: freezed == cashierName
          ? _self.cashierName
          : cashierName // ignore: cast_nullable_to_non_nullable
              as String?,
      subtotal: null == subtotal
          ? _self.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as num,
      discountAmount: null == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      taxAmount: null == taxAmount
          ? _self.taxAmount
          : taxAmount // ignore: cast_nullable_to_non_nullable
              as num,
      grandTotal: null == grandTotal
          ? _self.grandTotal
          : grandTotal // ignore: cast_nullable_to_non_nullable
              as num,
      tenderedAmount: null == tenderedAmount
          ? _self.tenderedAmount
          : tenderedAmount // ignore: cast_nullable_to_non_nullable
              as num,
      changeAmount: null == changeAmount
          ? _self.changeAmount
          : changeAmount // ignore: cast_nullable_to_non_nullable
              as num,
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SalesInvoiceItem>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PendingSaleReceipt].
extension PendingSaleReceiptPatterns on PendingSaleReceipt {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PendingSaleReceipt value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PendingSaleReceipt value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PendingSaleReceipt value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String? outletName,
            String? cashierName,
            num subtotal,
            num discountAmount,
            num taxAmount,
            num grandTotal,
            num tenderedAmount,
            num changeAmount,
            List<SalesInvoiceItem> items)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt() when $default != null:
        return $default(
            _that.outletName,
            _that.cashierName,
            _that.subtotal,
            _that.discountAmount,
            _that.taxAmount,
            _that.grandTotal,
            _that.tenderedAmount,
            _that.changeAmount,
            _that.items);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String? outletName,
            String? cashierName,
            num subtotal,
            num discountAmount,
            num taxAmount,
            num grandTotal,
            num tenderedAmount,
            num changeAmount,
            List<SalesInvoiceItem> items)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt():
        return $default(
            _that.outletName,
            _that.cashierName,
            _that.subtotal,
            _that.discountAmount,
            _that.taxAmount,
            _that.grandTotal,
            _that.tenderedAmount,
            _that.changeAmount,
            _that.items);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String? outletName,
            String? cashierName,
            num subtotal,
            num discountAmount,
            num taxAmount,
            num grandTotal,
            num tenderedAmount,
            num changeAmount,
            List<SalesInvoiceItem> items)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSaleReceipt() when $default != null:
        return $default(
            _that.outletName,
            _that.cashierName,
            _that.subtotal,
            _that.discountAmount,
            _that.taxAmount,
            _that.grandTotal,
            _that.tenderedAmount,
            _that.changeAmount,
            _that.items);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PendingSaleReceipt implements PendingSaleReceipt {
  const _PendingSaleReceipt(
      {this.outletName,
      this.cashierName,
      required this.subtotal,
      required this.discountAmount,
      required this.taxAmount,
      required this.grandTotal,
      required this.tenderedAmount,
      required this.changeAmount,
      required List<SalesInvoiceItem> items})
      : _items = items;
  factory _PendingSaleReceipt.fromJson(Map<String, dynamic> json) =>
      _$PendingSaleReceiptFromJson(json);

  /// Null when the outlet's name was not known at the till. Printed only when present,
  /// matching `formatReceiptEscPos`.
  @override
  final String? outletName;
  @override
  final String? cashierName;
  @override
  final num subtotal;
  @override
  final num discountAmount;
  @override
  final num taxAmount;
  @override
  final num grandTotal;
  @override
  final num tenderedAmount;
  @override
  final num changeAmount;
  final List<SalesInvoiceItem> _items;
  @override
  List<SalesInvoiceItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Create a copy of PendingSaleReceipt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PendingSaleReceiptCopyWith<_PendingSaleReceipt> get copyWith =>
      __$PendingSaleReceiptCopyWithImpl<_PendingSaleReceipt>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PendingSaleReceiptToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PendingSaleReceipt &&
            (identical(other.outletName, outletName) ||
                other.outletName == outletName) &&
            (identical(other.cashierName, cashierName) ||
                other.cashierName == cashierName) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.taxAmount, taxAmount) ||
                other.taxAmount == taxAmount) &&
            (identical(other.grandTotal, grandTotal) ||
                other.grandTotal == grandTotal) &&
            (identical(other.tenderedAmount, tenderedAmount) ||
                other.tenderedAmount == tenderedAmount) &&
            (identical(other.changeAmount, changeAmount) ||
                other.changeAmount == changeAmount) &&
            const DeepCollectionEquality().equals(other.items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        outletName,
        cashierName,
        subtotal,
        discountAmount,
        taxAmount,
        grandTotal,
        tenderedAmount,
        changeAmount,
        const DeepCollectionEquality().hash(_items));
  }

  @override
  String toString() {
    return 'PendingSaleReceipt(outletName: $outletName, cashierName: $cashierName, subtotal: $subtotal, discountAmount: $discountAmount, taxAmount: $taxAmount, grandTotal: $grandTotal, tenderedAmount: $tenderedAmount, changeAmount: $changeAmount, items: $items)';
  }
}

/// @nodoc
abstract mixin class _$PendingSaleReceiptCopyWith<$Res>
    implements $PendingSaleReceiptCopyWith<$Res> {
  factory _$PendingSaleReceiptCopyWith(
          _PendingSaleReceipt value, $Res Function(_PendingSaleReceipt) _then) =
      __$PendingSaleReceiptCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? outletName,
      String? cashierName,
      num subtotal,
      num discountAmount,
      num taxAmount,
      num grandTotal,
      num tenderedAmount,
      num changeAmount,
      List<SalesInvoiceItem> items});
}

/// @nodoc
class __$PendingSaleReceiptCopyWithImpl<$Res>
    implements _$PendingSaleReceiptCopyWith<$Res> {
  __$PendingSaleReceiptCopyWithImpl(this._self, this._then);

  final _PendingSaleReceipt _self;
  final $Res Function(_PendingSaleReceipt) _then;

  /// Create a copy of PendingSaleReceipt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? outletName = freezed,
    Object? cashierName = freezed,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? taxAmount = null,
    Object? grandTotal = null,
    Object? tenderedAmount = null,
    Object? changeAmount = null,
    Object? items = null,
  }) {
    return _then(_PendingSaleReceipt(
      outletName: freezed == outletName
          ? _self.outletName
          : outletName // ignore: cast_nullable_to_non_nullable
              as String?,
      cashierName: freezed == cashierName
          ? _self.cashierName
          : cashierName // ignore: cast_nullable_to_non_nullable
              as String?,
      subtotal: null == subtotal
          ? _self.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as num,
      discountAmount: null == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      taxAmount: null == taxAmount
          ? _self.taxAmount
          : taxAmount // ignore: cast_nullable_to_non_nullable
              as num,
      grandTotal: null == grandTotal
          ? _self.grandTotal
          : grandTotal // ignore: cast_nullable_to_non_nullable
              as num,
      tenderedAmount: null == tenderedAmount
          ? _self.tenderedAmount
          : tenderedAmount // ignore: cast_nullable_to_non_nullable
              as num,
      changeAmount: null == changeAmount
          ? _self.changeAmount
          : changeAmount // ignore: cast_nullable_to_non_nullable
              as num,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SalesInvoiceItem>,
    ));
  }
}

/// @nodoc
mixin _$PendingSale {
  /// The idempotency key. The server looks a sale up by `(company, client_ref)` before
  /// creating one, which is what makes a retry safe. Unique in the database, not just in
  /// this list.
  String get clientRef;

  /// The tenant. Carried per row rather than taken from the session at send time: the
  /// queue outlives a sign-out, and a device re-paired to another tenant must not post the
  /// previous one's sales.
  String get companyId;
  String get outletId;

  /// **Who typed it**, not who sends it. The server attributes the sale to whoever is
  /// authenticated at send time and does not accept this field, so it is the only record
  /// of the cashier who actually took the money (`plan/offline-queue/findings.md` F4).
  String get cashierId;

  /// The shift the sale was rung up under, or null when the company runs without shifts.
  String? get shiftId;
  PendingSaleStatus get status;

  /// The server's own sentence when it refused, so the panel can show what to fix.
  String? get error;

  /// The tablet's clock when the money was taken, RFC 3339. Sent on retries only: the
  /// first attempt leaves it to the server, because a tablet clock more than five minutes
  /// ahead is refused outright (`findings.md` F2, README D-Q5).
  String get paidAt;

  /// When the entry was written, RFC 3339.
  String get createdAt;

  /// How many times a send has failed without a definite answer. Shown in the panel so a
  /// sale that keeps failing is visible rather than silently retrying forever.
  int get attempts;

  /// The checkout payload, without the three fields above. See the class doc.
  POSCheckoutDTO get payload;

  /// What the temporary receipt prints. See [PendingSaleReceipt].
  PendingSaleReceipt get receipt;

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PendingSaleCopyWith<PendingSale> get copyWith =>
      _$PendingSaleCopyWithImpl<PendingSale>(this as PendingSale, _$identity);

  /// Serializes this PendingSale to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PendingSale;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PendingSale &&
            (identical(other.clientRef, _this.clientRef) ||
                other.clientRef == _this.clientRef) &&
            (identical(other.companyId, _this.companyId) ||
                other.companyId == _this.companyId) &&
            (identical(other.outletId, _this.outletId) ||
                other.outletId == _this.outletId) &&
            (identical(other.cashierId, _this.cashierId) ||
                other.cashierId == _this.cashierId) &&
            (identical(other.shiftId, _this.shiftId) ||
                other.shiftId == _this.shiftId) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error) &&
            (identical(other.paidAt, _this.paidAt) ||
                other.paidAt == _this.paidAt) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.attempts, _this.attempts) ||
                other.attempts == _this.attempts) &&
            (identical(other.payload, _this.payload) ||
                other.payload == _this.payload) &&
            (identical(other.receipt, _this.receipt) ||
                other.receipt == _this.receipt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PendingSale;
    return Object.hash(
        runtimeType,
        _this.clientRef,
        _this.companyId,
        _this.outletId,
        _this.cashierId,
        _this.shiftId,
        _this.status,
        _this.error,
        _this.paidAt,
        _this.createdAt,
        _this.attempts,
        _this.payload,
        _this.receipt);
  }

  @override
  String toString() {
    final _this = this as PendingSale;
    return 'PendingSale(clientRef: ${_this.clientRef}, companyId: ${_this.companyId}, outletId: ${_this.outletId}, cashierId: ${_this.cashierId}, shiftId: ${_this.shiftId}, status: ${_this.status}, error: ${_this.error}, paidAt: ${_this.paidAt}, createdAt: ${_this.createdAt}, attempts: ${_this.attempts}, payload: ${_this.payload}, receipt: ${_this.receipt})';
  }
}

/// @nodoc
abstract mixin class $PendingSaleCopyWith<$Res> {
  factory $PendingSaleCopyWith(
          PendingSale value, $Res Function(PendingSale) _then) =
      _$PendingSaleCopyWithImpl;
  @useResult
  $Res call(
      {String clientRef,
      String companyId,
      String outletId,
      String cashierId,
      String? shiftId,
      PendingSaleStatus status,
      String? error,
      String paidAt,
      String createdAt,
      int attempts,
      POSCheckoutDTO payload,
      PendingSaleReceipt receipt});

  $POSCheckoutDTOCopyWith<$Res> get payload;
  $PendingSaleReceiptCopyWith<$Res> get receipt;
}

/// @nodoc
class _$PendingSaleCopyWithImpl<$Res> implements $PendingSaleCopyWith<$Res> {
  _$PendingSaleCopyWithImpl(this._self, this._then);

  final PendingSale _self;
  final $Res Function(PendingSale) _then;

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientRef = null,
    Object? companyId = null,
    Object? outletId = null,
    Object? cashierId = null,
    Object? shiftId = freezed,
    Object? status = null,
    Object? error = freezed,
    Object? paidAt = null,
    Object? createdAt = null,
    Object? attempts = null,
    Object? payload = null,
    Object? receipt = null,
  }) {
    return _then(PendingSale(
      clientRef: null == clientRef
          ? _self.clientRef
          : clientRef // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _self.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      cashierId: null == cashierId
          ? _self.cashierId
          : cashierId // ignore: cast_nullable_to_non_nullable
              as String,
      shiftId: freezed == shiftId
          ? _self.shiftId
          : shiftId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PendingSaleStatus,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: null == paidAt
          ? _self.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _self.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      payload: null == payload
          ? _self.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as POSCheckoutDTO,
      receipt: null == receipt
          ? _self.receipt
          : receipt // ignore: cast_nullable_to_non_nullable
              as PendingSaleReceipt,
    ));
  }

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $POSCheckoutDTOCopyWith<$Res> get payload {
    return $POSCheckoutDTOCopyWith<$Res>(_self.payload, (value) {
      return _then(_self.copyWith(payload: value));
    });
  }

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PendingSaleReceiptCopyWith<$Res> get receipt {
    return $PendingSaleReceiptCopyWith<$Res>(_self.receipt, (value) {
      return _then(_self.copyWith(receipt: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PendingSale].
extension PendingSalePatterns on PendingSale {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PendingSale value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingSale() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PendingSale value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSale():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PendingSale value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSale() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String clientRef,
            String companyId,
            String outletId,
            String cashierId,
            String? shiftId,
            PendingSaleStatus status,
            String? error,
            String paidAt,
            String createdAt,
            int attempts,
            POSCheckoutDTO payload,
            PendingSaleReceipt receipt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingSale() when $default != null:
        return $default(
            _that.clientRef,
            _that.companyId,
            _that.outletId,
            _that.cashierId,
            _that.shiftId,
            _that.status,
            _that.error,
            _that.paidAt,
            _that.createdAt,
            _that.attempts,
            _that.payload,
            _that.receipt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String clientRef,
            String companyId,
            String outletId,
            String cashierId,
            String? shiftId,
            PendingSaleStatus status,
            String? error,
            String paidAt,
            String createdAt,
            int attempts,
            POSCheckoutDTO payload,
            PendingSaleReceipt receipt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSale():
        return $default(
            _that.clientRef,
            _that.companyId,
            _that.outletId,
            _that.cashierId,
            _that.shiftId,
            _that.status,
            _that.error,
            _that.paidAt,
            _that.createdAt,
            _that.attempts,
            _that.payload,
            _that.receipt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String clientRef,
            String companyId,
            String outletId,
            String cashierId,
            String? shiftId,
            PendingSaleStatus status,
            String? error,
            String paidAt,
            String createdAt,
            int attempts,
            POSCheckoutDTO payload,
            PendingSaleReceipt receipt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingSale() when $default != null:
        return $default(
            _that.clientRef,
            _that.companyId,
            _that.outletId,
            _that.cashierId,
            _that.shiftId,
            _that.status,
            _that.error,
            _that.paidAt,
            _that.createdAt,
            _that.attempts,
            _that.payload,
            _that.receipt);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PendingSale implements PendingSale {
  const _PendingSale(
      {required this.clientRef,
      required this.companyId,
      required this.outletId,
      required this.cashierId,
      this.shiftId,
      required this.status,
      this.error,
      required this.paidAt,
      required this.createdAt,
      this.attempts = 0,
      required this.payload,
      required this.receipt});
  factory _PendingSale.fromJson(Map<String, dynamic> json) =>
      _$PendingSaleFromJson(json);

  /// The idempotency key. The server looks a sale up by `(company, client_ref)` before
  /// creating one, which is what makes a retry safe. Unique in the database, not just in
  /// this list.
  @override
  final String clientRef;

  /// The tenant. Carried per row rather than taken from the session at send time: the
  /// queue outlives a sign-out, and a device re-paired to another tenant must not post the
  /// previous one's sales.
  @override
  final String companyId;
  @override
  final String outletId;

  /// **Who typed it**, not who sends it. The server attributes the sale to whoever is
  /// authenticated at send time and does not accept this field, so it is the only record
  /// of the cashier who actually took the money (`plan/offline-queue/findings.md` F4).
  @override
  final String cashierId;

  /// The shift the sale was rung up under, or null when the company runs without shifts.
  @override
  final String? shiftId;
  @override
  final PendingSaleStatus status;

  /// The server's own sentence when it refused, so the panel can show what to fix.
  @override
  final String? error;

  /// The tablet's clock when the money was taken, RFC 3339. Sent on retries only: the
  /// first attempt leaves it to the server, because a tablet clock more than five minutes
  /// ahead is refused outright (`findings.md` F2, README D-Q5).
  @override
  final String paidAt;

  /// When the entry was written, RFC 3339.
  @override
  final String createdAt;

  /// How many times a send has failed without a definite answer. Shown in the panel so a
  /// sale that keeps failing is visible rather than silently retrying forever.
  @override
  @JsonKey()
  final int attempts;

  /// The checkout payload, without the three fields above. See the class doc.
  @override
  final POSCheckoutDTO payload;

  /// What the temporary receipt prints. See [PendingSaleReceipt].
  @override
  final PendingSaleReceipt receipt;

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PendingSaleCopyWith<_PendingSale> get copyWith =>
      __$PendingSaleCopyWithImpl<_PendingSale>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PendingSaleToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PendingSale &&
            (identical(other.clientRef, clientRef) ||
                other.clientRef == clientRef) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.outletId, outletId) ||
                other.outletId == outletId) &&
            (identical(other.cashierId, cashierId) ||
                other.cashierId == cashierId) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            (identical(other.receipt, receipt) || other.receipt == receipt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, clientRef, companyId, outletId, cashierId,
        shiftId, status, error, paidAt, createdAt, attempts, payload, receipt);
  }

  @override
  String toString() {
    return 'PendingSale(clientRef: $clientRef, companyId: $companyId, outletId: $outletId, cashierId: $cashierId, shiftId: $shiftId, status: $status, error: $error, paidAt: $paidAt, createdAt: $createdAt, attempts: $attempts, payload: $payload, receipt: $receipt)';
  }
}

/// @nodoc
abstract mixin class _$PendingSaleCopyWith<$Res>
    implements $PendingSaleCopyWith<$Res> {
  factory _$PendingSaleCopyWith(
          _PendingSale value, $Res Function(_PendingSale) _then) =
      __$PendingSaleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String clientRef,
      String companyId,
      String outletId,
      String cashierId,
      String? shiftId,
      PendingSaleStatus status,
      String? error,
      String paidAt,
      String createdAt,
      int attempts,
      POSCheckoutDTO payload,
      PendingSaleReceipt receipt});

  @override
  $POSCheckoutDTOCopyWith<$Res> get payload;
  @override
  $PendingSaleReceiptCopyWith<$Res> get receipt;
}

/// @nodoc
class __$PendingSaleCopyWithImpl<$Res> implements _$PendingSaleCopyWith<$Res> {
  __$PendingSaleCopyWithImpl(this._self, this._then);

  final _PendingSale _self;
  final $Res Function(_PendingSale) _then;

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? clientRef = null,
    Object? companyId = null,
    Object? outletId = null,
    Object? cashierId = null,
    Object? shiftId = freezed,
    Object? status = null,
    Object? error = freezed,
    Object? paidAt = null,
    Object? createdAt = null,
    Object? attempts = null,
    Object? payload = null,
    Object? receipt = null,
  }) {
    return _then(_PendingSale(
      clientRef: null == clientRef
          ? _self.clientRef
          : clientRef // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _self.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      cashierId: null == cashierId
          ? _self.cashierId
          : cashierId // ignore: cast_nullable_to_non_nullable
              as String,
      shiftId: freezed == shiftId
          ? _self.shiftId
          : shiftId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PendingSaleStatus,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: null == paidAt
          ? _self.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _self.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      payload: null == payload
          ? _self.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as POSCheckoutDTO,
      receipt: null == receipt
          ? _self.receipt
          : receipt // ignore: cast_nullable_to_non_nullable
              as PendingSaleReceipt,
    ));
  }

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $POSCheckoutDTOCopyWith<$Res> get payload {
    return $POSCheckoutDTOCopyWith<$Res>(_self.payload, (value) {
      return _then(_self.copyWith(payload: value));
    });
  }

  /// Create a copy of PendingSale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PendingSaleReceiptCopyWith<$Res> get receipt {
    return $PendingSaleReceiptCopyWith<$Res>(_self.receipt, (value) {
      return _then(_self.copyWith(receipt: value));
    });
  }
}

// dart format on
