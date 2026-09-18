// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_cart.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartLine {
  String get id;
  Product get product;
  num get qty;

  /// A line carries a percentage **or** a flat amount, never both. See [CartDiscount].
  num? get discountPercent;
  num? get discountAmount;

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CartLineCopyWith<CartLine> get copyWith =>
      _$CartLineCopyWithImpl<CartLine>(this as CartLine, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as CartLine;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CartLine &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.product, _this.product) ||
                other.product == _this.product) &&
            (identical(other.qty, _this.qty) || other.qty == _this.qty) &&
            (identical(other.discountPercent, _this.discountPercent) ||
                other.discountPercent == _this.discountPercent) &&
            (identical(other.discountAmount, _this.discountAmount) ||
                other.discountAmount == _this.discountAmount));
  }

  @override
  int get hashCode {
    final _this = this as CartLine;
    return Object.hash(runtimeType, _this.id, _this.product, _this.qty,
        _this.discountPercent, _this.discountAmount);
  }

  @override
  String toString() {
    final _this = this as CartLine;
    return 'CartLine(id: ${_this.id}, product: ${_this.product}, qty: ${_this.qty}, discountPercent: ${_this.discountPercent}, discountAmount: ${_this.discountAmount})';
  }
}

/// @nodoc
abstract mixin class $CartLineCopyWith<$Res> {
  factory $CartLineCopyWith(CartLine value, $Res Function(CartLine) _then) =
      _$CartLineCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      Product product,
      num qty,
      num? discountPercent,
      num? discountAmount});

  $ProductCopyWith<$Res> get product;
}

/// @nodoc
class _$CartLineCopyWithImpl<$Res> implements $CartLineCopyWith<$Res> {
  _$CartLineCopyWithImpl(this._self, this._then);

  final CartLine _self;
  final $Res Function(CartLine) _then;

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? product = null,
    Object? qty = null,
    Object? discountPercent = freezed,
    Object? discountAmount = freezed,
  }) {
    return _then(CartLine(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      product: null == product
          ? _self.product
          : product // ignore: cast_nullable_to_non_nullable
              as Product,
      qty: null == qty
          ? _self.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: freezed == discountPercent
          ? _self.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as num?,
      discountAmount: freezed == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num?,
    ));
  }

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductCopyWith<$Res> get product {
    return $ProductCopyWith<$Res>(_self.product, (value) {
      return _then(_self.copyWith(product: value));
    });
  }
}

/// Adds pattern-matching-related methods to [CartLine].
extension CartLinePatterns on CartLine {
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
    TResult Function(_CartLine value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CartLine() when $default != null:
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
    TResult Function(_CartLine value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CartLine():
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
    TResult? Function(_CartLine value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CartLine() when $default != null:
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
    TResult Function(String id, Product product, num qty, num? discountPercent,
            num? discountAmount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CartLine() when $default != null:
        return $default(_that.id, _that.product, _that.qty,
            _that.discountPercent, _that.discountAmount);
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
    TResult Function(String id, Product product, num qty, num? discountPercent,
            num? discountAmount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CartLine():
        return $default(_that.id, _that.product, _that.qty,
            _that.discountPercent, _that.discountAmount);
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
    TResult? Function(String id, Product product, num qty, num? discountPercent,
            num? discountAmount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CartLine() when $default != null:
        return $default(_that.id, _that.product, _that.qty,
            _that.discountPercent, _that.discountAmount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CartLine implements CartLine {
  const _CartLine(
      {required this.id,
      required this.product,
      required this.qty,
      this.discountPercent,
      this.discountAmount});

  @override
  final String id;
  @override
  final Product product;
  @override
  final num qty;

  /// A line carries a percentage **or** a flat amount, never both. See [CartDiscount].
  @override
  final num? discountPercent;
  @override
  final num? discountAmount;

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CartLineCopyWith<_CartLine> get copyWith =>
      __$CartLineCopyWithImpl<_CartLine>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CartLine &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.product, product) || other.product == product) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, id, product, qty, discountPercent, discountAmount);
  }

  @override
  String toString() {
    return 'CartLine(id: $id, product: $product, qty: $qty, discountPercent: $discountPercent, discountAmount: $discountAmount)';
  }
}

/// @nodoc
abstract mixin class _$CartLineCopyWith<$Res>
    implements $CartLineCopyWith<$Res> {
  factory _$CartLineCopyWith(_CartLine value, $Res Function(_CartLine) _then) =
      __$CartLineCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      Product product,
      num qty,
      num? discountPercent,
      num? discountAmount});

  @override
  $ProductCopyWith<$Res> get product;
}

/// @nodoc
class __$CartLineCopyWithImpl<$Res> implements _$CartLineCopyWith<$Res> {
  __$CartLineCopyWithImpl(this._self, this._then);

  final _CartLine _self;
  final $Res Function(_CartLine) _then;

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? product = null,
    Object? qty = null,
    Object? discountPercent = freezed,
    Object? discountAmount = freezed,
  }) {
    return _then(_CartLine(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      product: null == product
          ? _self.product
          : product // ignore: cast_nullable_to_non_nullable
              as Product,
      qty: null == qty
          ? _self.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: freezed == discountPercent
          ? _self.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as num?,
      discountAmount: freezed == discountAmount
          ? _self.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num?,
    ));
  }

  /// Create a copy of CartLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductCopyWith<$Res> get product {
    return $ProductCopyWith<$Res>(_self.product, (value) {
      return _then(_self.copyWith(product: value));
    });
  }
}

// dart format on
