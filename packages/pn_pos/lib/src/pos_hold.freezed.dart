// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_hold.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HeldOrder {
  String get id;
  String get label;
  String get outletId;
  String? get customerId;
  String? get customerMemo;
  String? get tableNumber;
  String? get queueNumber;
  num get headerDiscount;
  List<CartLine> get lines;

  /// ISO-8601, and the sort key. A `String` rather than a `DateTime` because that is what
  /// the source stores and what `localeCompare` orders on — see [listHeldOrders] for why
  /// the comparison is done as text.
  String get heldAt;

  /// Create a copy of HeldOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeldOrderCopyWith<HeldOrder> get copyWith =>
      _$HeldOrderCopyWithImpl<HeldOrder>(this as HeldOrder, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as HeldOrder;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeldOrder &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.label, _this.label) ||
                other.label == _this.label) &&
            (identical(other.outletId, _this.outletId) ||
                other.outletId == _this.outletId) &&
            (identical(other.customerId, _this.customerId) ||
                other.customerId == _this.customerId) &&
            (identical(other.customerMemo, _this.customerMemo) ||
                other.customerMemo == _this.customerMemo) &&
            (identical(other.tableNumber, _this.tableNumber) ||
                other.tableNumber == _this.tableNumber) &&
            (identical(other.queueNumber, _this.queueNumber) ||
                other.queueNumber == _this.queueNumber) &&
            (identical(other.headerDiscount, _this.headerDiscount) ||
                other.headerDiscount == _this.headerDiscount) &&
            const DeepCollectionEquality().equals(other.lines, _this.lines) &&
            (identical(other.heldAt, _this.heldAt) ||
                other.heldAt == _this.heldAt));
  }

  @override
  int get hashCode {
    final _this = this as HeldOrder;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.label,
        _this.outletId,
        _this.customerId,
        _this.customerMemo,
        _this.tableNumber,
        _this.queueNumber,
        _this.headerDiscount,
        const DeepCollectionEquality().hash(_this.lines),
        _this.heldAt);
  }

  @override
  String toString() {
    final _this = this as HeldOrder;
    return 'HeldOrder(id: ${_this.id}, label: ${_this.label}, outletId: ${_this.outletId}, customerId: ${_this.customerId}, customerMemo: ${_this.customerMemo}, tableNumber: ${_this.tableNumber}, queueNumber: ${_this.queueNumber}, headerDiscount: ${_this.headerDiscount}, lines: ${_this.lines}, heldAt: ${_this.heldAt})';
  }
}

/// @nodoc
abstract mixin class $HeldOrderCopyWith<$Res> {
  factory $HeldOrderCopyWith(HeldOrder value, $Res Function(HeldOrder) _then) =
      _$HeldOrderCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String label,
      String outletId,
      String? customerId,
      String? customerMemo,
      String? tableNumber,
      String? queueNumber,
      num headerDiscount,
      List<CartLine> lines,
      String heldAt});
}

/// @nodoc
class _$HeldOrderCopyWithImpl<$Res> implements $HeldOrderCopyWith<$Res> {
  _$HeldOrderCopyWithImpl(this._self, this._then);

  final HeldOrder _self;
  final $Res Function(HeldOrder) _then;

  /// Create a copy of HeldOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? outletId = null,
    Object? customerId = freezed,
    Object? customerMemo = freezed,
    Object? tableNumber = freezed,
    Object? queueNumber = freezed,
    Object? headerDiscount = null,
    Object? lines = null,
    Object? heldAt = null,
  }) {
    return _then(HeldOrder(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: freezed == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String?,
      tableNumber: freezed == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: freezed == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      headerDiscount: null == headerDiscount
          ? _self.headerDiscount
          : headerDiscount // ignore: cast_nullable_to_non_nullable
              as num,
      lines: null == lines
          ? _self.lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<CartLine>,
      heldAt: null == heldAt
          ? _self.heldAt
          : heldAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [HeldOrder].
extension HeldOrderPatterns on HeldOrder {
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
    TResult Function(_HeldOrder value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeldOrder() when $default != null:
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
    TResult Function(_HeldOrder value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrder():
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
    TResult? Function(_HeldOrder value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrder() when $default != null:
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
            String id,
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines,
            String heldAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeldOrder() when $default != null:
        return $default(
            _that.id,
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines,
            _that.heldAt);
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
            String id,
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines,
            String heldAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrder():
        return $default(
            _that.id,
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines,
            _that.heldAt);
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
            String id,
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines,
            String heldAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrder() when $default != null:
        return $default(
            _that.id,
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines,
            _that.heldAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HeldOrder implements HeldOrder {
  const _HeldOrder(
      {required this.id,
      required this.label,
      required this.outletId,
      this.customerId,
      this.customerMemo,
      this.tableNumber,
      this.queueNumber,
      required this.headerDiscount,
      required List<CartLine> lines,
      required this.heldAt})
      : _lines = lines;

  @override
  final String id;
  @override
  final String label;
  @override
  final String outletId;
  @override
  final String? customerId;
  @override
  final String? customerMemo;
  @override
  final String? tableNumber;
  @override
  final String? queueNumber;
  @override
  final num headerDiscount;
  final List<CartLine> _lines;
  @override
  List<CartLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  /// ISO-8601, and the sort key. A `String` rather than a `DateTime` because that is what
  /// the source stores and what `localeCompare` orders on — see [listHeldOrders] for why
  /// the comparison is done as text.
  @override
  final String heldAt;

  /// Create a copy of HeldOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeldOrderCopyWith<_HeldOrder> get copyWith =>
      __$HeldOrderCopyWithImpl<_HeldOrder>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeldOrder &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.outletId, outletId) ||
                other.outletId == outletId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerMemo, customerMemo) ||
                other.customerMemo == customerMemo) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.queueNumber, queueNumber) ||
                other.queueNumber == queueNumber) &&
            (identical(other.headerDiscount, headerDiscount) ||
                other.headerDiscount == headerDiscount) &&
            const DeepCollectionEquality().equals(other.lines, _lines) &&
            (identical(other.heldAt, heldAt) || other.heldAt == heldAt));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        label,
        outletId,
        customerId,
        customerMemo,
        tableNumber,
        queueNumber,
        headerDiscount,
        const DeepCollectionEquality().hash(_lines),
        heldAt);
  }

  @override
  String toString() {
    return 'HeldOrder(id: $id, label: $label, outletId: $outletId, customerId: $customerId, customerMemo: $customerMemo, tableNumber: $tableNumber, queueNumber: $queueNumber, headerDiscount: $headerDiscount, lines: $lines, heldAt: $heldAt)';
  }
}

/// @nodoc
abstract mixin class _$HeldOrderCopyWith<$Res>
    implements $HeldOrderCopyWith<$Res> {
  factory _$HeldOrderCopyWith(
          _HeldOrder value, $Res Function(_HeldOrder) _then) =
      __$HeldOrderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      String outletId,
      String? customerId,
      String? customerMemo,
      String? tableNumber,
      String? queueNumber,
      num headerDiscount,
      List<CartLine> lines,
      String heldAt});
}

/// @nodoc
class __$HeldOrderCopyWithImpl<$Res> implements _$HeldOrderCopyWith<$Res> {
  __$HeldOrderCopyWithImpl(this._self, this._then);

  final _HeldOrder _self;
  final $Res Function(_HeldOrder) _then;

  /// Create a copy of HeldOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? outletId = null,
    Object? customerId = freezed,
    Object? customerMemo = freezed,
    Object? tableNumber = freezed,
    Object? queueNumber = freezed,
    Object? headerDiscount = null,
    Object? lines = null,
    Object? heldAt = null,
  }) {
    return _then(_HeldOrder(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: freezed == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String?,
      tableNumber: freezed == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: freezed == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      headerDiscount: null == headerDiscount
          ? _self.headerDiscount
          : headerDiscount // ignore: cast_nullable_to_non_nullable
              as num,
      lines: null == lines
          ? _self._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<CartLine>,
      heldAt: null == heldAt
          ? _self.heldAt
          : heldAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$HeldOrderDraft {
  String get label;
  String get outletId;
  String? get customerId;
  String? get customerMemo;
  String? get tableNumber;
  String? get queueNumber;
  num get headerDiscount;
  List<CartLine> get lines;

  /// Create a copy of HeldOrderDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeldOrderDraftCopyWith<HeldOrderDraft> get copyWith =>
      _$HeldOrderDraftCopyWithImpl<HeldOrderDraft>(
          this as HeldOrderDraft, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as HeldOrderDraft;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeldOrderDraft &&
            (identical(other.label, _this.label) ||
                other.label == _this.label) &&
            (identical(other.outletId, _this.outletId) ||
                other.outletId == _this.outletId) &&
            (identical(other.customerId, _this.customerId) ||
                other.customerId == _this.customerId) &&
            (identical(other.customerMemo, _this.customerMemo) ||
                other.customerMemo == _this.customerMemo) &&
            (identical(other.tableNumber, _this.tableNumber) ||
                other.tableNumber == _this.tableNumber) &&
            (identical(other.queueNumber, _this.queueNumber) ||
                other.queueNumber == _this.queueNumber) &&
            (identical(other.headerDiscount, _this.headerDiscount) ||
                other.headerDiscount == _this.headerDiscount) &&
            const DeepCollectionEquality().equals(other.lines, _this.lines));
  }

  @override
  int get hashCode {
    final _this = this as HeldOrderDraft;
    return Object.hash(
        runtimeType,
        _this.label,
        _this.outletId,
        _this.customerId,
        _this.customerMemo,
        _this.tableNumber,
        _this.queueNumber,
        _this.headerDiscount,
        const DeepCollectionEquality().hash(_this.lines));
  }

  @override
  String toString() {
    final _this = this as HeldOrderDraft;
    return 'HeldOrderDraft(label: ${_this.label}, outletId: ${_this.outletId}, customerId: ${_this.customerId}, customerMemo: ${_this.customerMemo}, tableNumber: ${_this.tableNumber}, queueNumber: ${_this.queueNumber}, headerDiscount: ${_this.headerDiscount}, lines: ${_this.lines})';
  }
}

/// @nodoc
abstract mixin class $HeldOrderDraftCopyWith<$Res> {
  factory $HeldOrderDraftCopyWith(
          HeldOrderDraft value, $Res Function(HeldOrderDraft) _then) =
      _$HeldOrderDraftCopyWithImpl;
  @useResult
  $Res call(
      {String label,
      String outletId,
      String? customerId,
      String? customerMemo,
      String? tableNumber,
      String? queueNumber,
      num headerDiscount,
      List<CartLine> lines});
}

/// @nodoc
class _$HeldOrderDraftCopyWithImpl<$Res>
    implements $HeldOrderDraftCopyWith<$Res> {
  _$HeldOrderDraftCopyWithImpl(this._self, this._then);

  final HeldOrderDraft _self;
  final $Res Function(HeldOrderDraft) _then;

  /// Create a copy of HeldOrderDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? outletId = null,
    Object? customerId = freezed,
    Object? customerMemo = freezed,
    Object? tableNumber = freezed,
    Object? queueNumber = freezed,
    Object? headerDiscount = null,
    Object? lines = null,
  }) {
    return _then(HeldOrderDraft(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: freezed == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String?,
      tableNumber: freezed == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: freezed == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      headerDiscount: null == headerDiscount
          ? _self.headerDiscount
          : headerDiscount // ignore: cast_nullable_to_non_nullable
              as num,
      lines: null == lines
          ? _self.lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<CartLine>,
    ));
  }
}

/// Adds pattern-matching-related methods to [HeldOrderDraft].
extension HeldOrderDraftPatterns on HeldOrderDraft {
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
    TResult Function(_HeldOrderDraft value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft() when $default != null:
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
    TResult Function(_HeldOrderDraft value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft():
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
    TResult? Function(_HeldOrderDraft value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft() when $default != null:
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
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft() when $default != null:
        return $default(
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines);
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
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft():
        return $default(
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines);
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
            String label,
            String outletId,
            String? customerId,
            String? customerMemo,
            String? tableNumber,
            String? queueNumber,
            num headerDiscount,
            List<CartLine> lines)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeldOrderDraft() when $default != null:
        return $default(
            _that.label,
            _that.outletId,
            _that.customerId,
            _that.customerMemo,
            _that.tableNumber,
            _that.queueNumber,
            _that.headerDiscount,
            _that.lines);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HeldOrderDraft implements HeldOrderDraft {
  const _HeldOrderDraft(
      {required this.label,
      required this.outletId,
      this.customerId,
      this.customerMemo,
      this.tableNumber,
      this.queueNumber,
      required this.headerDiscount,
      required List<CartLine> lines})
      : _lines = lines;

  @override
  final String label;
  @override
  final String outletId;
  @override
  final String? customerId;
  @override
  final String? customerMemo;
  @override
  final String? tableNumber;
  @override
  final String? queueNumber;
  @override
  final num headerDiscount;
  final List<CartLine> _lines;
  @override
  List<CartLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  /// Create a copy of HeldOrderDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeldOrderDraftCopyWith<_HeldOrderDraft> get copyWith =>
      __$HeldOrderDraftCopyWithImpl<_HeldOrderDraft>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeldOrderDraft &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.outletId, outletId) ||
                other.outletId == outletId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerMemo, customerMemo) ||
                other.customerMemo == customerMemo) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.queueNumber, queueNumber) ||
                other.queueNumber == queueNumber) &&
            (identical(other.headerDiscount, headerDiscount) ||
                other.headerDiscount == headerDiscount) &&
            const DeepCollectionEquality().equals(other.lines, _lines));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        label,
        outletId,
        customerId,
        customerMemo,
        tableNumber,
        queueNumber,
        headerDiscount,
        const DeepCollectionEquality().hash(_lines));
  }

  @override
  String toString() {
    return 'HeldOrderDraft(label: $label, outletId: $outletId, customerId: $customerId, customerMemo: $customerMemo, tableNumber: $tableNumber, queueNumber: $queueNumber, headerDiscount: $headerDiscount, lines: $lines)';
  }
}

/// @nodoc
abstract mixin class _$HeldOrderDraftCopyWith<$Res>
    implements $HeldOrderDraftCopyWith<$Res> {
  factory _$HeldOrderDraftCopyWith(
          _HeldOrderDraft value, $Res Function(_HeldOrderDraft) _then) =
      __$HeldOrderDraftCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String label,
      String outletId,
      String? customerId,
      String? customerMemo,
      String? tableNumber,
      String? queueNumber,
      num headerDiscount,
      List<CartLine> lines});
}

/// @nodoc
class __$HeldOrderDraftCopyWithImpl<$Res>
    implements _$HeldOrderDraftCopyWith<$Res> {
  __$HeldOrderDraftCopyWithImpl(this._self, this._then);

  final _HeldOrderDraft _self;
  final $Res Function(_HeldOrderDraft) _then;

  /// Create a copy of HeldOrderDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
    Object? outletId = null,
    Object? customerId = freezed,
    Object? customerMemo = freezed,
    Object? tableNumber = freezed,
    Object? queueNumber = freezed,
    Object? headerDiscount = null,
    Object? lines = null,
  }) {
    return _then(_HeldOrderDraft(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outletId: null == outletId
          ? _self.outletId
          : outletId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _self.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerMemo: freezed == customerMemo
          ? _self.customerMemo
          : customerMemo // ignore: cast_nullable_to_non_nullable
              as String?,
      tableNumber: freezed == tableNumber
          ? _self.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: freezed == queueNumber
          ? _self.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      headerDiscount: null == headerDiscount
          ? _self.headerDiscount
          : headerDiscount // ignore: cast_nullable_to_non_nullable
              as num,
      lines: null == lines
          ? _self._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<CartLine>,
    ));
  }
}

// dart format on
