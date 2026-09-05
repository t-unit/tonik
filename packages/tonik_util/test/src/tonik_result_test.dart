import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('TonikResult', () {
    test('success preserves the native response identity', () {
      final response = _NativeResponse();
      final result = TonikSuccess<String, _NativeResponse>('value', response);

      expect(result.value, 'value');
      expect(result.response, same(response));
      expect(result, isA<TonikResult<String, _NativeResponse>>());
    });

    test('error preserves the native response and error context', () {
      final response = _NativeResponse();
      final error = StateError('failed');
      final stackTrace = StackTrace.current;
      final result = TonikError<String, _NativeResponse>(
        error,
        stackTrace: stackTrace,
        type: TonikErrorType.network,
        response: response,
      );

      expect(result.error, same(error));
      expect(result.stackTrace, same(stackTrace));
      expect(result.type, TonikErrorType.network);
      expect(result.response, same(response));
      expect(result, isA<TonikResult<String, _NativeResponse>>());
    });

    test('error permits response-less failures without a placeholder', () {
      final result = TonikError<String, _NativeResponse>(
        StateError('failed before dispatch'),
        stackTrace: StackTrace.current,
        type: TonikErrorType.encoding,
        response: null,
      );

      expect(result.response, isNull);
    });
  });
}

final class _NativeResponse();
