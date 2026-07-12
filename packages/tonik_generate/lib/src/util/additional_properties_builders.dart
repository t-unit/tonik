import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/property_value_expression_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Everything the shared additional-properties builders need for one
/// entries owner: a pure map, a mixed class, or the selected allOf owner.
///
/// The builders depend only on [valueModel] and the codec plans; they do not
/// know which kind of owner is calling. Unrestricted additional properties
/// are simply a plan whose [valueModel] is [AnyModel].
final class AdditionalPropertiesPlan {
  const AdditionalPropertiesPlan({
    required this.valueModel,
    required this.knownWireKeys,
    this.fieldName,
  });

  final Model valueModel;

  /// Declared wire keys: excluded from decode capture and rejected when a
  /// user-constructed value tries to encode them as additional properties.
  final Set<String> knownWireKeys;

  /// Generated additional-properties field name; null when the receiver
  /// itself is the entries map.
  final String? fieldName;
}

/// Statements produced by a shared builder plus any inline helpers they need.
final class ApBuilderResult {
  const ApBuilderResult({
    required this.codes,
    this.inlineHelpers = const [],
    this.capturesValues = true,
  });

  final List<Code> codes;
  final List<InlineHelper> inlineHelpers;

  /// Whether the emitted decode capture fills a `_$additional` map. False
  /// when the value model cannot be decoded and unknown keys throw instead.
  final bool capturesValues;
}

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

/// The active (explicit) allowed policy of [policy], or null when no
/// additional-properties surface is generated.
AllowedAdditionalProperties? activeApPolicy(AdditionalPropertiesPolicy policy) {
  if (policy is AllowedAdditionalProperties &&
      policy.origin == AdditionalPropertiesOrigin.explicit) {
    return policy;
  }
  return null;
}

/// `Map<String, V>` (or `IMap`) type for the additional-properties field of
/// [valueModel].
TypeReference apMapTypeReference(
  Model valueModel,
  NameManager nameManager,
  String package, {
  bool useImmutableCollections = false,
}) => TypeReference(
  (b) => b
    ..symbol = useImmutableCollections ? 'IMap' : 'Map'
    ..url = useImmutableCollections ? _ficUrl : 'dart:core'
    ..types.addAll([
      refer('String', 'dart:core'),
      apValueTypeReference(
        valueModel,
        nameManager,
        package,
        useImmutableCollections: useImmutableCollections,
      ),
    ]),
);

/// `Map<String, V>` value type for the additional-properties entries of
/// [valueModel]; [AnyModel] values map to `Object?`.
Reference apValueTypeReference(
  Model valueModel,
  NameManager nameManager,
  String package, {
  bool useImmutableCollections = false,
}) {
  if (valueModel.resolved is AnyModel) {
    return refer('Object?', 'dart:core');
  }
  return typeReference(
    valueModel,
    nameManager,
    package,
    useImmutableCollections: useImmutableCollections,
  );
}

/// JSON decode capture: fills `_$additional` from [sourceMapVar], excluding
/// [AdditionalPropertiesPlan.knownWireKeys].
ApBuilderResult buildApJsonCaptureLoop(
  AdditionalPropertiesPlan plan, {
  required String sourceMapVar,
  required NameManager nameManager,
  required String package,
  required String contextClass,
  InlineHelperContext? helperContext,
  bool useImmutableCollections = false,
}) {
  final codes = <Code>[
    ..._knownKeysConst(plan),
    declareFinal(r'_$additional')
        .assign(
          literalMap(
            {},
            refer('String', 'dart:core'),
            apValueTypeReference(
              plan.valueModel,
              nameManager,
              package,
              useImmutableCollections: useImmutableCollections,
            ),
          ),
        )
        .statement,
    Code('for (final _\$entry in $sourceMapVar.entries) {'),
    ..._exclusionOpen(plan),
  ];

  final helpers = <InlineHelper>[];
  if (plan.valueModel.resolved is AnyModel) {
    codes.add(const Code(r'_$additional[_$entry.key] = _$entry.value;'));
  } else {
    final decodeBuilt = buildFromJsonValueExpression(
      r'_$entry.value',
      model: plan.valueModel,
      nameManager: nameManager,
      package: package,
      helperContext: helperContext,
      contextClass: contextClass,
      contextProperty: 'additionalProperties',
      useImmutableCollections: useImmutableCollections,
    );
    helpers.addAll(decodeBuilt.inlineFunctions);
    codes.addAll([
      const Code(r'_$additional[_$entry.key] = '),
      decodeBuilt.unsafeRawBody.code,
      const Code(';'),
    ]);
  }

  codes.addAll([..._exclusionClose(plan), const Code('}')]);
  return ApBuilderResult(codes: codes, inlineHelpers: helpers);
}

/// JSON encode: rejects declared-key collisions, then adds all encoded
/// additional-property values to [targetMapVar].
ApBuilderResult buildApJsonEncode(
  AdditionalPropertiesPlan plan, {
  required String targetMapVar,
  required String apAccess,
  required NameManager nameManager,
  required String package,
  required String contextClass,
  InlineHelperContext? helperContext,
  bool useImmutableCollections = false,
}) {
  final codes = <Code>[
    ..._collisionGuard(plan, apAccess: apAccess, contextClass: contextClass),
  ];

  final encoded = buildToJsonAdditionalPropertiesExpression(
    apAccess,
    plan.valueModel,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    contextClass: contextClass,
    useImmutableCollections: useImmutableCollections,
  );

  codes.add(
    refer(targetMapVar)
        .property('addAll')
        .call([encoded.unsafeRawBody])
        .statement,
  );
  return ApBuilderResult(codes: codes, inlineHelpers: encoded.inlineFunctions);
}

/// Simple/form decode capture through the flat decode plan.
///
/// When the value model has no flat decoding, unknown keys throw a
/// context-bearing decoding exception instead of being silently dropped.
ApBuilderResult buildApFlatCaptureLoop(
  AdditionalPropertiesPlan plan, {
  required FlatWireFormat format,
  required String sourceMapVar,
  required NameManager nameManager,
  required String package,
  required String contextClass,
  bool useImmutableCollections = false,
}) {
  final decodePlan = buildFlatDecodePlan(
    refer(r'_$entry').property('value'),
    plan.valueModel,
    format: format,
    isRequired: true,
    nameManager: nameManager,
    explode: refer('explode'),
    package: package,
    contextClass: contextClass,
    contextProperty: 'additionalProperties',
  );

  if (decodePlan is UnsupportedFlatDecodePlan) {
    final throwExpression = switch (format) {
      FlatWireFormat.simple => generateSimpleDecodingExceptionExpression(
        '${decodePlan.reason} at $contextClass.additionalProperties',
        raw: true,
      ),
      FlatWireFormat.form => generateFormDecodingExceptionExpression(
        '${decodePlan.reason} at $contextClass.additionalProperties',
        raw: true,
      ),
    };
    return ApBuilderResult(
      capturesValues: false,
      codes: [
        ..._knownKeysConst(plan),
        Code('for (final _\$entry in $sourceMapVar.entries) {'),
        ..._exclusionOpen(plan),
        throwExpression.statement,
        ..._exclusionClose(plan),
        const Code('}'),
      ],
    );
  }

  final decodeExpression = switch (decodePlan) {
    FlatScalarDecodePlan(:final value) => value,
    FlatArrayDecodePlan(:final value) =>
      useImmutableCollections ? value.property('lock') : value,
    UnsupportedFlatDecodePlan() => throw StateError('handled above'),
  };

  return ApBuilderResult(
    codes: [
      ..._knownKeysConst(plan),
      declareFinal(r'_$additional')
          .assign(
            literalMap(
              {},
              refer('String', 'dart:core'),
              apValueTypeReference(
                plan.valueModel,
                nameManager,
                package,
                useImmutableCollections: useImmutableCollections,
              ),
            ),
          )
          .statement,
      Code('for (final _\$entry in $sourceMapVar.entries) {'),
      ..._exclusionOpen(plan),
      const Code(r'_$additional[_$entry.key] = '),
      decodeExpression.code,
      const Code(';'),
      ..._exclusionClose(plan),
      const Code('}'),
    ],
  );
}

/// `Map<String, PropertyValue>` entries for flat parameter and form
/// encoding: rejects declared-key collisions, omits null (RFC 6570
/// undefined) entries, and converts defined values through the flat encode
/// plan. Unsupported value models throw before any entry is produced.
ApBuilderResult buildApPropertyValueEntries(
  AdditionalPropertiesPlan plan, {
  required String targetVar,
  required String apAccess,
  required String contextClass,
  bool useImmutableCollections = false,
}) {
  final context = '$contextClass.additionalProperties';
  final valueModel = plan.valueModel;
  final omitsNull =
      valueModel.isEffectivelyNullable || valueModel.resolved is AnyModel;
  final receiver = omitsNull ? refer(r'_$v') : refer(r'_$e').property('value');

  final encodePlan = buildFlatEncodePlan(
    receiver,
    valueModel,
    context: context,
    useImmutableCollections: useImmutableCollections,
  );

  if (encodePlan is UnsupportedFlatEncodePlan) {
    return ApBuilderResult(
      capturesValues: false,
      codes: [
        Code('if ($apAccess.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          '${encodePlan.reason} at $context',
          raw: true,
        ).statement,
        const Code('}'),
      ],
    );
  }

  final entryValue = switch (encodePlan) {
    FlatScalarEncodePlan(:final value) => propertyValueScalar(value),
    FlatArrayEncodePlan(:final values) => propertyValueArray(values),
    UnsupportedFlatEncodePlan() => throw StateError('handled above'),
  };

  return ApBuilderResult(
    codes: [
      ..._knownKeysConst(plan),
      Code('for (final _\$e in $apAccess.entries) {'),
      ..._collisionThrowInLoop(plan, contextClass: contextClass),
      if (omitsNull) ...[
        declareFinal(r'_$v').assign(refer(r'_$e').property('value')).statement,
        const Code(r'if (_$v == null) continue;'),
      ],
      refer(targetVar)
          .index(refer(r'_$e').property('key'))
          .assign(entryValue)
          .statement,
      const Code('}'),
    ],
  );
}

List<Code> _knownKeysConst(AdditionalPropertiesPlan plan) {
  if (plan.knownWireKeys.isEmpty) return const [];
  final keys = plan.knownWireKeys.map(specLiteralStringCode).join(', ');
  return [Code('const _\$knownKeys = {$keys};')];
}

List<Code> _exclusionOpen(AdditionalPropertiesPlan plan) {
  if (plan.knownWireKeys.isEmpty) return const [];
  return [const Code(r'if (!_$knownKeys.contains(_$entry.key)) {')];
}

List<Code> _exclusionClose(AdditionalPropertiesPlan plan) {
  if (plan.knownWireKeys.isEmpty) return const [];
  return [const Code('}')];
}

List<Code> _collisionGuard(
  AdditionalPropertiesPlan plan, {
  required String apAccess,
  required String contextClass,
}) {
  if (plan.knownWireKeys.isEmpty) return const [];
  return [
    ..._knownKeysConst(plan),
    Code('for (final _\$k in $apAccess.keys) {'),
    const Code(r'if (_$knownKeys.contains(_$k)) {'),
    generateEncodingExceptionExpression(
      _collisionMessage(contextClass),
      raw: true,
    ).statement,
    const Code('}'),
    const Code('}'),
  ];
}

List<Code> _collisionThrowInLoop(
  AdditionalPropertiesPlan plan, {
  required String contextClass,
}) {
  if (plan.knownWireKeys.isEmpty) return const [];
  return [
    const Code(r'if (_$knownKeys.contains(_$e.key)) {'),
    generateEncodingExceptionExpression(
      _collisionMessage(contextClass),
      raw: true,
    ).statement,
    const Code('}'),
  ];
}

String _collisionMessage(String contextClass) =>
    'Additional property keys must not collide with declared wire keys '
    'of $contextClass';
