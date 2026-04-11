// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class MixedItem implements _i1.ParameterEncodable {
  const MixedItem({
    required this.requiredTags,
    this.optionalTags,
    this.requiredMeta,
    this.optionalMeta,
  });

  factory MixedItem.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for MixedItem: contains complex types',
    );
  }

  factory MixedItem.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'MixedItem');
    return MixedItem(
      requiredTags: _$map[r'requiredTags']
          .decodeJsonList<_i3.String>(context: r'MixedItem.requiredTags')
          .lock,
      optionalTags: _$map[r'optionalTags']
          .decodeJsonNullableList<_i3.String>(
            context: r'MixedItem.optionalTags',
          )
          ?.lock,
      requiredMeta: _$map[r'requiredMeta']
          .decodeJsonNullableMap(
            (v) => v.decodeJsonInt(context: r'MixedItem.requiredMeta'),
            context: r'MixedItem.requiredMeta',
          )
          ?.lock,
      optionalMeta: _$map[r'optionalMeta']
          .decodeJsonNullableMap(
            (v) => v.decodeJsonInt(context: r'MixedItem.optionalMeta'),
            context: r'MixedItem.optionalMeta',
          )
          ?.lock,
    );
  }

  factory MixedItem.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for MixedItem: contains complex types',
    );
  }

  final _i4.IList<_i3.String> requiredTags;

  final _i4.IList<_i3.String>? optionalTags;

  final _i4.IMap<_i3.String, _i3.int>? requiredMeta;

  final _i4.IMap<_i3.String, _i3.int>? optionalMeta;

  @_i3.override
  _i3.Object? toJson() => {
    r'requiredTags': requiredTags.unlock,
    if (optionalTags != null) r'optionalTags': optionalTags?.unlock,
    if (requiredMeta != null) r'requiredMeta': requiredMeta?.unlock,
    if (optionalMeta != null) r'optionalMeta': optionalMeta?.unlock,
  };

  $$MixedItemCopyWith<MixedItem> get copyWith => _MixedItemCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is MixedItem &&
        other.requiredTags == this.requiredTags &&
        other.optionalTags == this.optionalTags &&
        other.requiredMeta == this.requiredMeta &&
        other.optionalMeta == this.optionalMeta;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([
      requiredTags,
      optionalTags,
      requiredMeta,
      optionalMeta,
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for MixedItem: contains complex types',
  );

  @_i3.override
  _i3.String toSimple({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return parameterProperties(
      allowEmpty: allowEmpty,
    ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
  }

  @_i3.override
  _i3.String toForm({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
    _i3.bool useQueryComponent = false,
  }) {
    return parameterProperties(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    ).toForm(
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
      useQueryComponent: useQueryComponent,
    );
  }

  @_i3.override
  _i3.String toLabel({
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return parameterProperties(
      allowEmpty: allowEmpty,
    ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
  }

  @_i3.override
  _i3.String toMatrix(
    _i3.String paramName, {
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toMatrix(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
    );
  }

  @_i3.override
  _i3.List<_i1.ParameterEntry> toDeepObject(
    _i3.String paramName, {
    required _i3.bool explode,
    required _i3.bool allowEmpty,
  }) {
    return parameterProperties(
      allowEmpty: allowEmpty,
      allowLists: false,
    ).toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
    );
  }
}

abstract class $$MixedItemCopyWith<$Res> {
  factory $$MixedItemCopyWith(MixedItem value) = _MixedItemCopyWith<$Res>;

  $Res call({
    _i4.IList<_i3.String>? requiredTags,
    _i4.IList<_i3.String>? optionalTags,
    _i4.IMap<_i3.String, _i3.int>? requiredMeta,
    _i4.IMap<_i3.String, _i3.int>? optionalMeta,
  });
  _i4.IList<_i3.String> get requiredTags;
  _i4.IList<_i3.String>? get optionalTags;
  _i4.IMap<_i3.String, _i3.int>? get requiredMeta;
  _i4.IMap<_i3.String, _i3.int>? get optionalMeta;
}

class _MixedItemCopyWith<$Res> implements $$MixedItemCopyWith<$Res> {
  _MixedItemCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final MixedItem _value;

  @_i3.override
  _i4.IList<_i3.String> get requiredTags => _value.requiredTags;

  @_i3.override
  _i4.IList<_i3.String>? get optionalTags => _value.optionalTags;

  @_i3.override
  _i4.IMap<_i3.String, _i3.int>? get requiredMeta => _value.requiredMeta;

  @_i3.override
  _i4.IMap<_i3.String, _i3.int>? get optionalMeta => _value.optionalMeta;

  @_i3.override
  $Res call({
    _i3.Object? requiredTags = _sentinel,
    _i3.Object? optionalTags = _sentinel,
    _i3.Object? requiredMeta = _sentinel,
    _i3.Object? optionalMeta = _sentinel,
  }) {
    return (MixedItem(
          requiredTags: _i3.identical(requiredTags, _sentinel)
              ? this.requiredTags
              : (requiredTags as _i4.IList<_i3.String>),
          optionalTags: _i3.identical(optionalTags, _sentinel)
              ? this.optionalTags
              : (optionalTags as _i4.IList<_i3.String>?),
          requiredMeta: _i3.identical(requiredMeta, _sentinel)
              ? this.requiredMeta
              : (requiredMeta as _i4.IMap<_i3.String, _i3.int>?),
          optionalMeta: _i3.identical(optionalMeta, _sentinel)
              ? this.optionalMeta
              : (optionalMeta as _i4.IMap<_i3.String, _i3.int>?),
        )
        as $Res);
  }
}
