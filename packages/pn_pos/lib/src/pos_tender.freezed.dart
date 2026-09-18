// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_tender.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TenderDraft {
  String get id;
  POSTenderMethod get method;
  num get amount;
  String? get reference;

  /// Create a copy of TenderDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TenderDraftCopyWith<TenderDraft> get copyWith =>
      _$TenderDraftCopyWithImpl<TenderDraft>(this as TenderDraft, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as TenderDraft;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TenderDraft &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.method, _this.method) ||
                other.method == _this.method) &&
            (identical(other.amount, _this.amount) ||
                other.amount == _this.amount) &&
            (identical(other.reference, _this.reference) ||
                other.reference == _this.reference));
  }

  @override
  int get hashCode {
    final _this = this as TenderDraft;
    return Object.hash(
        runtimeType, _this.id, _this.method, _this.amount, _this.reference);
  }

  @override
  String toString() {
    final _this = this as TenderDraft;
    return 'TenderDraft(id: ${_this.id}, method: ${_this.method}, amount: ${_this.amount}, reference: ${_this.reference})';
  }
}

/// @nodoc
abstract mixin class $TenderDraftCopyWith<$Res> {
  factory $TenderDraftCopyWith(
          TenderDraft value, $Res Function(TenderDraft) _then) =
      _$TenderDraftCopyWithImpl;
  @useResult
  $Res call({String id, POSTenderMethod method, num amount, String? reference});
}

/// @nodoc
class _$TenderDraftCopyWithImpl<$Res> implements $TenderDraftCopyWith<$Res> {
  _$TenderDraftCopyWithImpl(this._self, this._then);

  final TenderDraft _self;
  final $Res Function(TenderDraft) _then;

  /// Create a copy of TenderDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? method = null,
    Object? amount = null,
    Object? reference = freezed,
  }) {
    return _then(TenderDraft(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as POSTenderMethod,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      reference: freezed == reference
          ? _self.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TenderDraft].
extension TenderDraftPatterns on TenderDraft {
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
    TResult Function(_TenderDraft value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TenderDraft() when $default != null:
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
    TResult Function(_TenderDraft value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderDraft():
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
    TResult? Function(_TenderDraft value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderDraft() when $default != null:
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
            String id, POSTenderMethod method, num amount, String? reference)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TenderDraft() when $default != null:
        return $default(_that.id, _that.method, _that.amount, _that.reference);
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
            String id, POSTenderMethod method, num amount, String? reference)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderDraft():
        return $default(_that.id, _that.method, _that.amount, _that.reference);
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
            String id, POSTenderMethod method, num amount, String? reference)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderDraft() when $default != null:
        return $default(_that.id, _that.method, _that.amount, _that.reference);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TenderDraft implements TenderDraft {
  const _TenderDraft(
      {required this.id,
      required this.method,
      required this.amount,
      this.reference});

  @override
  final String id;
  @override
  final POSTenderMethod method;
  @override
  final num amount;
  @override
  final String? reference;

  /// Create a copy of TenderDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TenderDraftCopyWith<_TenderDraft> get copyWith =>
      __$TenderDraftCopyWithImpl<_TenderDraft>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenderDraft &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.reference, reference) ||
                other.reference == reference));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, method, amount, reference);
  }

  @override
  String toString() {
    return 'TenderDraft(id: $id, method: $method, amount: $amount, reference: $reference)';
  }
}

/// @nodoc
abstract mixin class _$TenderDraftCopyWith<$Res>
    implements $TenderDraftCopyWith<$Res> {
  factory _$TenderDraftCopyWith(
          _TenderDraft value, $Res Function(_TenderDraft) _then) =
      __$TenderDraftCopyWithImpl;
  @override
  @useResult
  $Res call({String id, POSTenderMethod method, num amount, String? reference});
}

/// @nodoc
class __$TenderDraftCopyWithImpl<$Res> implements _$TenderDraftCopyWith<$Res> {
  __$TenderDraftCopyWithImpl(this._self, this._then);

  final _TenderDraft _self;
  final $Res Function(_TenderDraft) _then;

  /// Create a copy of TenderDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? method = null,
    Object? amount = null,
    Object? reference = freezed,
  }) {
    return _then(_TenderDraft(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as POSTenderMethod,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      reference: freezed == reference
          ? _self.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$TenderSummary {
  num get paid;
  num get remaining;
  num get change;

  /// Create a copy of TenderSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TenderSummaryCopyWith<TenderSummary> get copyWith =>
      _$TenderSummaryCopyWithImpl<TenderSummary>(
          this as TenderSummary, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as TenderSummary;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TenderSummary &&
            (identical(other.paid, _this.paid) || other.paid == _this.paid) &&
            (identical(other.remaining, _this.remaining) ||
                other.remaining == _this.remaining) &&
            (identical(other.change, _this.change) ||
                other.change == _this.change));
  }

  @override
  int get hashCode {
    final _this = this as TenderSummary;
    return Object.hash(runtimeType, _this.paid, _this.remaining, _this.change);
  }

  @override
  String toString() {
    final _this = this as TenderSummary;
    return 'TenderSummary(paid: ${_this.paid}, remaining: ${_this.remaining}, change: ${_this.change})';
  }
}

/// @nodoc
abstract mixin class $TenderSummaryCopyWith<$Res> {
  factory $TenderSummaryCopyWith(
          TenderSummary value, $Res Function(TenderSummary) _then) =
      _$TenderSummaryCopyWithImpl;
  @useResult
  $Res call({num paid, num remaining, num change});
}

/// @nodoc
class _$TenderSummaryCopyWithImpl<$Res>
    implements $TenderSummaryCopyWith<$Res> {
  _$TenderSummaryCopyWithImpl(this._self, this._then);

  final TenderSummary _self;
  final $Res Function(TenderSummary) _then;

  /// Create a copy of TenderSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paid = null,
    Object? remaining = null,
    Object? change = null,
  }) {
    return _then(TenderSummary(
      paid: null == paid
          ? _self.paid
          : paid // ignore: cast_nullable_to_non_nullable
              as num,
      remaining: null == remaining
          ? _self.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as num,
      change: null == change
          ? _self.change
          : change // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// Adds pattern-matching-related methods to [TenderSummary].
extension TenderSummaryPatterns on TenderSummary {
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
    TResult Function(_TenderSummary value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TenderSummary() when $default != null:
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
    TResult Function(_TenderSummary value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderSummary():
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
    TResult? Function(_TenderSummary value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderSummary() when $default != null:
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
    TResult Function(num paid, num remaining, num change)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TenderSummary() when $default != null:
        return $default(_that.paid, _that.remaining, _that.change);
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
    TResult Function(num paid, num remaining, num change) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderSummary():
        return $default(_that.paid, _that.remaining, _that.change);
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
    TResult? Function(num paid, num remaining, num change)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TenderSummary() when $default != null:
        return $default(_that.paid, _that.remaining, _that.change);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TenderSummary implements TenderSummary {
  const _TenderSummary(
      {required this.paid, required this.remaining, required this.change});

  @override
  final num paid;
  @override
  final num remaining;
  @override
  final num change;

  /// Create a copy of TenderSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TenderSummaryCopyWith<_TenderSummary> get copyWith =>
      __$TenderSummaryCopyWithImpl<_TenderSummary>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenderSummary &&
            (identical(other.paid, paid) || other.paid == paid) &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.change, change) || other.change == change));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, paid, remaining, change);
  }

  @override
  String toString() {
    return 'TenderSummary(paid: $paid, remaining: $remaining, change: $change)';
  }
}

/// @nodoc
abstract mixin class _$TenderSummaryCopyWith<$Res>
    implements $TenderSummaryCopyWith<$Res> {
  factory _$TenderSummaryCopyWith(
          _TenderSummary value, $Res Function(_TenderSummary) _then) =
      __$TenderSummaryCopyWithImpl;
  @override
  @useResult
  $Res call({num paid, num remaining, num change});
}

/// @nodoc
class __$TenderSummaryCopyWithImpl<$Res>
    implements _$TenderSummaryCopyWith<$Res> {
  __$TenderSummaryCopyWithImpl(this._self, this._then);

  final _TenderSummary _self;
  final $Res Function(_TenderSummary) _then;

  /// Create a copy of TenderSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? paid = null,
    Object? remaining = null,
    Object? change = null,
  }) {
    return _then(_TenderSummary(
      paid: null == paid
          ? _self.paid
          : paid // ignore: cast_nullable_to_non_nullable
              as num,
      remaining: null == remaining
          ? _self.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as num,
      change: null == change
          ? _self.change
          : change // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
mixin _$TenderBuildResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TenderBuildResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TenderBuildResult()';
  }
}

/// @nodoc
class $TenderBuildResultCopyWith<$Res> {
  $TenderBuildResultCopyWith(
      TenderBuildResult _, $Res Function(TenderBuildResult) __);
}

/// Adds pattern-matching-related methods to [TenderBuildResult].
extension TenderBuildResultPatterns on TenderBuildResult {
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
    TResult Function(TenderBuildOk value)? ok,
    TResult Function(TenderBuildFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk() when ok != null:
        return ok(_that);
      case TenderBuildFailed() when failed != null:
        return failed(_that);
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
    required TResult Function(TenderBuildOk value) ok,
    required TResult Function(TenderBuildFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk():
        return ok(_that);
      case TenderBuildFailed():
        return failed(_that);
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
    TResult? Function(TenderBuildOk value)? ok,
    TResult? Function(TenderBuildFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk() when ok != null:
        return ok(_that);
      case TenderBuildFailed() when failed != null:
        return failed(_that);
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
    TResult Function(List<POSTenderDTO> tenders)? ok,
    TResult Function(TenderProblem problem)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk() when ok != null:
        return ok(_that.tenders);
      case TenderBuildFailed() when failed != null:
        return failed(_that.problem);
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
    required TResult Function(List<POSTenderDTO> tenders) ok,
    required TResult Function(TenderProblem problem) failed,
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk():
        return ok(_that.tenders);
      case TenderBuildFailed():
        return failed(_that.problem);
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
    TResult? Function(List<POSTenderDTO> tenders)? ok,
    TResult? Function(TenderProblem problem)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case TenderBuildOk() when ok != null:
        return ok(_that.tenders);
      case TenderBuildFailed() when failed != null:
        return failed(_that.problem);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TenderBuildOk implements TenderBuildResult {
  const TenderBuildOk(List<POSTenderDTO> tenders) : _tenders = tenders;

  final List<POSTenderDTO> _tenders;
  List<POSTenderDTO> get tenders {
    if (_tenders is EqualUnmodifiableListView) return _tenders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tenders);
  }

  /// Create a copy of TenderBuildResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TenderBuildOkCopyWith<TenderBuildOk> get copyWith =>
      _$TenderBuildOkCopyWithImpl<TenderBuildOk>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TenderBuildOk &&
            const DeepCollectionEquality().equals(other.tenders, _tenders));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_tenders));
  }

  @override
  String toString() {
    return 'TenderBuildResult.ok(tenders: $tenders)';
  }
}

/// @nodoc
abstract mixin class $TenderBuildOkCopyWith<$Res>
    implements $TenderBuildResultCopyWith<$Res> {
  factory $TenderBuildOkCopyWith(
          TenderBuildOk value, $Res Function(TenderBuildOk) _then) =
      _$TenderBuildOkCopyWithImpl;
  @useResult
  $Res call({List<POSTenderDTO> tenders});
}

/// @nodoc
class _$TenderBuildOkCopyWithImpl<$Res>
    implements $TenderBuildOkCopyWith<$Res> {
  _$TenderBuildOkCopyWithImpl(this._self, this._then);

  final TenderBuildOk _self;
  final $Res Function(TenderBuildOk) _then;

  /// Create a copy of TenderBuildResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tenders = null,
  }) {
    return _then(TenderBuildOk(
      null == tenders
          ? _self._tenders
          : tenders // ignore: cast_nullable_to_non_nullable
              as List<POSTenderDTO>,
    ));
  }
}

/// @nodoc

class TenderBuildFailed implements TenderBuildResult {
  const TenderBuildFailed(this.problem);

  final TenderProblem problem;

  /// Create a copy of TenderBuildResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TenderBuildFailedCopyWith<TenderBuildFailed> get copyWith =>
      _$TenderBuildFailedCopyWithImpl<TenderBuildFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TenderBuildFailed &&
            (identical(other.problem, problem) || other.problem == problem));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, problem);
  }

  @override
  String toString() {
    return 'TenderBuildResult.failed(problem: $problem)';
  }
}

/// @nodoc
abstract mixin class $TenderBuildFailedCopyWith<$Res>
    implements $TenderBuildResultCopyWith<$Res> {
  factory $TenderBuildFailedCopyWith(
          TenderBuildFailed value, $Res Function(TenderBuildFailed) _then) =
      _$TenderBuildFailedCopyWithImpl;
  @useResult
  $Res call({TenderProblem problem});
}

/// @nodoc
class _$TenderBuildFailedCopyWithImpl<$Res>
    implements $TenderBuildFailedCopyWith<$Res> {
  _$TenderBuildFailedCopyWithImpl(this._self, this._then);

  final TenderBuildFailed _self;
  final $Res Function(TenderBuildFailed) _then;

  /// Create a copy of TenderBuildResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? problem = null,
  }) {
    return _then(TenderBuildFailed(
      null == problem
          ? _self.problem
          : problem // ignore: cast_nullable_to_non_nullable
              as TenderProblem,
    ));
  }
}

// dart format on
