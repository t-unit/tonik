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
class Item implements _i1.ParameterEncodable {
  const Item({
    required this.id,
    required this.name,
    required this.tags,
    required this.children,
    required this.metadata,
  });

  factory Item.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for Item: contains complex types',
    );
  }

  factory Item.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'Item');
    return Item(
      id: _$map[r'id'].decodeJsonInt(context: r'Item.id'),
      name: _$map[r'name'].decodeJsonString(context: r'Item.name'),
      tags: _$map[r'tags']
          .decodeJsonList<_i3.String>(context: r'Item.tags')
          .lock,
      children: _$map[r'children']
          .decodeJsonList<_i3.Object?>(context: r'Item.children')
          .map(_i4.ChildModel.fromJson)
          .toList()
          .lock,
      metadata: _$map[r'metadata']
          .decodeJsonMap(
            (v) => v.decodeJsonString(context: r'Item.metadata'),
            context: r'Item.metadata',
          )
          .lock,
    );
  }

  factory Item.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for Item: contains complex types',
    );
  }

  final _i3.int id;

  final _i3.String name;

  final _i5.IList<_i3.String> tags;

  final _i5.IList<_i4.ChildModel> children;

  final _i5.IMap<_i3.String, _i3.String> metadata;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'name': name,
    r'tags': tags.unlock,
    r'children': children.unlock.map((e) => e.toJson()).toList(),
    r'metadata': metadata.unlock,
  };

  $$ItemCopyWith<Item> get copyWith => _ItemCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is Item &&
        other.id == this.id &&
        other.name == this.name &&
        other.tags == this.tags &&
        other.children == this.children &&
        other.metadata == this.metadata;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([id, name, tags, children, metadata]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for Item: contains complex types',
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

abstract class $$ItemCopyWith<$Res> {
  factory $$ItemCopyWith(Item value) = _ItemCopyWith<$Res>;

  $Res call({
    _i3.int? id,
    _i3.String? name,
    _i5.IList<_i3.String>? tags,
    _i5.IList<_i4.ChildModel>? children,
    _i5.IMap<_i3.String, _i3.String>? metadata,
  });
  _i3.int get id;
  _i3.String get name;
  _i5.IList<_i3.String> get tags;
  _i5.IList<_i4.ChildModel> get children;
  _i5.IMap<_i3.String, _i3.String> get metadata;
}

class _ItemCopyWith<$Res> implements $$ItemCopyWith<$Res> {
  _ItemCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final Item _value;

  @_i3.override
  _i3.int get id => _value.id;

  @_i3.override
  _i3.String get name => _value.name;

  @_i3.override
  _i5.IList<_i3.String> get tags => _value.tags;

  @_i3.override
  _i5.IList<_i4.ChildModel> get children => _value.children;

  @_i3.override
  _i5.IMap<_i3.String, _i3.String> get metadata => _value.metadata;

  @_i3.override
  $Res call({
    _i3.Object? id = _sentinel,
    _i3.Object? name = _sentinel,
    _i3.Object? tags = _sentinel,
    _i3.Object? children = _sentinel,
    _i3.Object? metadata = _sentinel,
  }) {
    return (Item(
          id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.int),
          name: _i3.identical(name, _sentinel)
              ? this.name
              : (name as _i3.String),
          tags: _i3.identical(tags, _sentinel)
              ? this.tags
              : (tags as _i5.IList<_i3.String>),
          children: _i3.identical(children, _sentinel)
              ? this.children
              : (children as _i5.IList<_i4.ChildModel>),
          metadata: _i3.identical(metadata, _sentinel)
              ? this.metadata
              : (metadata as _i5.IMap<_i3.String, _i3.String>),
        )
        as $Res);
  }
}
