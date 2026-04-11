// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:immutable_collections_api/immutable_collections_api.dart'
    as _i2;
import 'package:meta/meta.dart' as _i1;

sealed class GetItemResponse {
  const GetItemResponse();
}

@_i1.immutable
class GetItemResponse200 extends GetItemResponse {
  const GetItemResponse200({required this.body});

  final _i2.Item body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is GetItemResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class GetItemResponse404 extends GetItemResponse {
  const GetItemResponse404();

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is GetItemResponse404;
  }

  @_i3.override
  _i3.int get hashCode => runtimeType.hashCode;
}
