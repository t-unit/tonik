import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_support_generator.dart';

void main() {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  test('generates a cryptographically secure 256-bit boundary', () {
    final specs = buildHttpMultipartSupport(
      includesPartHeaders: false,
      includesPlainFields: false,
    );
    final boundaryMethod = specs.whereType<Method>().singleWhere(
      (method) => method.name == '_createMultipartBoundary',
    );

    const expected = r'''
String _createMultipartBoundary() {
  final random = Random.secure();
  final bytes = List.generate(32, (_) => random.nextInt(256));
  final suffix = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return 'tonik-$suffix';
}
''';

    expect(
      collapseWhitespace(format('${boundaryMethod.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );

    final requestClass = specs.whereType<Class>().singleWhere(
      (generatedClass) => generatedClass.name == '_TonikMultipartRequest',
    );
    final boundaryField = requestClass.fields.singleWhere(
      (field) => field.name == '_boundary',
    );

    expect(boundaryField.type?.accept(emitter).toString(), 'String');
    expect(boundaryField.modifier, FieldModifier.final$);
    expect(
      boundaryField.assignment?.accept(emitter).toString(),
      '_createMultipartBoundary()',
    );
  });
}
