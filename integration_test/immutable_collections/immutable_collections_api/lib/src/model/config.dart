// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class Config implements _i1.ParameterEncodable {
  const Config({required this.name, this.settings});

  factory Config.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for Config: contains complex types',
    );
  }

  factory Config.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'Config');
    return Config(
      name: _$map[r'name'].decodeJsonString(context: r'Config.name'),
      settings: _$map[r'settings']
          .decodeJsonNullableMap(
            (v) => v.decodeJsonString(context: r'Config.settings'),
            context: r'Config.settings',
          )
          ?.lock,
    );
  }

  factory Config.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for Config: contains complex types',
    );
  }

  final _i3.String name;

  final _i4.IMap<_i3.String, _i3.String>? settings;

  @_i3.override
  _i3.Object? toJson() => {
    r'name': name,
    if (settings != null) r'settings': settings?.unlock,
  };

  $$ConfigCopyWith<Config> get copyWith => _ConfigCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is Config &&
        other.name == this.name &&
        other.settings == this.settings;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([name, settings]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for Config: contains complex types',
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

abstract class $$ConfigCopyWith<$Res> {
  factory $$ConfigCopyWith(Config value) = _ConfigCopyWith<$Res>;

  $Res call({_i3.String? name, _i4.IMap<_i3.String, _i3.String>? settings});
  _i3.String get name;
  _i4.IMap<_i3.String, _i3.String>? get settings;
}

class _ConfigCopyWith<$Res> implements $$ConfigCopyWith<$Res> {
  _ConfigCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final Config _value;

  @_i3.override
  _i3.String get name => _value.name;

  @_i3.override
  _i4.IMap<_i3.String, _i3.String>? get settings => _value.settings;

  @_i3.override
  $Res call({_i3.Object? name = _sentinel, _i3.Object? settings = _sentinel}) {
    return (Config(
          name: _i3.identical(name, _sentinel)
              ? this.name
              : (name as _i3.String),
          settings: _i3.identical(settings, _sentinel)
              ? this.settings
              : (settings as _i4.IMap<_i3.String, _i3.String>?),
        )
        as $Res);
  }
}
