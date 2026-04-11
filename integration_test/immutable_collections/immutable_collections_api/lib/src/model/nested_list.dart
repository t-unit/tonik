// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class NestedList implements _i1.ParameterEncodable {
  const NestedList({required this.matrix});

  factory NestedList.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for NestedList: contains complex types',
    );
  }

  factory NestedList.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'NestedList');
    return NestedList(
      matrix: _$map[r'matrix']
          .decodeJsonList<_i3.Object?>(context: r'NestedList.matrix')
          .map(
            (e) => e
                .decodeJsonList<_i3.String>(context: r'NestedList.matrix')
                .lock,
          )
          .toList()
          .lock,
    );
  }

  factory NestedList.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for NestedList: contains complex types',
    );
  }

  final _i4.IList<_i4.IList<_i3.String>> matrix;

  @_i3.override
  _i3.Object? toJson() => {
    r'matrix': matrix.unlock.map((e) => e.unlock).toList(),
  };

  $$NestedListCopyWith<NestedList> get copyWith => _NestedListCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is NestedList && other.matrix == this.matrix;
  }

  @_i3.override
  _i3.int get hashCode => matrix.hashCode;

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for NestedList: contains complex types',
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

abstract class $$NestedListCopyWith<$Res> {
  factory $$NestedListCopyWith(NestedList value) = _NestedListCopyWith<$Res>;

  $Res call({_i4.IList<_i4.IList<_i3.String>>? matrix});
  _i4.IList<_i4.IList<_i3.String>> get matrix;
}

class _NestedListCopyWith<$Res> implements $$NestedListCopyWith<$Res> {
  _NestedListCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final NestedList _value;

  @_i3.override
  _i4.IList<_i4.IList<_i3.String>> get matrix => _value.matrix;

  @_i3.override
  $Res call({_i3.Object? matrix = _sentinel}) {
    return (NestedList(
          matrix: _i3.identical(matrix, _sentinel)
              ? this.matrix
              : (matrix as _i4.IList<_i4.IList<_i3.String>>),
        )
        as $Res);
  }
}
