// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i2;

import 'package:dio/dio.dart' as _i1;
import 'package:immutable_collections_api/immutable_collections_api.dart'
    as _i4;
import 'package:tonik_util/tonik_util.dart' as _i3;

class GetItem {
  GetItem(this._dio);

  final _i1.Dio _dio;

  _i2.Future<_i3.TonikResult<_i4.GetItemResponse>> call({
    required _i2.int id,
  }) async {
    late final _i2.Uri _$uri;
    late final _i2.Object? _$data;
    late final _i1.Options _$options;
    try {
      final _$baseUri = _i2.Uri.parse(_dio.options.baseUrl);
      final _$pathResult = _path(id: id);
      final _$newPath = _$baseUri.path.endsWith('/')
          ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}'
          : '${_$baseUri.path}/${_$pathResult.join('/')}';
      _$uri = _$baseUri.replace(path: _$newPath);
      _$data = _data();
      _$options = _options();
    } on _i2.Object catch (exception, stackTrace) {
      return _i3.TonikError(
        exception,
        stackTrace: stackTrace,
        type: _i3.TonikErrorType.encoding,
        response: null,
      );
    }

    final _i1.Response<_i2.List<_i2.int>> _$response;
    try {
      _$response = await _dio.requestUri<_i2.List<_i2.int>>(
        _$uri,
        data: _$data,
        options: _$options,
      );
    } on _i2.Object catch (exception, stackTrace) {
      return _i3.TonikError(
        exception,
        stackTrace: stackTrace,
        type: _i3.TonikErrorType.network,
        response: null,
      );
    }

    final _i4.GetItemResponse _$parsedResponse;
    try {
      _$parsedResponse = _parseResponse(_$response);
    } on _i2.Object catch (exception, stackTrace) {
      return _i3.TonikError(
        exception,
        stackTrace: stackTrace,
        type: _i3.TonikErrorType.decoding,
        response: _$response,
      );
    }

    return _i3.TonikSuccess(_$parsedResponse, _$response);
  }

  _i2.List<_i2.String> _path({required _i2.int id}) {
    return [r'items', id.toSimple(explode: false, allowEmpty: false)];
  }

  _i2.Object? _data() {
    return null;
  }

  _i1.Options _options() {
    final _$headers = <_i2.String, _i2.dynamic>{};
    _$headers['Accept'] = r'application/json';
    return _i1.Options(
      method: 'GET',
      headers: _$headers,
      responseType: _i1.ResponseType.bytes,
      validateStatus: (_) => true,
    );
  }

  _i4.GetItemResponse _parseResponse(_i1.Response<_i2.List<_i2.int>> response) {
    switch ((response.statusCode, response.headers.value('content-type'))) {
      case (200, r'application/json'):
        final _$json = _i3.decodeResponseJson<_i2.Object?>(response.data);
        final _$body = _i4.Item.fromJson(_$json);
        return _i4.GetItemResponse200(body: _$body);
      case (404, _):
        return _i4.GetItemResponse404();
      default:
        final _$content =
            response.headers.value('content-type') ?? 'not specified';
        final _$status = response.statusCode;
        throw _i3.ResponseDecodingException(
          'Unexpected content type: ${_$content} for status code: ${_$status}',
        );
    }
  }
}
