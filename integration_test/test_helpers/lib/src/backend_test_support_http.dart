import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_result.dart';

ServerConfig<http.Client> httpTestServerConfig({
  required Map<String, String> headers,
  required TestRequestRecorder? recorder,
  required TestResponseStub? response,
}) =>
    ServerConfig.clientFactory(
      () => _HeaderClient(headers, recorder: recorder, response: response),
    );

final class _HeaderClient extends http.BaseClient {
  _HeaderClient(
    this._headers, {
    required TestRequestRecorder? recorder,
    required TestResponseStub? response,
  })  : _recorder = recorder,
        _response = response,
        _inner = http.Client();

  final Map<String, String> _headers;
  final TestRequestRecorder? _recorder;
  final TestResponseStub? _response;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    for (final entry in _headers.entries) {
      request.headers.putIfAbsent(entry.key, () => entry.value);
    }
    final captured = await _captureRequest(request);
    final outbound = captured.outbound;
    _requestSnapshots[outbound] = captured.snapshot;
    _recorder?.record(captured.snapshot);

    final response = _response;
    if (response != null) {
      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        request: outbound,
        headers: {
          for (final entry in response.headers.entries)
            entry.key: entry.value.join(','),
        },
      );
    }
    return _inner.send(outbound);
  }

  @override
  void close() => _inner.close();
}

final Expando<TestRequestOptions> _requestSnapshots =
    Expando<TestRequestOptions>('integration request snapshot');

TestResponse httpTestResponse(http.Response response) => TestResponse(
      statusCode: response.statusCode,
      headers: TestHeaders(response.headersSplitValues),
      data: response.bodyBytes,
      requestOptions: response.request == null
          ? _requestOptions(null)
          : _requestSnapshots[response.request!] ??
              _requestOptions(response.request),
    );

TestRequestOptions _requestOptions(http.BaseRequest? request) {
  if (request == null) {
    return TestRequestOptions(
      uri: Uri(),
      path: '',
      method: '',
      headers: TestRequestHeaders({}),
      data: null,
      contentType: null,
      cancelToken: null,
      bodyBytes: null,
    );
  }

  return TestRequestOptions(
    uri: request.url,
    path: request.url.toString(),
    method: request.method,
    headers: TestRequestHeaders(request.headers),
    data: _requestData(request),
    contentType: request.headers['content-type'],
    cancelToken: _abortTrigger(request),
    bodyBytes: request is http.Request && _hasRequestBody(request)
        ? List.unmodifiable(request.bodyBytes)
        : null,
  );
}

Future<({http.BaseRequest outbound, TestRequestOptions snapshot})>
    _captureRequest(http.BaseRequest request) async {
  if (request is! http.MultipartRequest) {
    return (outbound: request, snapshot: _requestOptions(request));
  }

  final bodyBytes = await request.finalize().toBytes();
  final contentType = request.headers['content-type'];
  if (contentType == null) {
    throw StateError('Finalized multipart request has no content-type.');
  }
  final boundary = http.MediaType.parse(contentType).parameters['boundary'];
  if (boundary == null) {
    throw StateError('Multipart content-type has no boundary: $contentType');
  }

  final fields = request.fields.entries.toList();
  final files = <MapEntry<String, TestMultipartFile>>[];
  final parts = await Stream<List<int>>.value(
    bodyBytes,
  ).transform(MimeMultipartTransformer(boundary)).toList();
  for (var index = 0; index < parts.length; index++) {
    final part = parts[index];
    final bytes = await http.ByteStream(part).toBytes();
    final disposition = part.headers['content-disposition'];
    if (disposition == null) {
      throw StateError('Multipart part has no content-disposition.');
    }
    final parameters = http.MediaType.parse(
      'multipart/$disposition',
    ).parameters;
    final field = parameters['name'];
    if (field == null) {
      throw StateError('Multipart part has no field name: $disposition');
    }
    final partContentType = part.headers['content-type'];
    final originalFile =
        index < request.files.length ? request.files[index] : null;
    if (_isPlainField(originalFile)) {
      fields.add(MapEntry(field, _decodePartText(bytes, partContentType)));
      continue;
    }
    files.add(
      MapEntry(
        field,
        TestMultipartFile.fromBytes(
          bytes: bytes,
          filename: parameters['filename'],
          contentType: partContentType == null
              ? null
              : http.MediaType.parse(partContentType),
          headers: TestHeaders({
            for (final entry in part.headers.entries)
              if (entry.key.toLowerCase() != 'content-type' &&
                  entry.key.toLowerCase() != 'content-disposition')
                entry.key: [entry.value],
          }),
        ),
      ),
    );
  }

  final abortTrigger = _abortTrigger(request);
  final outbound = abortTrigger == null
      ? http.Request(request.method, request.url)
      : http.AbortableRequest(
          request.method,
          request.url,
          abortTrigger: abortTrigger,
        );
  outbound
    ..headers.addAll(request.headers)
    ..bodyBytes = bodyBytes
    ..followRedirects = request.followRedirects
    ..maxRedirects = request.maxRedirects
    ..persistentConnection = request.persistentConnection;
  return (
    outbound: outbound,
    snapshot: TestRequestOptions(
      uri: request.url,
      path: request.url.toString(),
      method: request.method,
      headers: TestRequestHeaders(request.headers),
      data: TestFormData(
        fields: List.unmodifiable(fields),
        files: List.unmodifiable(files),
      ),
      contentType: request.headers['content-type'],
      cancelToken: abortTrigger,
      bodyBytes: List.unmodifiable(bodyBytes),
    ),
  );
}

Future<void>? _abortTrigger(http.BaseRequest request) => switch (request) {
      http.Abortable(:final abortTrigger) => abortTrigger,
      _ => null,
    };

bool _hasRequestBody(http.Request request) =>
    request.bodyBytes.isNotEmpty ||
    request.headers.keys.any((key) => key.toLowerCase() == 'content-type');

bool _isPlainField(http.MultipartFile? file) {
  if (file == null) return false;
  try {
    return (file as dynamic).isPlainField as bool;
  } on NoSuchMethodError {
    return false;
  }
}

String _decodePartText(List<int> bytes, String? contentType) {
  final charset = contentType == null
      ? null
      : http.MediaType.parse(contentType).parameters['charset'];
  return (Encoding.getByName(charset) ?? utf8).decode(bytes);
}

Object? _requestData(http.BaseRequest request) {
  if (request is http.MultipartRequest) {
    return TestFormData(
      fields: List.unmodifiable(request.fields.entries),
      files: List.unmodifiable(
        request.files.map(
          (file) => MapEntry(
            file.field,
            TestMultipartFile(
              filename: file.filename,
              contentType: file.contentType,
              length: file.length,
              headers: TestHeaders(const {}),
              finalize: file.finalize,
            ),
          ),
        ),
      ),
    );
  }
  if (request is! http.Request) return null;

  final contentType = request.headers['content-type']?.toLowerCase() ?? '';
  if (!_hasRequestBody(request)) return null;
  if (contentType.startsWith('application/octet-stream')) {
    return request.bodyBytes;
  }

  final body = request.body;
  if (contentType.contains('json')) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }
  if (contentType.startsWith('application/x-www-form-urlencoded')) {
    return body;
  }
  if (!contentType.startsWith('text/') && body.isEmpty) {
    return request.bodyBytes;
  }
  return body;
}
