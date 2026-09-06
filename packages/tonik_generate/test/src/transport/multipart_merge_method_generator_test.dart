import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/transport/multipart_merge_method_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

void main() {
  test('emits only the operation-local multipart merge methods in use', () {
    final methods = generateMultipartMergeMethods(
      _multipartPlan({
        MultipartMergeHelper.lists,
        MultipartMergeHelper.propertyValues,
        MultipartMergeHelper.dynamicValues,
      }),
    ).toList();

    expect(methods.map((method) => method.name), [
      '_mergeMultipartLists',
      '_mergeMultipartPropertyValues',
      '_mergeMultipartPropertyValue',
      '_mergeMultipartValues',
      '_mergeMultipartMap',
    ]);
    expect(methods.every((method) => method.body != null), isTrue);
    final mergeMapReturn = methods
        .singleWhere((method) => method.name == '_mergeMultipartMap')
        .returns;
    expect(mergeMapReturn?.symbol, 'void');
    expect(mergeMapReturn?.url, isNull);

    final generatedClass = Class(
      (builder) => builder
        ..name = 'MultipartOperation'
        ..methods.addAll(methods),
    );
    final source = generatedClass.accept(DartEmitter()).toString();
    expect(
      () =>
          DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
              .format(source),
      returnsNormally,
    );
  });

  test('collects multipart merge methods across body variants', () {
    final body = BodySelectionPlan(
      value: refer('body'),
      variants: [
        _multipartPlan({MultipartMergeHelper.lists}),
        _multipartPlan({MultipartMergeHelper.dynamicValues}),
      ],
      isRequired: true,
    );

    expect(generateMultipartMergeMethods(body).map((method) => method.name), [
      '_mergeMultipartLists',
      '_mergeMultipartValues',
      '_mergeMultipartMap',
    ]);
  });

  test('emits nested object and iterable merge logic', () {
    final method = generateMultipartMergeMethods(
      _multipartPlan({MultipartMergeHelper.dynamicValues}),
    ).singleWhere((method) => method.name == '_mergeMultipartMap');
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    const expected = r'''
void _mergeMultipartMap(
  Map<String, dynamic> target,
  Map<dynamic, dynamic> incoming,
  String propertyName,
) {
  for (final entry in incoming.entries) {
    final key = entry.key;
    if (key is! String) {
      throw EncodingException(
        'Conflicting values for multipart property "$propertyName": object keys must be strings.',
      );
    }
    if (!target.containsKey(key) || target[key] == null) {
      target[key] = entry.value;
      continue;
    }
    if (entry.value == null) continue;
    final current = target[key];
    if (current is Map && entry.value is Map) {
      final nested = <String, dynamic>{};
      _mergeMultipartMap(nested, current, propertyName);
      _mergeMultipartMap(
        nested,
        (entry.value as Map<dynamic, dynamic>),
        propertyName,
      );
      target[key] = nested;
      continue;
    }
    if (current is Iterable && entry.value is Iterable) {
      target[key] = [...current, ...((entry.value as Iterable))];
      continue;
    }
    if (current != entry.value) {
      throw EncodingException(
        'Conflicting values for multipart property "$propertyName" at "$key".',
      );
    }
  }
}
''';

    expect(
      collapseWhitespace(formatter.format('${method.accept(DartEmitter())}')),
      collapseWhitespace(formatter.format(expected)),
    );
  });
}

MultipartBodyPlan _multipartPlan(Set<MultipartMergeHelper> mergeHelpers) =>
    MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      emissions: const [],
      isRequired: true,
      mergeHelpers: mergeHelpers,
    );
