import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('ClassGenerator with CorePrefixedAllocator', () {
    late ClassGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
    });

    test('generates code with prefixed dart:core types', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'isActive',
            model: BooleanModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      final result = generator.generate(model);
      
      // Check that the generated code contains dart:core prefixes
      expect(result.code, contains("import 'dart:core' as _i"));
      expect(result.code, contains('_i'));
      
      // Verify that core types have prefixes
      final coreTypeRegex = RegExp(r'_i\d+\.(String|int|bool|Map|List)');
      expect(coreTypeRegex.hasMatch(result.code), isTrue);
      
      // Print the result for manual inspection
      print('Generated code contains the following imports:');
      RegExp(r'import.*').allMatches(result.code).forEach((match) {
        print(match.group(0));
      });
      
      print('\nGenerated file: ${result.filename}');
    });
  });
} 