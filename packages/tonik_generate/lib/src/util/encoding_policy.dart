import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Per-encoding-style policy for emitting `AnyModel` and `NeverModel` arms.
///
/// Centralizes the choice of runtime helper for each encoding style so that
/// every value-level and parameter-level generator routes through one table.
/// Adding a new style or fixing an edge case is a single edit point here.
///
/// The closure-based shape lets each style express its own runtime-helper
/// signature (matrix's `paramName`, simple/form/label/matrix's
/// `explode`/`allowEmpty`) without leaking per-style arms back into call
/// sites.
class EncodingPolicy {
  const EncodingPolicy({required this.encodeAny, required this.neverThrow});

  /// Builds the expression that encodes an `AnyModel` value via the
  /// runtime helper configured for the chosen encoding style.
  final Expression Function(Expression receiver) encodeAny;

  /// Builds a throw expression for `NeverModel` values that carry no
  /// per-site context.
  ///
  /// Reserved for an upcoming consolidation that will route every
  /// `NeverModel` arm through this policy as well; not yet wired into call
  /// sites, which continue to inline the literal throw at each `NeverModel`
  /// arm.
  final Expression Function() neverThrow;
}

/// Standard message used by every catch-all NeverModel encoding throw.
const String _neverModelMessage =
    'Cannot encode NeverModel - this type does not permit any value.';

Expression _neverThrow() =>
    generateEncodingExceptionExpression(_neverModelMessage);

/// Policy that routes `AnyModel` JSON encoding through `encodeAnyToJson`.
EncodingPolicy jsonEncodingPolicy() {
  return EncodingPolicy(
    encodeAny: (receiver) => refer(
      'encodeAnyToJson',
      'package:tonik_util/tonik_util.dart',
    ).call([receiver]),
    neverThrow: _neverThrow,
  );
}

/// Policy that routes `AnyModel` simple-style encoding through
/// `encodeAnyToSimple` with the supplied [explode] and [allowEmpty]
/// arguments.
EncodingPolicy simpleEncodingPolicy({
  required Expression explode,
  required Expression allowEmpty,
}) {
  return EncodingPolicy(
    encodeAny: (receiver) =>
        refer('encodeAnyToSimple', 'package:tonik_util/tonik_util.dart').call(
          [receiver],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    neverThrow: _neverThrow,
  );
}

/// Policy that routes `AnyModel` form-style encoding through
/// `encodeAnyToForm` with the supplied [explode] and [allowEmpty]
/// arguments.
///
/// When [useQueryComponent] is non-null, it is forwarded to the runtime
/// helper so that primitives use `Uri.encodeQueryComponent` (spaces → `+`)
/// instead of `Uri.encodeComponent` (spaces → `%20`). Generators that emit
/// form-urlencoded request bodies pass `literalBool(true)`; generators that
/// emit form-style query parameters omit the argument.
EncodingPolicy formEncodingPolicy({
  required Expression explode,
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  return EncodingPolicy(
    encodeAny: (receiver) =>
        refer('encodeAnyToForm', 'package:tonik_util/tonik_util.dart').call(
          [receiver],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'useQueryComponent': ?useQueryComponent,
          },
        ),
    neverThrow: _neverThrow,
  );
}

/// Policy that routes `AnyModel` matrix-style encoding through
/// `encodeAnyToMatrix` with the supplied [paramName], [explode], and
/// [allowEmpty] arguments.
EncodingPolicy matrixEncodingPolicy({
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
}) {
  return EncodingPolicy(
    encodeAny: (receiver) =>
        refer('encodeAnyToMatrix', 'package:tonik_util/tonik_util.dart').call(
          [receiver, paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    neverThrow: _neverThrow,
  );
}

/// Policy that routes `AnyModel` label-style encoding through
/// `encodeAnyToLabel` with the supplied [explode] and [allowEmpty]
/// arguments.
EncodingPolicy labelEncodingPolicy({
  required Expression explode,
  required Expression allowEmpty,
}) {
  return EncodingPolicy(
    encodeAny: (receiver) =>
        refer('encodeAnyToLabel', 'package:tonik_util/tonik_util.dart').call(
          [receiver],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    neverThrow: _neverThrow,
  );
}
