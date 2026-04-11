// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as _i5;
import 'package:immutable_collections_api/immutable_collections_api.dart'
    as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class ItemSummary implements _i1.ParameterEncodable {
  const ItemSummary({required this.id, required this.name, this.categories});

  factory ItemSummary.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'id', r'name', r'categories'},
      listKeys: {r'categories'},
      context: r'ItemSummary',
    );
    return _i4.ItemSummary(
      id: _$values[r'id'].decodeSimpleInt(context: r'ItemSummary.id'),
      name: _$values[r'name'].decodeSimpleString(context: r'ItemSummary.name'),
      categories: _$values[r'categories']
          .decodeSimpleNullableStringList(context: r'ItemSummary.categories')
          ?.lock,
    );
  }

  factory ItemSummary.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ItemSummary');
    return ItemSummary(
      id: _$map[r'id'].decodeJsonInt(context: r'ItemSummary.id'),
      name: _$map[r'name'].decodeJsonString(context: r'ItemSummary.name'),
      categories: _$map[r'categories']
          .decodeJsonNullableList<_i3.String>(
            context: r'ItemSummary.categories',
          )
          ?.lock,
    );
  }

  factory ItemSummary.fromForm(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'id', r'name', r'categories'},
      listKeys: {r'categories'},
      context: r'ItemSummary',
    );
    return _i4.ItemSummary(
      id: _$values[r'id'].decodeFormInt(context: r'ItemSummary.id'),
      name: _$values[r'name'].decodeFormString(context: r'ItemSummary.name'),
      categories: _$values[r'categories']
          .decodeFormNullableStringList(context: r'ItemSummary.categories')
          ?.lock,
    );
  }

  final _i3.int id;

  final _i3.String name;

  final _i5.IList<_i3.String>? categories;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'name': name,
    if (categories != null) r'categories': categories?.unlock,
  };

  $$ItemSummaryCopyWith<ItemSummary> get copyWith => _ItemSummaryCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ItemSummary &&
        other.id == this.id &&
        other.name == this.name &&
        other.categories == this.categories;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([id, name, categories]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) {
    if (!allowLists && categories != null) {
      throw _i1.EncodingException(
        'Lists are not supported in this encoding style',
      );
    }
    final _$result = <_i3.String, _i3.String>{};
    _$result[r'id'] = id.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
    _$result[r'name'] = name.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
    if (categories != null) {
      _$result[r'categories'] = categories!.unlock.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'categories'] = '';
    }
    return _$result;
  }

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

abstract class $$ItemSummaryCopyWith<$Res> {
  factory $$ItemSummaryCopyWith(ItemSummary value) = _ItemSummaryCopyWith<$Res>;

  $Res call({_i3.int? id, _i3.String? name, _i5.IList<_i3.String>? categories});
  _i3.int get id;
  _i3.String get name;
  _i5.IList<_i3.String>? get categories;
}

class _ItemSummaryCopyWith<$Res> implements $$ItemSummaryCopyWith<$Res> {
  _ItemSummaryCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ItemSummary _value;

  @_i3.override
  _i3.int get id => _value.id;

  @_i3.override
  _i3.String get name => _value.name;

  @_i3.override
  _i5.IList<_i3.String>? get categories => _value.categories;

  @_i3.override
  $Res call({
    _i3.Object? id = _sentinel,
    _i3.Object? name = _sentinel,
    _i3.Object? categories = _sentinel,
  }) {
    return (ItemSummary(
          id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.int),
          name: _i3.identical(name, _sentinel)
              ? this.name
              : (name as _i3.String),
          categories: _i3.identical(categories, _sentinel)
              ? this.categories
              : (categories as _i5.IList<_i3.String>?),
        )
        as $Res);
  }
}
