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
}

MultipartBodyPlan _multipartPlan(Set<MultipartMergeHelper> mergeHelpers) =>
    MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      emissions: const [],
      isRequired: true,
      mergeHelpers: mergeHelpers,
    );
