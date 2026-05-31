// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

@_i2.immutable
class DefaultedPrimitives implements _i1.ParameterEncodable, _i1.UriEncodable {
  const DefaultedPrimitives({
    this.name = nameDefault,
    this.count = countDefault,
    this.rate = rateDefault,
    this.active = activeDefault,
    this.nickname,
    this.title = titleDefault,
  });

  factory DefaultedPrimitives.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {
        r'name',
        r'count',
        r'rate',
        r'active',
        r'nickname',
        r'title',
      },
      listKeys: {},
      context: r'DefaultedPrimitives',
    );
    return DefaultedPrimitives(
      name: _$values.containsKey(r'name')
          ? _$values[r'name'].decodeSimpleString(
              context: r'DefaultedPrimitives.name',
            )
          : nameDefault,
      count: _$values.containsKey(r'count')
          ? _$values[r'count'].decodeSimpleInt(
              context: r'DefaultedPrimitives.count',
            )
          : countDefault,
      rate: _$values.containsKey(r'rate')
          ? _$values[r'rate'].decodeSimpleDouble(
              context: r'DefaultedPrimitives.rate',
            )
          : rateDefault,
      active: _$values.containsKey(r'active')
          ? _$values[r'active'].decodeSimpleBool(
              context: r'DefaultedPrimitives.active',
            )
          : activeDefault,
      nickname: _$values[r'nickname'].decodeSimpleNullableString(
        context: r'DefaultedPrimitives.nickname',
      ),
      title: _$values.containsKey(r'title')
          ? _$values[r'title'].decodeSimpleNullableString(
              context: r'DefaultedPrimitives.title',
            )
          : titleDefault,
    );
  }

  factory DefaultedPrimitives.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'DefaultedPrimitives');
    return DefaultedPrimitives(
      name: _$map.containsKey(r'name')
          ? _$map[r'name'].decodeJsonString(
              context: r'DefaultedPrimitives.name',
            )
          : nameDefault,
      count: _$map.containsKey(r'count')
          ? _$map[r'count'].decodeJsonInt(context: r'DefaultedPrimitives.count')
          : countDefault,
      rate: _$map.containsKey(r'rate')
          ? _$map[r'rate'].decodeJsonDouble(
              context: r'DefaultedPrimitives.rate',
            )
          : rateDefault,
      active: _$map.containsKey(r'active')
          ? _$map[r'active'].decodeJsonBool(
              context: r'DefaultedPrimitives.active',
            )
          : activeDefault,
      nickname: _$map[r'nickname'].decodeJsonNullableString(
        context: r'DefaultedPrimitives.nickname',
      ),
      title: _$map.containsKey(r'title')
          ? _$map[r'title'].decodeJsonNullableString(
              context: r'DefaultedPrimitives.title',
            )
          : titleDefault,
    );
  }

  factory DefaultedPrimitives.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {
        r'name',
        r'count',
        r'rate',
        r'active',
        r'nickname',
        r'title',
      },
      listKeys: {},
      context: r'DefaultedPrimitives',
    );
    return DefaultedPrimitives(
      name: _$values.containsKey(r'name')
          ? _$values[r'name'].decodeFormString(
              context: r'DefaultedPrimitives.name',
            )
          : nameDefault,
      count: _$values.containsKey(r'count')
          ? _$values[r'count'].decodeFormInt(
              context: r'DefaultedPrimitives.count',
            )
          : countDefault,
      rate: _$values.containsKey(r'rate')
          ? _$values[r'rate'].decodeFormDouble(
              context: r'DefaultedPrimitives.rate',
            )
          : rateDefault,
      active: _$values.containsKey(r'active')
          ? _$values[r'active'].decodeFormBool(
              context: r'DefaultedPrimitives.active',
            )
          : activeDefault,
      nickname: _$values[r'nickname'].decodeFormNullableString(
        context: r'DefaultedPrimitives.nickname',
      ),
      title: _$values.containsKey(r'title')
          ? _$values[r'title'].decodeFormNullableString(
              context: r'DefaultedPrimitives.title',
            )
          : titleDefault,
    );
  }

  static const _i3.String nameDefault = r'anon';

  static const _i3.int countDefault = 0;

  static const _i3.double rateDefault = 1.5;

  static const _i3.bool activeDefault = true;

  static const _i3.String? titleDefault = r'Mx.';

  final _i3.String name;

  final _i3.int? count;

  final _i3.double? rate;

  final _i3.bool? active;

  final _i3.String? nickname;

  final _i3.String? title;

  @_i3.override
  _i3.Object? toJson() => {
    r'name': name,
    if (count != null) r'count': count,
    if (rate != null) r'rate': rate,
    if (active != null) r'active': active,
    r'nickname': nickname,
    r'title': title,
  };

  $$DefaultedPrimitivesCopyWith<DefaultedPrimitives> get copyWith =>
      _DefaultedPrimitivesCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is DefaultedPrimitives &&
        other.name == this.name &&
        other.count == this.count &&
        other.rate == this.rate &&
        other.active == this.active &&
        other.nickname == this.nickname &&
        other.title == this.title;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([name, count, rate, active, nickname, title]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  _i3.Map<_i3.String, _i3.String> parameterProperties({
    _i3.bool allowEmpty = true,
    _i3.bool allowLists = true,
    _i3.bool useQueryComponent = false,
  }) {
    final _$result = <_i3.String, _i3.String>{};
    _$result[r'name'] = name.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
    if (count != null) {
      _$result[r'count'] = count!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'count'] = '';
    }
    if (rate != null) {
      _$result[r'rate'] = rate!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'rate'] = '';
    }
    if (active != null) {
      _$result[r'active'] = active!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'active'] = '';
    }
    if (nickname != null) {
      _$result[r'nickname'] = nickname!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'nickname'] = '';
    }
    if (title != null) {
      _$result[r'title'] = title!.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );
    } else if (allowEmpty) {
      _$result[r'title'] = '';
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
      r'Cannot uriEncode DefaultedPrimitives: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$DefaultedPrimitivesCopyWith<$Res> {
  factory $$DefaultedPrimitivesCopyWith(DefaultedPrimitives value) =
      _DefaultedPrimitivesCopyWith<$Res>;

  $Res call({
    _i3.String? name,
    _i3.int? count,
    _i3.double? rate,
    _i3.bool? active,
    _i3.String? nickname,
    _i3.String? title,
  });
  _i3.String get name;
  _i3.int? get count;
  _i3.double? get rate;
  _i3.bool? get active;
  _i3.String? get nickname;
  _i3.String? get title;
}

class _DefaultedPrimitivesCopyWith<$Res>
    implements $$DefaultedPrimitivesCopyWith<$Res> {
  _DefaultedPrimitivesCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final DefaultedPrimitives _value;

  @_i3.override
  _i3.String get name => _value.name;

  @_i3.override
  _i3.int? get count => _value.count;

  @_i3.override
  _i3.double? get rate => _value.rate;

  @_i3.override
  _i3.bool? get active => _value.active;

  @_i3.override
  _i3.String? get nickname => _value.nickname;

  @_i3.override
  _i3.String? get title => _value.title;

  @_i3.override
  $Res call({
    _i3.Object? name = _sentinel,
    _i3.Object? count = _sentinel,
    _i3.Object? rate = _sentinel,
    _i3.Object? active = _sentinel,
    _i3.Object? nickname = _sentinel,
    _i3.Object? title = _sentinel,
  }) {
    return (DefaultedPrimitives(
          name: _i3.identical(name, _sentinel)
              ? this.name
              : (name as _i3.String),
          count: _i3.identical(count, _sentinel)
              ? this.count
              : (count as _i3.int?),
          rate: _i3.identical(rate, _sentinel)
              ? this.rate
              : (rate as _i3.double?),
          active: _i3.identical(active, _sentinel)
              ? this.active
              : (active as _i3.bool?),
          nickname: _i3.identical(nickname, _sentinel)
              ? this.nickname
              : (nickname as _i3.String?),
          title: _i3.identical(title, _sentinel)
              ? this.title
              : (title as _i3.String?),
        )
        as $Res);
  }
}
