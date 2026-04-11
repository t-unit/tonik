// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:immutable_collections_api/immutable_collections_api.dart'
    as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class ChildModel implements _i1.ParameterEncodable {
  const ChildModel({required this.childName, required this.value});

  factory ChildModel.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'childName', r'value'},
      listKeys: {},
      context: r'ChildModel',
    );
    return _i4.ChildModel(
      childName: _$values[r'childName'].decodeSimpleString(
        context: r'ChildModel.childName',
      ),
      value: _$values[r'value'].decodeSimpleInt(context: r'ChildModel.value'),
    );
  }

  factory ChildModel.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ChildModel');
    return ChildModel(
      childName: _$map[r'childName'].decodeJsonString(
        context: r'ChildModel.childName',
      ),
      value: _$map[r'value'].decodeJsonInt(context: r'ChildModel.value'),
    );
  }

  factory ChildModel.fromForm(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'childName', r'value'},
      listKeys: {},
      context: r'ChildModel',
    );
    return _i4.ChildModel(
      childName: _$values[r'childName'].decodeFormString(
        context: r'ChildModel.childName',
      ),
      value: _$values[r'value'].decodeFormInt(context: r'ChildModel.value'),
    );
  }

  final _i3.String childName;

  final _i3.int value;

  @_i3.override
  _i3.Object? toJson() => {r'childName': childName, r'value': value};

  $$ChildModelCopyWith<ChildModel> get copyWith => _ChildModelCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ChildModel &&
        other.childName == this.childName &&
        other.value == this.value;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([childName, value]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) {
    final _$result = <_i3.String, _i3.String>{};
    _$result[r'childName'] = childName.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
    _$result[r'value'] = value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
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

abstract class $$ChildModelCopyWith<$Res> {
  factory $$ChildModelCopyWith(ChildModel value) = _ChildModelCopyWith<$Res>;

  $Res call({_i3.String? childName, _i3.int? value});
  _i3.String get childName;
  _i3.int get value;
}

class _ChildModelCopyWith<$Res> implements $$ChildModelCopyWith<$Res> {
  _ChildModelCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ChildModel _value;

  @_i3.override
  _i3.String get childName => _value.childName;

  @_i3.override
  _i3.int get value => _value.value;

  @_i3.override
  $Res call({
    _i3.Object? childName = _sentinel,
    _i3.Object? value = _sentinel,
  }) {
    return (ChildModel(
          childName: _i3.identical(childName, _sentinel)
              ? this.childName
              : (childName as _i3.String),
          value: _i3.identical(value, _sentinel)
              ? this.value
              : (value as _i3.int),
        )
        as $Res);
  }
}
