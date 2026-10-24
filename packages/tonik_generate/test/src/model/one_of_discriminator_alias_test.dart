import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late Class baseClass;
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    final context = Context.initial();
    final square = ClassModel(
      name: 'Square',
      properties: [],
      context: context,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final model = OneOfModel(
      name: 'Shape',
      models: [(discriminatorValue: 'square', model: square)],
      discriminator: 'shapeType',
      discriminatorAliases: {'box': 'square', 'crate': 'square'},
      context: context,
      isDeprecated: false,
      examples: const [],
      nameOverride: null,
      description: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
      defaultValue: null,
    );
    final sorter = StableModelSorter();
    final generator = OneOfGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: sorter,
      ),
      package: 'example',
      stableModelSorter: sorter,
    );
    baseClass = generator.generateClasses(model).first;
  });

  test('JSON discriminator switch explicitly recognizes every alias', () {
    final constructor = baseClass.constructors.singleWhere(
      (c) => c.name == 'fromJson',
    );
    final code = collapseWhitespace(
      format('void f() { ${constructor.body!.accept(emitter)} }'),
    );

    expect(
      code,
      contains(
        "r'square' || r'box' || r'crate' => "
        'ShapeSquare(Square.fromJson(json))',
      ),
    );
    expect(code, isNot(contains("r'Square' =>")));
  });

  test('simple and header discriminator paths recognize aliases', () {
    final constructor = baseClass.constructors.singleWhere(
      (c) => c.name == 'fromSimple',
    );
    final code = collapseWhitespace(
      format('void f() { ${constructor.body!.accept(emitter)} }'),
    );

    expect(
      code,
      contains(
        "findHeaderDiscriminator(r'shapeType', "
        "{ r'square', r'box', r'crate', })",
      ),
    );
    expect(
      code,
      contains(
        r"if (_$discriminator == r'square' || _$discriminator == r'box' || "
        r"_$discriminator == r'crate') { return ShapeSquare(",
      ),
    );
  });

  test('form discriminator path explicitly recognizes aliases', () {
    final constructor = baseClass.constructors.singleWhere(
      (c) => c.name == 'fromForm',
    );
    final code = collapseWhitespace(
      format('void f() { ${constructor.body!.accept(emitter)} }'),
    );

    expect(code, contains(r"final _$pairs = value.split('&');"));
    expect(
      code,
      contains(
        r"if (_$discriminator == r'square' || _$discriminator == r'box' || "
        r"_$discriminator == r'crate') { return ShapeSquare(",
      ),
    );
  });

  test('serialization keeps the first mapping value as its default', () {
    final method = baseClass.methods.singleWhere((m) => m.name == 'toJson');
    final code = collapseWhitespace(format(method.accept(emitter).toString()));

    expect(
      code,
      contains("ShapeSquare(:final value) => (value.toJson(), r'square')"),
    );
  });
}
