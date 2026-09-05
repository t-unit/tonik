import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

/// Backend-neutral view of a successful Tonik result.
final class const TestSuccess<T>(final T value, final TestResponse response);

/// Backend-neutral view of a failed Tonik result.
final class const TestError({
  required final Object error,
  required final StackTrace stackTrace,
  required final TonikErrorType type,
  required final TestResponse? response,
});

/// Backend-neutral response details retained for integration assertions.
final class const TestResponse({
  required final int? statusCode,
  required final TestHeaders headers,
  required final Object? _data,
}) {
  dynamic get data => _data;
}

/// Case-insensitive response headers retaining each field value.
final class const TestHeaders._(final Map<String, List<String>> map) {
  new(Map<String, Object?> values)
    : this._(
        Map.unmodifiable({
          for (final entry in values.entries)
            entry.key: List<String>.unmodifiable(switch (entry.value) {
              Iterable<Object?> values => values.map((value) => '$value'),
              final value? => ['$value'],
              null => const <String>[],
            }),
        }),
      );

  List<String>? operator [](String name) {
    final normalized = name.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return null;
  }

  String? value(String name) => this[name]?.join(',');
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
