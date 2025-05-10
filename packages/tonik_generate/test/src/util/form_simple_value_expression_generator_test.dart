// Generated code won't have whitespcae in long lines, so we ignore this.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/form_simple_value_expression_generator.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  late DartEmitter emitter;
  late CorePrefixedAllocator scopedAllocator;
  late DartEmitter scopedEmitter;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(generator: NameGenerator());
    emitter = DartEmitter(useNullSafetySyntax: true);
    scopedAllocator = CorePrefixedAllocator();
    scopedEmitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: scopedAllocator,
    );
  });

  group('buildFormSimpleValueExpression', () {
    test('generates for primitive types', () {
      final stringHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: StringModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          stringHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleString()',
      );

      final nullableStringHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: StringModel(context: context),
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableStringHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableString()',
      );

      final intHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: IntegerModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          intHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleInt()',
      );

      final nullableIntHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: IntegerModel(context: context),
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableIntHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableInt()',
      );

      final boolHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: BooleanModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          boolHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleBool()',
      );

      final nullableBoolHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: BooleanModel(context: context),
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableBoolHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableBool()',
      );

      final dateTimeHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: DateTimeModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          dateTimeHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleDateTime()',
      );

      final nullableDateTimeHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: DateTimeModel(context: context),
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableDateTimeHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableDateTime()',
      );

      final decimalHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: DecimalModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          decimalHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleBigDecimal()',
      );

      final nullableDecimalHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: DecimalModel(context: context),
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableDecimalHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableBigDecimal()',
      );
    });

    test('generates for enum types', () {
      final enumModel = EnumModel(
        context: context,
        name: 'UserRole',
        values: const {'admin', 'user'},
        isNullable: false,
      );
      final enumHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: enumModel,
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          enumHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "UserRole.fromSimple(response.headers.value(r'x-header'))",
      );

      final nullableEnumHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: enumModel,
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableEnumHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header') == null "
        '? null '
        ": UserRole.fromSimple(response.headers.value(r'x-header')!)",
      );
    });

    test('generates for class types', () {
      final classModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      final classHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: classModel,
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          classHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "User.fromSimple(response.headers.value(r'x-header'))",
      );

      final nullableClassHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: classModel,
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableClassHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header') == null "
        '? null '
        ": User.fromSimple(response.headers.value(r'x-header')!)",
      );
    });

    test('generates for list of primitives', () {
      final stringListModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final stringListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: stringListModel,
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          stringListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header').decodeSimpleStringList()",
      );

      final nullableStringListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: stringListModel,
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableStringListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header').decodeSimpleNullableStringList()",
      );

      final intListModel = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );
      final intListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: intListModel,
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          intListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleStringList()'
        '.map((e) => e.decodeSimpleInt()).toList()',
      );

      final nullableIntListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: intListModel,
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableIntListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableStringList()'
        '?.map((e) => e.decodeSimpleInt()).toList()',
      );

      final boolListModel = ListModel(
        content: BooleanModel(context: context),
        context: context,
      );
      final boolListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: boolListModel,
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          boolListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleStringList()'
        '.map((e) => e.decodeSimpleBool()).toList()',
      );

      final nullableBoolListHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: boolListModel,
        isRequired: false,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      expect(
        buildFormSimpleValueExpression(
          nullableBoolListHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header')"
        '.decodeSimpleNullableStringList()'
        '?.map((e) => e.decodeSimpleBool()).toList()',
      );
    });

    test('generates for alias header', () {
      final baseHeader = ResponseHeaderObject(
        name: 'x-header',
        context: context,
        description: null,
        explode: false,
        model: IntegerModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
      );
      final aliasHeader = ResponseHeaderAlias(
        name: 'x-header-alias',
        header: baseHeader,
        context: context,
      );
      expect(
        buildFormSimpleValueExpression(
          aliasHeader,
          nameManager: nameManager,
          package: 'tonik_core',
          headerName: 'x-header',
        ).accept(emitter).toString(),
        "response.headers.value(r'x-header').decodeSimpleInt()",
      );
    });

    group('with scoped emitter', () {
      test('generates for scoped enum types', () {
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );
        final enumHeader = ResponseHeaderObject(
          name: 'x-header',
          context: context,
          description: null,
          explode: false,
          model: enumModel,
          isRequired: true,
          isDeprecated: false,
          encoding: ResponseHeaderEncoding.simple,
        );
        expect(
          buildFormSimpleValueExpression(
            enumHeader,
            nameManager: nameManager,
            package: 'tonik_core',
            headerName: 'x-header',
          ).accept(scopedEmitter).toString(),
          "_i1.UserRole.fromSimple(response.headers.value(r'x-header'))",
        );
      });

      test('generates for scoped list of enums', () {
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );
        final listModel = ListModel(content: enumModel, context: context);
        final enumListHeader = ResponseHeaderObject(
          name: 'x-header',
          context: context,
          description: null,
          explode: false,
          model: listModel,
          isRequired: true,
          isDeprecated: false,
          encoding: ResponseHeaderEncoding.simple,
        );
        expect(
          buildFormSimpleValueExpression(
            enumListHeader,
            nameManager: nameManager,
            package: 'tonik_core',
            headerName: 'x-header',
          ).accept(scopedEmitter).toString(),
          "response.headers.value(r'x-header')"
          '.decodeSimpleStringList()'
          '.map((e) => _i1.UserRole.fromSimple(e)).toList()',
        );
      });
    });
  });
}
