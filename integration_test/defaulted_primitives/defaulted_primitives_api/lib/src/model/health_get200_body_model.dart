// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class HealthGet200BodyModel
    implements _i1.ParameterEncodable, _i1.UriEncodable {
  const HealthGet200BodyModel({this.status});

  factory HealthGet200BodyModel.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'status'},
      listKeys: {},
      context: r'HealthGet200BodyModel',
    );
    return HealthGet200BodyModel(
      status: _$values[r'status'].decodeSimpleNullableString(
        context: r'HealthGet200BodyModel.status',
      ),
    );
  }

  factory HealthGet200BodyModel.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'HealthGet200BodyModel');
    return HealthGet200BodyModel(
      status: _$map[r'status'].decodeJsonNullableString(
        context: r'HealthGet200BodyModel.status',
      ),
    );
  }

  factory HealthGet200BodyModel.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'status'},
      listKeys: {},
      context: r'HealthGet200BodyModel',
    );
    return HealthGet200BodyModel(
      status: _$values[r'status'].decodeFormNullableString(
        context: r'HealthGet200BodyModel.status',
      ),
    );
  }

  final _i3.String? status;

  @_i3.override
  _i3.Object? toJson() => {if (status != null) r'status': status};

  $$HealthGet200BodyModelCopyWith<HealthGet200BodyModel> get copyWith =>
      _HealthGet200BodyModelCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is HealthGet200BodyModel && other.status == this.status;
  }

  @_i3.override
  _i3.int get hashCode => status.hashCode;

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) {
    final _$result = <_i3.String, _i3.String>{};
    if (status != null) {
      _$result[r'status'] = status!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'status'] = '';
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

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    _i3.bool useQueryComponent = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode HealthGet200BodyModel: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$HealthGet200BodyModelCopyWith<$Res> {
  factory $$HealthGet200BodyModelCopyWith(HealthGet200BodyModel value) =
      _HealthGet200BodyModelCopyWith<$Res>;

  $Res call({_i3.String? status});
  _i3.String? get status;
}

class _HealthGet200BodyModelCopyWith<$Res>
    implements $$HealthGet200BodyModelCopyWith<$Res> {
  _HealthGet200BodyModelCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final HealthGet200BodyModel _value;

  @_i3.override
  _i3.String? get status => _value.status;

  @_i3.override
  $Res call({_i3.Object? status = _sentinel}) {
    return (HealthGet200BodyModel(
          status: _i3.identical(status, _sentinel)
              ? this.status
              : (status as _i3.String?),
        )
        as $Res);
  }
}
