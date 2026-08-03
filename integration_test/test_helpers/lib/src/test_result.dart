import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

/// Backend-neutral view of a successful Tonik result.
final class TestSuccess<T> {
  const TestSuccess(this.value, this.response);

  final T value;
  final TestResponse response;
}

/// Backend-neutral view of a failed Tonik result.
final class TestError {
  const TestError({
    required this.error,
    required this.stackTrace,
    required this.type,
    required this.response,
  });

  final Object error;
  final StackTrace stackTrace;
  final TonikErrorType type;
  final TestResponse? response;
}

/// Backend-neutral response details retained for integration assertions.
final class TestResponse {
  const TestResponse({
    required this.statusCode,
    required this.headers,
    required Object? data,
    required this.requestOptions,
  }) : _data = data;

  final int? statusCode;
  final TestHeaders headers;
  final Object? _data;

  dynamic get data => _data;
  final TestRequestOptions requestOptions;
}

/// Backend-neutral outgoing request details retained for integration assertions.
final class TestRequestOptions {
  const TestRequestOptions({
    required this.uri,
    required this.path,
    required this.method,
    required this.headers,
    required Object? data,
    required this.contentType,
    required this.cancelToken,
    required this.bodyBytes,
  }) : _data = data;

  final Uri uri;
  final String path;
  final String method;
  final TestRequestHeaders headers;
  final Object? _data;

  dynamic get data => _data;
  final String? contentType;
  final Object? cancelToken;
  final List<int>? bodyBytes;

  String? get bodyText => bodyBytes == null ? null : utf8.decode(bodyBytes!);
}

/// Records the last request at the backend client boundary.
final class TestRequestRecorder {
  TestRequestOptions? request;

  void record(TestRequestOptions value) => request = value;
}

/// Backend-neutral response returned by a recording test client.
final class TestResponseStub {
  const TestResponseStub({
    this.statusCode = 204,
    this.headers = const {},
    this.bodyBytes = const [],
  });

  final int statusCode;
  final Map<String, List<String>> headers;
  final List<int> bodyBytes;
}

/// Case-insensitive request headers with scalar values, matching Dio's view.
final class TestRequestHeaders extends MapBase<String, Object?> {
  TestRequestHeaders(Map<String, Object?> values) : _values = Map.of(values);

  final Map<String, Object?> _values;

  String? _keyFor(Object? key) {
    if (key is! String) return null;
    final normalized = key.toLowerCase();
    for (final candidate in _values.keys) {
      if (candidate.toLowerCase() == normalized) return candidate;
    }
    return null;
  }

  @override
  Object? operator [](Object? key) {
    final actual = _keyFor(key);
    return actual == null ? null : _values[actual];
  }

  @override
  void operator []=(String key, Object? value) => _values[key] = value;

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  @override
  Object? remove(Object? key) {
    final actual = _keyFor(key);
    return actual == null ? null : _values.remove(actual);
  }
}

/// Case-insensitive response headers retaining each field value.
final class TestHeaders {
  TestHeaders(Map<String, Object?> values)
      : map = Map.unmodifiable({
          for (final entry in values.entries)
            entry.key: List<String>.unmodifiable(
              switch (entry.value) {
                Iterable<Object?> values => values.map((value) => '$value'),
                final value? => ['$value'],
                null => const <String>[],
              },
            ),
        });

  final Map<String, List<String>> map;

  List<String>? operator [](String name) {
    final normalized = name.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return null;
  }

  String? value(String name) => this[name]?.join(',');
}

/// Backend-neutral multipart body matching the subset asserted by the suite.
final class TestFormData {
  const TestFormData({required this.fields, required this.files});

  final List<MapEntry<String, String>> fields;
  final List<MapEntry<String, TestMultipartFile>> files;
}

/// Backend-neutral multipart part matching the subset asserted by the suite.
final class TestMultipartFile {
  const TestMultipartFile({
    required this.filename,
    required this.contentType,
    required this.length,
    required this.headers,
    required Stream<List<int>> Function() finalize,
  }) : _finalize = finalize;

  final String? filename;
  final Object? contentType;
  final int length;
  final TestHeaders headers;
  final Stream<List<int>> Function() _finalize;

  TestMultipartFile clone() => this;

  Stream<List<int>> finalize() => _finalize();

  static TestMultipartFile fromBytes({
    required List<int> bytes,
    String? filename,
    Object? contentType,
    TestHeaders? headers,
  }) {
    final immutableBytes = Uint8List.fromList(bytes);
    return TestMultipartFile(
      filename: filename,
      contentType: contentType,
      length: immutableBytes.length,
      headers: headers ?? TestHeaders(const {}),
      finalize: () => Stream.value(immutableBytes),
    );
  }
}

/// Matches a Tonik success without naming its native response type.
final Matcher isTonikSuccess = predicate<Object?>(
  (value) => switch (value) {
    TonikSuccess() => true,
    _ => false,
  },
  'is a TonikSuccess',
);

/// Matches a Tonik error without naming its native response type.
final Matcher isTonikError = predicate<Object?>(
  (value) => switch (value) {
    TonikError() => true,
    _ => false,
  },
  'is a TonikError',
);
