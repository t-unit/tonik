import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

/// Returns null for the throwing cases (never/binary/complex map) and the
/// `AnyModel` single-string path, which each caller handles with
/// context-specific wording. Arguments are expressions so the same builder
/// serves literal call sites (query/cookie/body) and composite variant arms
/// that thread runtime parameters.
Expression? buildFormEntriesValueExpression(
  Expression receiver,
  Model model, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
  Expression? useQueryComponent,
  bool allowReserved = false,
  Expression? fieldEncodings,
}) {
  final toFormArgs = <String, Expression>{
    'explode': explode,
    'allowEmpty': allowEmpty,
    'useQueryComponent': ?useQueryComponent,
  };

  Expression toForm(
    Expression target, {
    bool alreadyEncoded = false,
    bool reserved = false,
    Expression? objectFieldEncodings,
  }) => target.property('toForm').call(
    [paramName],
    {
      ...toFormArgs,
      if (alreadyEncoded) 'alreadyEncoded': literalBool(true),
      if (reserved) 'allowReserved': literalBool(true),
      'fieldEncodings': ?objectFieldEncodings,
    },
  );

  switch (model) {
    case StringModel():
    case BooleanModel():
    case DateTimeModel():
    case DecimalModel():
    case UriModel():
    case DateModel():
    case IntegerModel():
    case DoubleModel():
    case NumberModel():
      return toForm(receiver, reserved: allowReserved);

    case EnumModel():
    case ClassModel():
    case AllOfModel():
    case OneOfModel():
    case AnyOfModel():
      return toForm(
        receiver,
        reserved: allowReserved,
        objectFieldEncodings: fieldEncodings,
      );

    case Base64Model():
      return toForm(
        receiver.property('toBase64String').call([]),
        reserved: allowReserved,
      );

    case MapModel():
      final converted = buildMapToStringMapExpression(
        receiver,
        model,
        isNullable: false,
      );
      if (converted == null) return null;
      // Conversion does not URI-encode, so the Map extension must still encode.
      return toForm(converted, reserved: allowReserved);

    case final ListModel m:
      return _buildListFormEntriesExpression(
        receiver,
        m.content,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        isContentNullable:
            m.isContentNullable || m.content.isEffectivelyNullable,
        toForm: toForm,
        allowReserved: allowReserved,
      );

    case AliasModel():
      return buildFormEntriesValueExpression(
        receiver,
        model.model,
        paramName: paramName,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      );

    case NeverModel():
    case BinaryModel():
    case AnyModel():
      return null;

    // The `NamedModel`/`CompositeModel` mixins keep the sealed hierarchy
    // non-exhaustive, so this arm is required.
    default:
      return null;
  }
}

Expression? _buildListFormEntriesExpression(
  Expression receiver,
  Model contentModel, {
  required Expression allowEmpty,
  required Expression? useQueryComponent,
  required bool isContentNullable,
  required Expression Function(
    Expression, {
    bool alreadyEncoded,
    bool reserved,
  })
  toForm,
  required bool allowReserved,
}) {
  final resolved = contentModel.resolved;

  if (resolved is StringModel && !isContentNullable) {
    return toForm(receiver, reserved: allowReserved);
  }

  // The base64 string still needs URI-encoding, so it is not passed as
  // alreadyEncoded.
  if (resolved is Base64Model && !isContentNullable) {
    final mapped = receiver
        .property('map')
        .call([
          Method(
            (b) => b
              ..requiredParameters.add(Parameter((p) => p..name = 'e'))
              ..body = refer('e').property('toBase64String').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
    return toForm(mapped, reserved: allowReserved);
  }

  final encodedElements = _buildEncodedElementsList(
    receiver,
    contentModel,
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    isContentNullable: isContentNullable,
    allowReserved: allowReserved,
  );
  if (encodedElements == null) return null;

  return toForm(encodedElements, alreadyEncoded: true);
}

Expression? _buildEncodedElementsList(
  Expression receiver,
  Model contentModel, {
  required Expression allowEmpty,
  required Expression? useQueryComponent,
  required bool isContentNullable,
  required bool allowReserved,
}) {
  if (!_isUriEncodableElement(contentModel)) return null;

  final element = buildUriEncodeExpression(
    refer('e'),
    contentModel,
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: allowReserved ? literalBool(true) : null,
  ).expression;

  final elementEncode = isContentNullable
      ? refer('e')
            .equalTo(literalNull)
            .conditional(literalString(''), element)
      : element;

  return receiver
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = elementEncode.code,
        ).closure,
      ])
      .property('toList')
      .call([]);
}

/// Complex elements (objects, nested lists, complex maps) are excluded because
/// they would otherwise yield an ambiguous `List<Never>.toForm` call.
@visibleForTesting
bool isUriEncodableElement(Model model) => _isUriEncodableElement(model);

bool _isUriEncodableElement(Model model) {
  return switch (model) {
    StringModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    EnumModel() ||
    Base64Model() ||
    AnyModel() ||
    AnyOfModel() ||
    OneOfModel() ||
    AllOfModel() => true,
    AliasModel(:final model) => _isUriEncodableElement(model),
    _ => false,
  };
}

bool isAnyModelFormValue(Model model) => model.resolved is AnyModel;

/// An empty-name entry denotes a bare value with no `name=` prefix.
Expression formEntryToWireString() => Method(
  (b) => b
    ..lambda = true
    ..requiredParameters.add(Parameter((p) => p..name = 'e'))
    ..body = const Code(r"e.name.isEmpty ? e.value : '${e.name}=${e.value}'"),
).closure;

String? formEntriesUnsupportedReason(Model model) {
  if (model is NeverModel) {
    return 'Cannot encode NeverModel - this type does not permit any value.';
  }
  if (model is BinaryModel) {
    return 'Binary data cannot be form-encoded.';
  }
  if (model is ListModel) {
    final content = model.content.resolved;
    if (content is NeverModel) {
      return 'Cannot encode List<NeverModel> - '
          'this type does not permit any value.';
    }
    if (content is BinaryModel) {
      return 'Binary data cannot be form-encoded.';
    }
  }
  return null;
}
