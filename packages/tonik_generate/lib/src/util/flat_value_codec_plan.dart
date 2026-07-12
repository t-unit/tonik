import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

const _tonikUtilUrl = 'package:tonik_util/tonik_util.dart';

/// Flat decoding medium.
enum FlatWireFormat { simple, form }

/// Encoding plan for one flat property slot.
sealed class FlatEncodePlan {
  const FlatEncodePlan();
}

/// Scalar flat encoding.
final class FlatScalarEncodePlan extends FlatEncodePlan {
  const FlatScalarEncodePlan({required this.value});

  /// Raw string expression.
  final Expression value;
}

/// Array flat encoding.
final class FlatArrayEncodePlan extends FlatEncodePlan {
  const FlatArrayEncodePlan({required this.values});

  /// Raw string-list expression.
  final Expression values;
}

/// Unsupported flat encoding.
final class UnsupportedFlatEncodePlan extends FlatEncodePlan {
  const UnsupportedFlatEncodePlan({required this.reason});

  final String reason;
}

/// Decoding plan for one flat property slot.
sealed class FlatDecodePlan {
  const FlatDecodePlan();
}

/// Scalar flat decoding.
final class FlatScalarDecodePlan extends FlatDecodePlan {
  const FlatScalarDecodePlan({required this.value});

  final Expression value;
}

/// Unsupported flat decoding.
final class UnsupportedFlatDecodePlan extends FlatDecodePlan {
  const UnsupportedFlatDecodePlan({required this.reason});

  final String reason;
}

/// Builds a flat encoding plan.
FlatEncodePlan buildFlatEncodePlan(
  Expression value,
  Model model, {
  required String context,
  bool useImmutableCollections = false,
}) {
  switch (model) {
    case StringModel() ||
        IntegerModel() ||
        NumberModel() ||
        DoubleModel() ||
        BooleanModel() ||
        DecimalModel() ||
        UriModel() ||
        DateModel() ||
        DateTimeModel() ||
        EnumModel() ||
        Base64Model():
      return FlatScalarEncodePlan(
        value: buildRawStringExpression(value, model),
      );
    case AnyModel():
      return FlatScalarEncodePlan(
        value: _unknownFlatScalarCall(value, context),
      );
    case AliasModel():
      return buildFlatEncodePlan(
        value,
        model.model,
        context: context,
        useImmutableCollections: useImmutableCollections,
      );
    case ListModel():
      return _buildArrayEncodePlan(
        value,
        model,
        context: context,
        useImmutableCollections: useImmutableCollections,
      );
    case NeverModel():
      return const UnsupportedFlatEncodePlan(
        reason: 'NeverModel does not permit any value',
      );
    case BinaryModel():
      return const UnsupportedFlatEncodePlan(
        reason: 'Binary values have no flat representation',
      );
    default:
      return UnsupportedFlatEncodePlan(
        reason: '${model.runtimeType} values have no flat representation',
      );
  }
}

/// Builds a flat decoding plan.
FlatDecodePlan buildFlatDecodePlan(
  Expression value,
  Model model, {
  required FlatWireFormat format,
  required bool isRequired,
  required NameManager nameManager,
  required Expression explode,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final reason = _flatSlotDecodingUnsupportedReason(model);
  if (reason != null) {
    return UnsupportedFlatDecodePlan(reason: reason);
  }

  final expression = switch (format) {
    FlatWireFormat.simple => buildSimpleValueExpression(
      value,
      model: model,
      isRequired: isRequired,
      nameManager: nameManager,
      explode: explode,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
    ).expression,
    FlatWireFormat.form => buildFromFormValueExpression(
      value,
      model: model,
      isRequired: isRequired,
      nameManager: nameManager,
      explode: explode,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
    ).expression,
  };

  return FlatScalarDecodePlan(value: expression);
}

String? _flatSlotDecodingUnsupportedReason(Model model) => switch (model) {
  StringModel() ||
  IntegerModel() ||
  NumberModel() ||
  DoubleModel() ||
  DecimalModel() ||
  BooleanModel() ||
  DateTimeModel() ||
  DateModel() ||
  UriModel() ||
  BinaryModel() ||
  Base64Model() ||
  EnumModel() ||
  AnyModel() => null,
  NeverModel() => 'NeverModel does not permit any value',
  MapModel() => 'Map values cannot be decoded from a flat value',
  ListModel() => 'List values cannot be decoded from a flat value',
  AliasModel(:final model) => _flatSlotDecodingUnsupportedReason(model),
  _ => '${model.runtimeType} values cannot be decoded from a flat value',
};

Expression _unknownFlatScalarCall(Expression value, String context) => refer(
  'encodeUnknownFlatScalar',
  _tonikUtilUrl,
).call([value], {'context': specLiteralString(context)});

FlatEncodePlan _buildArrayEncodePlan(
  Expression value,
  ListModel model, {
  required String context,
  required bool useImmutableCollections,
}) {
  final content = model.content.resolved;
  final isContentNullable =
      model.isContentNullable || model.content.isEffectivelyNullable;
  final listExpr = useImmutableCollections
      ? value.property('unlock')
      : value;

  Expression nullGuard(Expression raw) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), raw)
      : raw;

  Expression mapToRaw(Expression body) => listExpr
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = body.code,
        ).closure,
      ])
      .property('toList')
      .call([]);

  switch (content) {
    case StringModel() when isContentNullable:
      return FlatArrayEncodePlan(
        values: mapToRaw(refer('e').ifNullThen(literalString(''))),
      );
    case StringModel():
      return FlatArrayEncodePlan(values: listExpr);
    case IntegerModel() ||
        NumberModel() ||
        DoubleModel() ||
        BooleanModel() ||
        DecimalModel() ||
        UriModel() ||
        DateModel() ||
        DateTimeModel() ||
        EnumModel() ||
        Base64Model():
      return FlatArrayEncodePlan(
        values: mapToRaw(
          nullGuard(buildRawStringExpression(refer('e'), content)),
        ),
      );
    case AnyModel():
      return FlatArrayEncodePlan(
        values: mapToRaw(
          nullGuard(_unknownFlatScalarCall(refer('e'), context)),
        ),
      );
    case NeverModel():
      return const UnsupportedFlatEncodePlan(
        reason: 'NeverModel does not permit any value',
      );
    default:
      return UnsupportedFlatEncodePlan(
        reason:
            'List elements of ${content.runtimeType} have no flat '
            'representation',
      );
  }
}
