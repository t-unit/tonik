import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_label_path_parameter_expression_generator.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('buildToLabelPathParameterExpression', () {
    test('generates toLabel expression for primitive path parameter', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('userId', parameter),
        'userId.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test(
      'generates toLabel expression for array path parameter with '
      'explode=false',
      () {
        final parameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          buildToLabelPathParameterExpression('ids', parameter),
          'ids.toLabel(explode: false, allowEmpty: false)',
        );
      },
    );

    test(
      'generates toLabel expression for array path parameter with explode=true',
      () {
        final parameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: true,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          buildToLabelPathParameterExpression('ids', parameter),
          'ids.toLabel(explode: true, allowEmpty: false)',
        );
      },
    );

    test('generates toLabel expression for optional path parameter', () {
      final parameter = PathParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Optional filter parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: true,
        isRequired: false,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('filter', parameter),
        'filter?.toLabel(explode: false, allowEmpty: true)',
      );
    });

    test('generates toLabel expression for enum path parameter', () {
      final parameter = PathParameterObject(
        name: 'status',
        rawName: 'status',
        description: 'Status parameter',
        model: EnumModel(
          context: context,
          name: 'Status',
          values: const {'active', 'inactive', 'pending'},
          isNullable: false,
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('status', parameter),
        'status.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test('generates toLabel expression for integer path parameter', () {
      final parameter = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: 'ID parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('id', parameter),
        'id.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test('generates toLabel expression for double path parameter', () {
      final parameter = PathParameterObject(
        name: 'price',
        rawName: 'price',
        description: 'Price parameter',
        model: DoubleModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('price', parameter),
        'price.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test('generates toLabel expression for boolean path parameter', () {
      final parameter = PathParameterObject(
        name: 'enabled',
        rawName: 'enabled',
        description: 'Enabled parameter',
        model: BooleanModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('enabled', parameter),
        'enabled.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test('generates toLabel expression for DateTime path parameter', () {
      final parameter = PathParameterObject(
        name: 'timestamp',
        rawName: 'timestamp',
        description: 'Timestamp parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('timestamp', parameter),
        'timestamp.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test('generates toLabel expression for class path parameter', () {
      final parameter = PathParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter parameter',
        model: ClassModel(
          context: context,
          name: 'Filter',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'value',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        ),
        encoding: PathParameterEncoding.label,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToLabelPathParameterExpression('filter', parameter),
        'filter.toLabel(explode: false, allowEmpty: false)',
      );
    });

    test(
      'generates toLabel expression with custom explode and allowEmpty '
      'parameters',
      () {
        final explodeTrueParameter = PathParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'User IDs parameter',
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          encoding: PathParameterEncoding.label,
          explode: true,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
        );
        expect(
          buildToLabelPathParameterExpression('ids', explodeTrueParameter),
          'ids.toLabel(explode: true, allowEmpty: false)',
        );
      },
    );
  });
}
