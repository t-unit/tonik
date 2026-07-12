import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';

const _tonikUtilUrl = 'package:tonik_util/tonik_util.dart';

/// Which flat wire medium a decode plan targets.
enum FlatWireFormat { simple, form }

/// Plan for encoding one model occupying one flat object-property slot.
///
/// Callers omit null (RFC 6570 undefined) entries before rendering a plan;
/// plan expressions therefore receive defined, non-null values. Whether a
/// specific encode operation exists is answered here — never by a separate
/// boolean capability gate.
sealed class FlatEncodePlan {
  const FlatEncodePlan();
}

/// The value converts to one raw scalar wire string.
final class FlatScalarEncodePlan extends FlatEncodePlan {
  const FlatScalarEncodePlan({required this.value});

  /// Raw (unescaped) `String` expression for the defined value.
  final Expression value;
}

/// The value converts to a raw string per element, preserving boundaries
/// for the late style renderer.
final class FlatArrayEncodePlan extends FlatEncodePlan {
  const FlatArrayEncodePlan({required this.values});

  /// Raw (unescaped) `List<String>` expression.
  final Expression values;
}

/// The model has no defined flat representation.
final class UnsupportedFlatEncodePlan extends FlatEncodePlan {
  const UnsupportedFlatEncodePlan({required this.reason});

  final String reason;
}

/// Plan for decoding one model from one flat object-property slot.
sealed class FlatDecodePlan {
  const FlatDecodePlan();
}

/// The slot decodes to a single value.
final class FlatScalarDecodePlan extends FlatDecodePlan {
  const FlatScalarDecodePlan({required this.value});

  final Expression value;
}

/// The original runtime type cannot be recovered from a flat string.
final class UnsupportedFlatDecodePlan extends FlatDecodePlan {
  const UnsupportedFlatDecodePlan({required this.reason});

  final String reason;
}

/// Builds the flat encode plan for [value] of [model].
///
/// [context] names the value's location for runtime unknown-value errors.
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

/// Builds the flat decode plan for [value] of [model] from [format].
///
/// Decode support is independent from encode support: Binary values decode
/// from a flat slot but have no flat encoding.
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

/// Why [model] cannot be decoded from one flat object-property slot, or
/// null when it can.
///
/// Nested objects and compositions have no OAS-defined single-slot text
/// form, so they are unsupported here even though they expose fromSimple
/// factories for whole-value decoding. Lists are unsupported because the
/// object decoder cannot recover element boundaries of unknown keys:
/// exploded simple pairs split on the same comma that separates elements,
/// and repeated form keys overwrite each other outside the declared
/// list-key set.
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
).call([value], {'context': literalString(context)});

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
