import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

void main() {
  test('class roots retain regular types and direct field access', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final base = ClassModel(
      name: 'Upload',
      context: context.push('Upload'),
      properties: [
        Property(
          name: 'display-name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final requestContent = MultipartRequestContent(
      model: base,
      rawContentType: 'multipart/form-data',
      examples: const [],
    );
    final reference = requestContentTypeReference(
      requestContent,
      manager,
      'example',
    );
    expect(reference.symbol, 'Upload');
    expect(
      reference.url,
      'package:example/src/model/upload.dart',
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          requestContent,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'display-name', utf8.encode(body.displayName),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );

    final generated = ClassGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      package: 'example',
    ).generateClass(base);
    expect(generated.fields.map((f) => f.name), ['displayName']);
    expect(
      generated.constructors
          .firstWhere((c) => c.name == null)
          .optionalParameters
          .map((p) => p.name),
      ['displayName'],
    );
  });

  test('alias roots retain regular types and direct field access', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final base = ClassModel(
      name: 'Upload',
      context: context.push('Upload'),
      properties: [
        Property(
          name: 'display-name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final renamed = AliasModel(
      name: 'UploadAlias',
      context: context.push('UploadAlias'),
      model: base,
      examples: const [],
      defaultValue: null,
    );

    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final requestContent = MultipartRequestContent(
      model: renamed,
      rawContentType: 'multipart/form-data',
      examples: const [],
    );
    final reference = requestContentTypeReference(
      requestContent,
      manager,
      'example',
    );
    expect(reference.symbol, 'UploadAlias');
    expect(
      reference.url,
      'package:example/src/model/upload_alias.dart',
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          requestContent,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'display-name', utf8.encode(body.displayName),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test('inline class roots retain regular types and direct field access', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final inline = ClassModel(
      context: context.pushAll(['upload', 'body']),
      properties: [
        Property(
          name: 'display-name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
    );

    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final requestContent = MultipartRequestContent(
      model: inline,
      rawContentType: 'multipart/form-data',
      examples: const [],
    );
    final reference = requestContentTypeReference(
      requestContent,
      manager,
      'example',
    );
    expect(reference.symbol, 'UploadBodyModel');
    expect(
      reference.url,
      'package:example/src/model/upload_body_model.dart',
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          requestContent,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'display-name', utf8.encode(body.displayName),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test('nested allOf reads normal member objects in declaration order', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final zebra = ClassModel(
      name: 'Zebra',
      context: context.push('Zebra'),
      properties: [
        Property(
          name: 'first',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final alpha = ClassModel(
      name: 'Alpha',
      context: context.push('Alpha'),
      properties: [
        Property(
          name: 'second',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final middle = AllOfModel(
      name: 'Middle',
      context: context.push('Middle'),
      models: [alpha],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final root = AllOfModel(
      name: 'Upload',
      context: context.push('Upload'),
      models: [
        AliasModel(
          name: 'ZebraAlias',
          context: context.push('ZebraAlias'),
          model: zebra,
          examples: const [],
          defaultValue: null,
        ),
        middle,
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final generator = AllOfGenerator(
      nameManager: manager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    final generated = generator.generateClass(root);
    final copyMethods = generator
        .generateClasses(root)
        .whereType<Class>()
        .expand((c) => c.methods)
        .where((m) => m.name == 'call');
    expect(copyMethods, isNotEmpty);
    for (final method in copyMethods) {
      expect(method.optionalParameters.map((p) => p.name), [
        'zebraAlias',
        'middle',
      ]);
    }
    expect(generated.fields.map((f) => f.name), ['zebraAlias', 'middle']);
    expect(
      generated.constructors
          .firstWhere((c) => c.name == null)
          .optionalParameters
          .map((p) => p.name),
      ['zebraAlias', 'middle'],
    );
    expect(
      generated.methods
          .where((m) => m.type == MethodType.getter)
          .map((m) => m.name),
      isNot(contains('first')),
    );
    final reference = requestContentTypeReference(
      MultipartRequestContent(
        model: root,
        rawContentType: 'multipart/form-data',
        examples: const [],
      ),
      manager,
      'example',
    );
    expect(reference.symbol, 'Upload');
    expect(reference.url, 'package:example/src/model/upload.dart');

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          MultipartRequestContent(
            model: root,
            rawContentType: 'multipart/form-data',
            examples: const [],
          ),
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'first', utf8.encode(body.zebraAlias.first),
    contentType: MediaType.parse(r'text/plain'),
  ));
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'second', utf8.encode(body.middle.alpha.second),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test('compound generators preserve member declaration order', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final zebra = ClassModel(
      name: 'Zebra',
      context: context.push('Zebra'),
      properties: [
        Property(
          name: 'z',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final alpha = ClassModel(
      name: 'Alpha',
      context: context.push('Alpha'),
      properties: [
        Property(
          name: 'a',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final members = <DiscriminatedModel>[
      (model: zebra, discriminatorValue: 'z'),
      (model: alpha, discriminatorValue: 'a'),
    ];
    final all =
        AllOfGenerator(
          nameManager: manager,
          package: 'example',
          stableModelSorter: StableModelSorter(),
        ).generateClass(
          AllOfModel(
            name: 'All',
            context: context.push('All'),
            models: [zebra, alpha],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        );
    final any =
        AnyOfGenerator(
          nameManager: manager,
          package: 'example',
          stableModelSorter: StableModelSorter(),
        ).generateClass(
          AnyOfModel(
            name: 'Any',
            context: context.push('Any'),
            models: members,
            isDeprecated: false,
            examples: const [],
          ),
        );
    final one =
        OneOfGenerator(
          nameManager: manager,
          package: 'example',
          stableModelSorter: StableModelSorter(),
        ).generateClasses(
          OneOfModel(
            name: 'One',
            context: context.push('One'),
            models: members,
            isDeprecated: false,
            examples: const [],
          ),
        );
    expect(all.fields.map((f) => f.name), ['zebra', 'alpha']);
    expect(any.fields.map((f) => f.name), ['zebra', 'alpha']);
    expect(one.where((c) => c.name != 'One').map((c) => c.name), [
      'OneZebra',
      'OneAlpha',
    ]);
  });

  test('dio rejects string multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: text,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects integer multipart root', () {
    final context = Context.initial();
    final integer = IntegerModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: integer,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects binary multipart root', () {
    final context = Context.initial();
    final binary = BinaryModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: binary,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects list multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: ListModel(content: text, context: context, examples: const []),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects map multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: MapModel(
            valueModel: text,
            context: context,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects any multipart root', () {
    final context = Context.initial();

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: AnyModel(context: context),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects never multipart root', () {
    final context = Context.initial();

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: NeverModel(context: context, isNullable: false),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects oneOf multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final variants = <DiscriminatedModel>[
      (model: supported, discriminatorValue: null),
    ];

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: OneOfModel(
            name: 'One',
            context: context,
            models: variants,
            isDeprecated: false,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects anyOf multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final variants = <DiscriminatedModel>[
      (model: supported, discriminatorValue: null),
    ];

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: AnyOfModel(
            name: 'Any',
            context: context,
            models: variants,
            isDeprecated: false,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects unsupported allOf member multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: AllOfModel(
            name: 'UnsupportedMember',
            context: context.push('UnsupportedMember'),
            models: [supported, text],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects alias cycle multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final cyclicAlias = AliasModel(
      name: 'Cycle',
      context: context.push('Cycle'),
      model: supported,
      examples: const [],
      defaultValue: null,
    );
    cyclicAlias.model = cyclicAlias;

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: cyclicAlias,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects allOf cycle multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final cycle = AllOfModel(
      name: 'CycleRoot',
      context: context.push('CycleRoot'),
      models: [supported],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    cycle.models.add(cycle);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: cycle,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects string multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: text,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects integer multipart root', () {
    final context = Context.initial();
    final integer = IntegerModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: integer,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects binary multipart root', () {
    final context = Context.initial();
    final binary = BinaryModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: binary,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects list multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: ListModel(content: text, context: context, examples: const []),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects map multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: MapModel(
            valueModel: text,
            context: context,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects any multipart root', () {
    final context = Context.initial();

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: AnyModel(context: context),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects never multipart root', () {
    final context = Context.initial();

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: NeverModel(context: context, isNullable: false),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects oneOf multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final variants = <DiscriminatedModel>[
      (model: supported, discriminatorValue: null),
    ];

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: OneOfModel(
            name: 'One',
            context: context,
            models: variants,
            isDeprecated: false,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects anyOf multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final variants = <DiscriminatedModel>[
      (model: supported, discriminatorValue: null),
    ];

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: AnyOfModel(
            name: 'Any',
            context: context,
            models: variants,
            isDeprecated: false,
            examples: const [],
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects unsupported allOf member multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: AllOfModel(
            name: 'UnsupportedMember',
            context: context.push('UnsupportedMember'),
            models: [supported, text],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects alias cycle multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final cyclicAlias = AliasModel(
      name: 'Cycle',
      context: context.push('Cycle'),
      model: supported,
      examples: const [],
      defaultValue: null,
    );
    cyclicAlias.model = cyclicAlias;

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: cyclicAlias,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('http rejects allOf cycle multipart root', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final supported = ClassModel(
      name: 'Supported',
      context: context.push('Supported'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final cycle = AllOfModel(
      name: 'CycleRoot',
      context: context.push('CycleRoot'),
      models: [supported],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    cycle.models.add(cycle);

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: cycle,
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(predicate<Object>((error) => error.toString().trim().isNotEmpty)),
    );
  });

  test('dio rejects incompatible repeated property definitions', () {
    final context = Context.initial();
    final text = StringModel(context: context);
    final integer = IntegerModel(context: context);

    final first = ClassModel(
      name: 'First',
      context: context.push('First'),
      properties: [
        Property(
          name: 'value',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final second = ClassModel(
      name: 'Second',
      context: context.push('Second'),
      properties: [
        Property(
          name: 'value',
          model: integer,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
        MultipartRequestContent(
          model: AllOfModel(
            name: 'Upload',
            context: context.push('Upload'),
            models: [first, second],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(
        predicate<Object>((error) => error.toString().trim().isNotEmpty),
      ),
    );
  });

  test('http rejects incompatible repeated property definitions', () {
    final context = Context.initial();
    final text = StringModel(context: context);
    final integer = IntegerModel(context: context);

    final first = ClassModel(
      name: 'First',
      context: context.push('First'),
      properties: [
        Property(
          name: 'value',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final second = ClassModel(
      name: 'Second',
      context: context.push('Second'),
      properties: [
        Property(
          name: 'value',
          model: integer,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    expect(
      () => const MultipartBodyPlanner(backend: TransportBackend.http).plan(
        MultipartRequestContent(
          model: AllOfModel(
            name: 'Upload',
            context: context.push('Upload'),
            models: [first, second],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          rawContentType: 'multipart/form-data',
          examples: const [],
        ),
        bodyAccessor: 'body',
        isRequired: true,
      ),
      throwsA(
        predicate<Object>((error) => error.toString().trim().isNotEmpty),
      ),
    );
  });

  test('raw encoding names preserve visibility nullability and defaults', () {
    final context = Context.initial();
    final text = StringModel(context: context);
    final integer = IntegerModel(context: context);
    final binary = BinaryModel(context: context);

    final base = ClassModel(
      name: 'Upload',
      context: context.push('Upload'),
      properties: [
        Property(
          name: 'server-id',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isReadOnly: true,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'display-name',
          model: text,
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'secret',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isWriteOnly: true,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'count',
          model: integer,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'file',
          model: binary,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'metadata',
          model: ClassModel(
            name: 'Metadata',
            context: context.push('Metadata'),
            properties: [
              Property(
                name: 'label',
                model: text,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final requestContent = MultipartRequestContent(
      model: base,
      encoding: {
        'display-name': const PartEncoding(
          contentType: ContentType.text,
          rawContentType: 'text/custom',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
        ),
      },
      rawContentType: 'multipart/form-data',
      examples: const [],
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          requestContent,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  if (body.displayName != null) {
    _$multipartFiles.add(MultipartFile.fromBytes(
      r'display-name', utf8.encode(body.displayName!),
      contentType: MediaType.parse(r'text/custom'),
    ));
  }
  if (body.secret == null) { throw 'required'; }
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'secret', utf8.encode(body.secret!), contentType: MediaType.parse(r'text/plain'),
  ));
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'count', utf8.encode(body.count.toString()), contentType: MediaType.parse(r'text/plain'),
  ));
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'file', body.file.toBytes(), filename: body.file.fileName ?? r'file',
    contentType: MediaType.parse(r'application/octet-stream'),
  ));
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'metadata', utf8.encode(jsonEncode(body.metadata.toJson())),
    contentType: MediaType.parse(r'application/json'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(
        formatter.format(
          actual.replaceAll(RegExp('throw [^;]+;'), "throw 'required';"),
        ),
      ),
      collapseWhitespace(formatter.format(expected)),
    );

    expect(requestContent.encoding.keys, ['display-name']);
    expect(base.properties.map((p) => p.name), [
      'server-id',
      'display-name',
      'secret',
      'count',
      'file',
      'metadata',
    ]);
  });

  test('object array defaults serialize one complete JSON part', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final item = ClassModel(
      name: 'Item',
      context: context.push('Item'),
      properties: [
        Property(
          name: 'value',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final root = ClassModel(
      name: 'Upload',
      context: context.push('Upload'),
      properties: [
        Property(
          name: 'items',
          model: ListModel(content: item, context: context, examples: const []),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          MultipartRequestContent(
            model: root,
            rawContentType: 'multipart/form-data',
            examples: const [],
          ),
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'items', utf8.encode(jsonEncode(body.items.map((item) => item.toJson()).toList())),
    contentType: MediaType.parse(r'application/json'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test('class arrays retain file and scalar element order', () {
    final context = Context.initial();
    final text = StringModel(context: context);
    final binary = BinaryModel(context: context);

    final root = ClassModel(
      name: 'Upload',
      context: context.push('Upload'),
      properties: [
        Property(
          name: 'files',
          model: ListModel(
            content: binary,
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
        Property(
          name: 'labels',
          model: ListModel(content: text, context: context, examples: const []),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          MultipartRequestContent(
            model: root,
            rawContentType: 'multipart/form-data',
            examples: const [],
          ),
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  for (final item in body.files) {
    _$multipartFiles.add(MultipartFile.fromBytes(
      r'files', item.toBytes(), filename: item.fileName ?? r'files',
      contentType: MediaType.parse(r'application/octet-stream'),
    ));
  }
  for (final item in body.labels) {
    _$multipartFiles.add(MultipartFile.fromBytes(
      r'labels', utf8.encode(item), contentType: MediaType.parse(r'text/plain'),
    ));
  }
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(formatter.format(actual)),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test('per-use encodings do not mutate a shared class or JSON generation', () {
    final context = Context.initial();
    final integer = IntegerModel(context: context);

    final root = ClassModel(
      name: 'Shared',
      context: context.push('Shared'),
      properties: [
        Property(
          name: 'count',
          model: integer,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final first = MultipartRequestContent(
      model: root,
      rawContentType: 'multipart/form-data',
      examples: const [],
    );
    final second = MultipartRequestContent(
      model: root,
      encoding: {
        'count': const PartEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
        ),
      },
      rawContentType: 'multipart/form-data',
      examples: const [],
    );
    final generator = ClassGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      package: 'example',
    );
    final before = generator.generate(root).code;

    final firstPlan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          first,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final firstMethod = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(firstPlan)),
    );
    final firstActual = firstMethod
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const firstExpected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'count', utf8.encode(body.count.toString()), contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final firstFormatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(firstFormatter.format(firstActual)),
      collapseWhitespace(firstFormatter.format(firstExpected)),
    );

    final secondPlan =
        const MultipartBodyPlanner(backend: TransportBackend.http).plan(
          second,
          bodyAccessor: 'body',
          isRequired: true,
        );
    final secondMethod = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(secondPlan)),
    );
    final secondActual = secondMethod
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const secondExpected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'count', utf8.encode(jsonEncode(body.count)), contentType: MediaType.parse(r'application/json'),
  ));
  return _$multipartFiles;
}
''';
    final secondFormatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(secondFormatter.format(secondActual)),
      collapseWhitespace(secondFormatter.format(secondExpected)),
    );

    expect(generator.generate(root).code, before);
    expect(first.model, same(second.model));
    expect(first.encoding, isEmpty);
  });

  test('repeated properties emit once at the first declaration position', () {
    final context = Context.initial();
    final text = StringModel(context: context);

    final metadataA = ClassModel(
      name: 'MetadataA',
      context: context.push('MetadataA'),
      properties: [
        Property(
          name: 'name',
          model: text,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final metadataB = ClassModel(
      name: 'MetadataB',
      context: context.push('MetadataB'),
      properties: [
        Property(
          name: 'annotations',
          model: MapModel(
            valueModel: text,
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final root = AllOfModel(
      name: 'Upload',
      context: context.push('Upload'),
      models: [
        ClassModel(
          name: 'First',
          context: context.push('First'),
          properties: [
            Property(
              name: 'first',
              model: text,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'metadata',
              model: metadataA,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'server',
              model: text,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isReadOnly: true,
              examples: const [],
              defaultValue: null,
            ),
          ],
          isDeprecated: false,
          examples: const [],
          additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
        ),
        ClassModel(
          name: 'Second',
          context: context.push('Second'),
          properties: [
            Property(
              name: 'metadata',
              model: metadataB,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'last',
              model: text,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
              examples: const [],
              defaultValue: null,
            ),
          ],
          isDeprecated: false,
          examples: const [],
          additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          MultipartRequestContent(
            model: root,
            rawContentType: 'multipart/form-data',
            examples: const [],
          ),
          bodyAccessor: 'body',
          isRequired: true,
        );
    final parts = plan.emissions.whereType<MultipartAppend>().toList();
    expect(parts, hasLength(3));

    final firstMethod = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = parts[0].name.statement,
    );
    final firstExpected = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = literalString('first', raw: true).statement,
    );
    final firstEmitter = DartEmitter(useNullSafetySyntax: true);
    final firstFormat = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      collapseWhitespace(
        firstFormat(firstMethod.accept(firstEmitter).toString()),
      ),
      collapseWhitespace(
        firstFormat(firstExpected.accept(firstEmitter).toString()),
      ),
    );

    final metadataMethod = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = parts[1].name.statement,
    );
    final metadataExpected = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = literalString('metadata', raw: true).statement,
    );
    final metadataEmitter = DartEmitter(useNullSafetySyntax: true);
    final metadataFormat = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      collapseWhitespace(
        metadataFormat(metadataMethod.accept(metadataEmitter).toString()),
      ),
      collapseWhitespace(
        metadataFormat(metadataExpected.accept(metadataEmitter).toString()),
      ),
    );

    final lastMethod = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = parts[2].name.statement,
    );
    final lastExpected = Method(
      (b) => b
        ..name = 'name'
        ..lambda = true
        ..returns = refer('String', 'dart:core')
        ..body = literalString('last', raw: true).statement,
    );
    final lastEmitter = DartEmitter(useNullSafetySyntax: true);
    final lastFormat = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      collapseWhitespace(lastFormat(lastMethod.accept(lastEmitter).toString())),
      collapseWhitespace(
        lastFormat(lastExpected.accept(lastEmitter).toString()),
      ),
    );

    expect(parts[1].contentType, 'application/json');
  });

  test('dio keeps scalar arrays after files in allOf declaration order', () {
    final context = Context.initial();
    final files = ClassModel(
      name: 'Files',
      context: context,
      properties: [
        Property(
          name: 'files',
          model: ListModel(
            content: BinaryModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
    );
    final labels = ClassModel(
      name: 'Labels',
      context: context,
      properties: [
        Property(
          name: 'labels',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
    );
    final root = AllOfModel(
      name: 'Upload',
      context: context,
      models: [files, labels],
      isDeprecated: false,
      examples: const [],
    );
    final plan = const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
      MultipartRequestContent(
        model: root,
        rawContentType: 'multipart/form-data',
        examples: const [],
      ),
      bodyAccessor: 'body',
      isRequired: true,
    );
    expect(
      plan.emissions.whereType<MultipartAppend>().map((part) => part.source),
      [
        MultipartValueSource.bytes,
        MultipartValueSource.path,
        MultipartValueSource.text,
      ],
    );
  });

  test(
    'required writeOnly HTTP fields compile and reject null before sending',
    () async {
      final context = Context.initial();
      final model = ClassModel(
        name: 'Upload',
        context: context,
        properties: [
          Property(
            name: 'secret',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            isWriteOnly: true,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generated = ClassGenerator(
        nameManager: manager,
        package: 'example',
      ).generate(model);
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: model,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer('Upload', 'package:example/example.dart'),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_write_only_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:core';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${generated.code}
${encoder.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final parts = encode(const Upload(secret: 'token'));
  if (parts.length != 1 || parts.single.field != 'secret' ||
      utf8.decode(await parts.single.finalize().toBytes()) != 'token') {
    throw StateError('The writeOnly value was not encoded.');
  }
  var sent = false;
  var rejected = false;
  try {
    encode(const Upload(secret: null));
    sent = true;
  } catch (_) {
    rejected = true;
  }
  if (!rejected || sent) throw StateError('Missing required secret was sent.');
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test('required writeOnly Dio fields reject null before encoding', () {
    final context = Context.initial();
    final model = ClassModel(
      name: 'Upload',
      context: context,
      properties: [
        Property(
          name: 'secret',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isWriteOnly: true,
          examples: const [],
          defaultValue: null,
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    final plan = const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
      MultipartRequestContent(
        model: model,
        rawContentType: 'multipart/form-data',
        examples: const [],
      ),
      bodyAccessor: 'body',
      isRequired: true,
    );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildMultipartBodyStatements(plan).statements),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$formData = FormData();
  if (body.secret == null) { throw 'required'; }
  _$formData.files.add(MapEntry(r'secret', MultipartFile.fromString(
    body.secret!, contentType: DioMediaType.parse(r'text/plain'),
  )));
  return _$formData;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    expect(
      collapseWhitespace(
        formatter.format(
          actual.replaceAll(RegExp('throw [^;]+;'), "throw 'required';"),
        ),
      ),
      collapseWhitespace(formatter.format(expected)),
    );
  });
}
