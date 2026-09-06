import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  test(
    'object models inherit both delimited encoders through the typed hook',
    () {
      final context = Context.initial();
      final generator = ClassGenerator(
        nameManager: NameManager(
          generator: NameGenerator(),
          stableModelSorter: StableModelSorter(),
        ),
        package: 'example',
      );
      final model = ClassModel(
        isDeprecated: false,
        name: 'TestModel',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
      expect(
        generatedClass.methods.any(
          (method) => method.name == 'toPipeDelimited',
        ),
        isFalse,
      );
      expect(
        generatedClass.methods.any(
          (method) => method.name == 'toSpaceDelimited',
        ),
        isFalse,
      );
    },
  );
}
