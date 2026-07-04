import 'dart:convert';

import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('PriorityEnum.fromJson integer coercion', () {
    test('resolves whole-number double to matching member', () {
      expect(PriorityEnum.fromJson(2.0), PriorityEnum.two);
    });

    test('resolves exponent-form JSON number to matching member', () {
      expect(PriorityEnum.fromJson(jsonDecode('1e0')), PriorityEnum.one);
    });

    test('resolves plain int to matching member', () {
      expect(PriorityEnum.fromJson(2), PriorityEnum.two);
    });

    test('resolves whole-number double inside decoded JSON object', () {
      final payload = jsonDecode('{"priority": 2.0}') as Map<String, Object?>;
      expect(PriorityEnum.fromJson(payload['priority']), PriorityEnum.two);
    });

    test('rejects non-whole double', () {
      expect(
        () => PriorityEnum.fromJson(2.5),
        throwsA(isA<DecodingException>()),
      );
    });

    test('rejects unmatched whole value', () {
      expect(
        () => PriorityEnum.fromJson(7.0),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });
}
