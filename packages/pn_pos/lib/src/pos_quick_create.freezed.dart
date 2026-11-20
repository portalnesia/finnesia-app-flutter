// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_quick_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuickUnitChoice {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuickUnitChoice);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuickUnitChoice()';
  }
}

/// @nodoc
class $QuickUnitChoiceCopyWith<$Res> {
  $QuickUnitChoiceCopyWith(
      QuickUnitChoice _, $Res Function(QuickUnitChoice) __);
}

/// Adds pattern-matching-related methods to [QuickUnitChoice].
extension QuickUnitChoicePatterns on QuickUnitChoice {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuickUnitExisting value)? existing,
    TResult Function(QuickUnitPcsNew value)? pcsNew,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting() when existing != null:
        return existing(_that);
      case QuickUnitPcsNew() when pcsNew != null:
        return pcsNew(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(QuickUnitExisting value) existing,
    required TResult Function(QuickUnitPcsNew value) pcsNew,
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting():
        return existing(_that);
      case QuickUnitPcsNew():
        return pcsNew(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuickUnitExisting value)? existing,
    TResult? Function(QuickUnitPcsNew value)? pcsNew,
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting() when existing != null:
        return existing(_that);
      case QuickUnitPcsNew() when pcsNew != null:
        return pcsNew(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Unit unit)? existing,
    TResult Function()? pcsNew,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting() when existing != null:
        return existing(_that.unit);
      case QuickUnitPcsNew() when pcsNew != null:
        return pcsNew();
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
  TResult when<TResult extends Object?>({
    required TResult Function(Unit unit) existing,
    required TResult Function() pcsNew,
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting():
        return existing(_that.unit);
      case QuickUnitPcsNew():
        return pcsNew();
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Unit unit)? existing,
    TResult? Function()? pcsNew,
  }) {
    final _that = this;
    switch (_that) {
      case QuickUnitExisting() when existing != null:
        return existing(_that.unit);
      case QuickUnitPcsNew() when pcsNew != null:
        return pcsNew();
      case _:
        return null;
    }
  }
}

/// @nodoc

class QuickUnitExisting implements QuickUnitChoice {
  const QuickUnitExisting(this.unit);

  final Unit unit;

  /// Create a copy of QuickUnitChoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuickUnitExistingCopyWith<QuickUnitExisting> get copyWith =>
      _$QuickUnitExistingCopyWithImpl<QuickUnitExisting>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuickUnitExisting &&
            (identical(other.unit, unit) || other.unit == unit));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, unit);
  }

  @override
  String toString() {
    return 'QuickUnitChoice.existing(unit: $unit)';
  }
}

/// @nodoc
abstract mixin class $QuickUnitExistingCopyWith<$Res>
    implements $QuickUnitChoiceCopyWith<$Res> {
  factory $QuickUnitExistingCopyWith(
          QuickUnitExisting value, $Res Function(QuickUnitExisting) _then) =
      _$QuickUnitExistingCopyWithImpl;
  @useResult
  $Res call({Unit unit});

  $UnitCopyWith<$Res> get unit;
}

/// @nodoc
class _$QuickUnitExistingCopyWithImpl<$Res>
    implements $QuickUnitExistingCopyWith<$Res> {
  _$QuickUnitExistingCopyWithImpl(this._self, this._then);

  final QuickUnitExisting _self;
  final $Res Function(QuickUnitExisting) _then;

  /// Create a copy of QuickUnitChoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? unit = null,
  }) {
    return _then(QuickUnitExisting(
      null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as Unit,
    ));
  }

  /// Create a copy of QuickUnitChoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnitCopyWith<$Res> get unit {
    return $UnitCopyWith<$Res>(_self.unit, (value) {
      return _then(_self.copyWith(unit: value));
    });
  }
}

/// @nodoc

class QuickUnitPcsNew implements QuickUnitChoice {
  const QuickUnitPcsNew();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuickUnitPcsNew);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuickUnitChoice.pcsNew()';
  }
}

// dart format on
