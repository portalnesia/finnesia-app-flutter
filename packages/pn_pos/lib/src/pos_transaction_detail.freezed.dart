// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_transaction_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionDetail {
  /// The picked customer, or `''` for none. The source's `customerId: ''`.
  String get customerId;

  /// The name behind [customerId], carried along so the cart's summary row can name the
  /// customer without a second lookup.
  ///
  /// Null and `''` are not the same answer, and the source says why: a row that stayed silent
  /// for an id it holds would read "no detail yet" for a sale that has a customer on it. The
  /// till never attaches an id without a name today (see [shownCustomerName]), so null is what
  /// this carries in practice; the distinction is kept because it is the source's, and because
  /// the held-basket path in C7 is what will produce the other one.
  String? get customerName;

  /// The free note that prints on the receipt, not the customer's own record.
  String get customerMemo;

  /// Only shown when the outlet asks for it (`POSPreferences.showTableNumber`).
  String get tableNumber;

  /// Only shown when the outlet asks for it (`POSPreferences.showQueueNumber`).
  String get queueNumber;

  /// Create a copy of TransactionDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TransactionDetailCopyWith<TransactionDetail> get copyWith =>
      _$TransactionDetailCopyWithImpl<TransactionDetail>(
          this as TransactionDetail, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as TransactionDetail;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TransactionDetail &&
            (identical(other.customerId, _this.customerId) ||
                other.customerId == _this.customerId) &&
            (identical(other.customerName, _this.customerName) ||
                other.customerName == _this.customerName) &&
            (identical(other.customerMemo, _this.customerMemo) ||
                other.customerMemo == _this.customerMemo) &&
            (identical(other.tableNumber, _this.tableNumber) ||
                other.tableNumber == _this.tableNumber) &&
            (identical(other.queueNumber, _this.queueNumber) ||
                other.queueNumber == _this.queueNumber));
  }

  @override
  int get hashCode {
    final _this = this as TransactionDetail;
    return Object.hash(runtimeType, _this.customerId, _this.customerName,
        _this.customerMemo, _this.tableNumber, _this.queueNumber);
  }

  @override
  String toString() {
    final _this = this as TransactionDetail;
    return 'TransactionDetail(customerId: ${_this.customerId}, customerName: ${_this.customerName}, customerMemo: ${_this.customerMemo}, tableNumber: ${_this.tableNumber}, queueNumber: ${_this.queueNumber})';
  }
}

/// @nodoc
abstract mixin class $TransactionDetailCopyWith<$Res> {
  factory $TransactionDetailCopyWith(
          TransactionDetail value, $Res Function(TransactionDetail) _then) =
      _$TransactionDetailCopyWithImpl;
  @useResult
  $Res call(
      {String customerId,
      String? customerName,
      String customerMemo,
      String tableNumber,
      String queueNumber});
}

/// @nodoc
class _$TransactionDetailCopyWithImpl<$Res>
    implements $TransactionDetailCopyWith<$Res> {
  _$TransactionDetailCopyWithImpl(this._self, this._then);

  final TransactionDetail _self;
  final $Res Function(TransactionDetail) _then;

  /// Create a copy of TransactionDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? customerName = freezed,
    Object? customerMemo = null,
    Object? tableNumber = null,
    Object? queueNumber = null,
  }) {
    return _then(TransactionDetail(
      customerId: null == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: freezed == customerName
          ? _self.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: null == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String,
      tableNumber: null == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String,
      queueNumber: null == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [TransactionDetail].
extension TransactionDetailPatterns on TransactionDetail {
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
    TResult Function(_TransactionDetail value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail() when $default != null:
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
    TResult Function(_TransactionDetail value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail():
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
    TResult? Function(_TransactionDetail value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail() when $default != null:
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
    TResult Function(String customerId, String? customerName,
            String customerMemo, String tableNumber, String queueNumber)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail() when $default != null:
        return $default(_that.customerId, _that.customerName,
            _that.customerMemo, _that.tableNumber, _that.queueNumber);
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
    TResult Function(String customerId, String? customerName,
            String customerMemo, String tableNumber, String queueNumber)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail():
        return $default(_that.customerId, _that.customerName,
            _that.customerMemo, _that.tableNumber, _that.queueNumber);
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
    TResult? Function(String customerId, String? customerName,
            String customerMemo, String tableNumber, String queueNumber)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TransactionDetail() when $default != null:
        return $default(_that.customerId, _that.customerName,
            _that.customerMemo, _that.tableNumber, _that.queueNumber);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TransactionDetail extends TransactionDetail {
  const _TransactionDetail(
      {this.customerId = '',
      this.customerName,
      this.customerMemo = '',
      this.tableNumber = '',
      this.queueNumber = ''})
      : super._();

  /// The picked customer, or `''` for none. The source's `customerId: ''`.
  @override
  @JsonKey()
  final String customerId;

  /// The name behind [customerId], carried along so the cart's summary row can name the
  /// customer without a second lookup.
  ///
  /// Null and `''` are not the same answer, and the source says why: a row that stayed silent
  /// for an id it holds would read "no detail yet" for a sale that has a customer on it. The
  /// till never attaches an id without a name today (see [shownCustomerName]), so null is what
  /// this carries in practice; the distinction is kept because it is the source's, and because
  /// the held-basket path in C7 is what will produce the other one.
  @override
  final String? customerName;

  /// The free note that prints on the receipt, not the customer's own record.
  @override
  @JsonKey()
  final String customerMemo;

  /// Only shown when the outlet asks for it (`POSPreferences.showTableNumber`).
  @override
  @JsonKey()
  final String tableNumber;

  /// Only shown when the outlet asks for it (`POSPreferences.showQueueNumber`).
  @override
  @JsonKey()
  final String queueNumber;

  /// Create a copy of TransactionDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TransactionDetailCopyWith<_TransactionDetail> get copyWith =>
      __$TransactionDetailCopyWithImpl<_TransactionDetail>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TransactionDetail &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerMemo, customerMemo) ||
                other.customerMemo == customerMemo) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.queueNumber, queueNumber) ||
                other.queueNumber == queueNumber));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, customerId, customerName, customerMemo,
        tableNumber, queueNumber);
  }

  @override
  String toString() {
    return 'TransactionDetail(customerId: $customerId, customerName: $customerName, customerMemo: $customerMemo, tableNumber: $tableNumber, queueNumber: $queueNumber)';
  }
}

/// @nodoc
abstract mixin class _$TransactionDetailCopyWith<$Res>
    implements $TransactionDetailCopyWith<$Res> {
  factory _$TransactionDetailCopyWith(
          _TransactionDetail value, $Res Function(_TransactionDetail) _then) =
      __$TransactionDetailCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String customerId,
      String? customerName,
      String customerMemo,
      String tableNumber,
      String queueNumber});
}

/// @nodoc
class __$TransactionDetailCopyWithImpl<$Res>
    implements _$TransactionDetailCopyWith<$Res> {
  __$TransactionDetailCopyWithImpl(this._self, this._then);

  final _TransactionDetail _self;
  final $Res Function(_TransactionDetail) _then;

  /// Create a copy of TransactionDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? customerId = null,
    Object? customerName = freezed,
    Object? customerMemo = null,
    Object? tableNumber = null,
    Object? queueNumber = null,
  }) {
    return _then(_TransactionDetail(
      customerId: null == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: freezed == customerName
          ? _self.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: null == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String,
      tableNumber: null == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String,
      queueNumber: null == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
