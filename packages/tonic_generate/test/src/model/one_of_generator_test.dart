import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/one_of_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('OneOfGenerator', () {
    late OneOfGenerator generator;
    late NameManger nameManger;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManger = NameManger(generator: nameGenerator);
      generator = OneOfGenerator(
        nameManger: nameManger,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates sealed class with correct name and annotations', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (discriminatorValue: 'success', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      expect(generatedClass.name, 'Result');
      expect(generatedClass.sealed, isTrue);
      expect(generatedClass.annotations, hasLength(1));
      expect(
        generatedClass.annotations.first.code.accept(emitter).toString(),
        'freezed',
      );
      expect(generatedClass.mixins, hasLength(1));
      expect(
        generatedClass.mixins.first.accept(emitter).toString(),
        r'_$Result',
      );
    });

    test('generates factory constructors with correct names and types', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (discriminatorValue: 'success', model: StringModel(context: context)),
          (discriminatorValue: 'error', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      expect(generatedClass.constructors, hasLength(2));

      final successConstructor = generatedClass.constructors.first;
      expect(successConstructor.name, 'success');
      expect(successConstructor.factory, isTrue);
      expect(successConstructor.constant, isTrue);
      expect(successConstructor.requiredParameters, hasLength(1));
      expect(
        successConstructor.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String',
      );
      expect(
        successConstructor.redirect?.symbol,
        'ResultSuccess',
        reason: 'Should redirect to public class name',
      );

      final errorConstructor = generatedClass.constructors.last;
      expect(errorConstructor.name, 'error');
      expect(errorConstructor.factory, isTrue);
      expect(errorConstructor.constant, isTrue);
      expect(errorConstructor.requiredParameters, hasLength(1));
      expect(
        errorConstructor.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'int',
      );
      expect(
        errorConstructor.redirect?.symbol,
        'ResultError',
        reason: 'Should redirect to public class name',
      );
    });

    test('uses model name when discriminator value is not available', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Success',
              properties: const {},
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Error',
              properties: const {},
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      expect(generatedClass.constructors, hasLength(2));
      expect(generatedClass.constructors.first.name, 'success');
      expect(
        generatedClass.constructors.first.redirect?.symbol,
        'ResultSuccess',
        reason: 'Should redirect to public class name',
      );
      expect(generatedClass.constructors.last.name, 'error');
      expect(
        generatedClass.constructors.last.redirect?.symbol,
        'ResultError',
        reason: 'Should redirect to public class name',
      );
    });

    test('handles nested models correctly', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: 'data',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      expect(generatedClass.constructors, hasLength(1));

      final dataConstructor = generatedClass.constructors.first;
      expect(dataConstructor.name, 'data');
      expect(
        dataConstructor.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'List<String>',
      );
      expect(
        dataConstructor.redirect?.symbol,
        'ResultData',
        reason: 'Should redirect to public class name',
      );
    });
  });
}
