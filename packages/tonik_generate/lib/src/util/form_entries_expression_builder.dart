import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
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
  }) => target.property('toForm').call(
    [paramName],
    {
      ...toFormArgs,
      if (alreadyEncoded) 'alreadyEncoded': literalBool(true),
      if (reserved) 'allowReserved': literalBool(true),
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

    // The generated toForm for enums and compositions has no allowReserved
    // parameter, so the flag is deferred for these types — threading it would
    // not compile.
    case EnumModel():
    case ClassModel():
    case AllOfModel():
    case OneOfModel():
    case AnyOfModel():
      return toForm(receiver);

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

/// Gates the per-property form-body path, which only an `allowReserved` flag
/// needs. It stays on the byte-identical object-level `body.toForm()` path
/// unless a writable, emitted property of [model] carries the flag — a flag on
/// a read-only property or an unmatched key has no emitted effect.
bool formBodyHasAllowReserved(
  Map<String, PropertyEncoding>? encoding,
  ClassModel model,
) {
  if (encoding == null) return false;
  final emittedNames = {
    for (final property in model.properties)
      if (!property.isReadOnly) property.name,
  };
  return encoding.entries.any(
    (e) => (e.value.allowReserved ?? false) && emittedNames.contains(e.key),
  );
}

/// Emits form entries one property at a time so a mix of per-property
/// `allowReserved` flags is honored — the object-level `toForm` encodes every
/// property uniformly and cannot express the mix. On success `entries` holds
/// the list expression; when a property model is not form-encodable
/// per-property, `unencodableProperty` names it so the caller can surface an
/// `EncodingException` rather than falling back to a path that would silently
/// drop `allowReserved` from a sibling that opted in.
({Expression? entries, String? unencodableProperty})
buildClassFormEntriesExpression(
  Expression receiver,
  ClassModel model,
  Map<String, PropertyEncoding>? encoding,
) {
  final writeProperties = model.properties
      .where((p) => !p.isReadOnly)
      .toList();
  final normalizedProps = normalizeProperties(writeProperties);

  final propertyCodes = <Code>[];
  for (final (:normalizedName, :property) in normalizedProps) {
    final entryCodes = _buildPropertyFormEntry(
      receiver.property(normalizedName),
      property,
      encoding?[property.name]?.allowReserved ?? false,
    );
    if (entryCodes == null) {
      return (entries: null, unencodableProperty: property.name);
    }
    propertyCodes.addAll(entryCodes);
  }

  return (
    entries: CodeExpression(
      Block.of([const Code('['), ...propertyCodes, const Code(']')]),
    ),
    unencodableProperty: null,
  );
}

/// Emits the spread/element code for one class property, or null when the
/// property model cannot be encoded per-property. Field nullability mirrors the
/// object path (`class_generator`): a field is nullable when the property is
/// nullable, optional, write-only, or backed by an effectively-nullable model.
List<Code>? _buildPropertyFormEntry(
  Expression field,
  Property property,
  bool allowReserved,
) {
  final propertyNameLiteral = specLiteralString(property.name);
  final resolved = property.model.resolved;

  // Free-form objects encode via encodeAnyToForm, which accepts null and owns
  // its own value encoding, so allowReserved is deferred here as it is for the
  // enum/composition arm of buildFormEntriesValueExpression.
  if (resolved is AnyModel) {
    final value = refer(
      'encodeAnyToForm',
      'package:tonik_util/tonik_util.dart',
    ).call([field], {
      'explode': literalBool(true),
      'allowEmpty': literalBool(true),
      'useQueryComponent': literalBool(true),
    });
    final entry = literalRecord([], {
      'name': propertyNameLiteral,
      'value': value,
    });
    return [entry.code, const Code(',')];
  }

  final isNullable =
      property.isNullable || property.model.isEffectivelyNullable;
  final fieldCanBeNull =
      isNullable || !property.isRequired || property.isWriteOnly;

  final entries = buildFormEntriesValueExpression(
    fieldCanBeNull ? field.nullChecked : field,
    property.model,
    paramName: propertyNameLiteral,
    explode: literalBool(true),
    allowEmpty: literalBool(true),
    useQueryComponent: literalBool(true),
    allowReserved: allowReserved,
  );
  if (entries == null) return null;

  if (!fieldCanBeNull) {
    return [const Code('...'), entries.code, const Code(',')];
  }

  final whenNull = property.isRequired && !isNullable
      ? generateEncodingExceptionExpression(
          'Required property ${property.name} is null.',
          raw: true,
        )
      : literalList([
          literalRecord([], {
            'name': propertyNameLiteral,
            'value': literalString(''),
          }),
        ]);

  return [
    const Code('...('),
    field.notEqualTo(literalNull).code,
    const Code(' ? '),
    entries.code,
    const Code(' : '),
    whenNull.code,
    const Code('),'),
  ];
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
    allowReserved: allowReserved,
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
