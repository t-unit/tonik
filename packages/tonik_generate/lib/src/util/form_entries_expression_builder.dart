import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

/// Builds an expression producing `List<ParameterEntry>` for [model] in the
/// form encoding style, or null when the model cannot be form-encoded as a
/// list of entries.
///
/// Form query strings, cookies, and urlencoded bodies are all a list of
/// `name=value` entries that differ only in their join separator, so they
/// share this builder. The throwing cases (never/binary/complex map) and the
/// `AnyModel` single-string path are handled by each caller, which use
/// context-specific wording.
///
/// [paramName], [explode], [allowEmpty] and [useQueryComponent] are expressions
/// so the same builder serves call sites with literal arguments
/// (query/cookie/body) and composite variant arms that thread runtime
/// parameters. A null [useQueryComponent] omits the argument entirely.
Expression? buildFormEntriesValueExpression(
  Expression receiver,
  Model model, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  final toFormArgs = <String, Expression>{
    'explode': explode,
    'allowEmpty': allowEmpty,
    'useQueryComponent': ?useQueryComponent,
  };

  Expression toForm(Expression target, {bool alreadyEncoded = false}) =>
      target.property('toForm').call(
        [paramName],
        {
          ...toFormArgs,
          if (alreadyEncoded) 'alreadyEncoded': literalBool(true),
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
    case EnumModel():
    case ClassModel():
    case AllOfModel():
    case OneOfModel():
    case AnyOfModel():
      return toForm(receiver);

    case Base64Model():
      return toForm(receiver.property('toBase64String').call([]));

    case MapModel():
      final converted = buildMapToStringMapExpression(
        receiver,
        model,
        isNullable: false,
      );
      if (converted == null) return null;
      // Non-string maps are converted with `.toString()`/`.toJson()`, not
      // URI-encoded, so the Map extension must still encode them.
      return toForm(converted);

    case ListModel(:final content):
      return _buildListFormEntriesExpression(
        receiver,
        content,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        isContentNullable: content.isEffectivelyNullable,
        toForm: toForm,
      );

    case AliasModel():
      return buildFormEntriesValueExpression(
        receiver,
        model.model,
        paramName: paramName,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      );

    case NeverModel():
    case BinaryModel():
    case AnyModel():
      return null;

    // Required: the `NamedModel`/`CompositeModel` mixins keep the sealed
    // hierarchy non-exhaustive for switch flow analysis.
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
  required Expression Function(Expression, {bool alreadyEncoded}) toForm,
}) {
  final resolved = contentModel.resolved;

  // List<String> is already a list of values the extension can encode.
  if (resolved is StringModel && !isContentNullable) {
    return toForm(receiver);
  }

  // Base64 content maps to its base64 string, which the extension still needs
  // to URI-encode; everything else is mapped through uriEncode first.
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
    return toForm(mapped);
  }

  final encodedElements = _buildEncodedElementsList(
    receiver,
    contentModel,
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    isContentNullable: isContentNullable,
  );
  if (encodedElements == null) return null;

  return toForm(encodedElements, alreadyEncoded: true);
}

/// Maps a list to `List<String>` where each element is URI-encoded, ready to
/// be passed to the `List<String>.toForm(..., alreadyEncoded: true)`
/// extension. Returns null for content types that cannot be encoded.
Expression? _buildEncodedElementsList(
  Expression receiver,
  Model contentModel, {
  required Expression allowEmpty,
  required Expression? useQueryComponent,
  required bool isContentNullable,
}) {
  if (!_isUriEncodableElement(contentModel)) return null;

  final element = buildUriEncodeExpression(
    refer('e'),
    contentModel,
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
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

/// Whether a list element of type [model] URI-encodes to a single string.
///
/// Mirrors the scalar/any/composite arms of [buildUriEncodeExpression]. Complex
/// elements (objects, nested lists, complex maps) cannot be encoded as a single
/// value and would otherwise yield an ambiguous `List<Never>.toForm` call.
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

/// Whether [model] form-encodes to a single string value (handled by the
/// caller as one entry) rather than a `List<ParameterEntry>`.
bool isAnyModelFormValue(Model model) => model.resolved is AnyModel;

/// Returns the encoding-exception message for a model that cannot be
/// form-encoded as entries, or null when the model is encodable.
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
