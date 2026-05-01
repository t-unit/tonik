import 'package:code_builder/code_builder.dart';

/// Per-encoding-style policy for emitting `AnyModel` arms.
///
/// Centralizes the choice of runtime helper for each encoding style so that
/// every value-level and parameter-level generator routes through one table.
/// Adding a new style or fixing an edge case is a single edit point here.
class EncodingPolicy {
  const EncodingPolicy({required this.encodeAny});

  final Expression Function(Expression receiver) encodeAny;
}

EncodingPolicy jsonEncodingPolicy() {
  return EncodingPolicy(
    encodeAny: (receiver) => refer(
      'encodeAnyToJson',
      'package:tonik_util/tonik_util.dart',
    ).call([receiver]),
  );
}

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
  );
}

/// When [useQueryComponent] is non-null, it is forwarded to the runtime helper
/// so primitives use `Uri.encodeQueryComponent` (spaces → `+`) instead of
/// `Uri.encodeComponent` (spaces → `%20`).
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
  );
}

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
  );
}

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
  );
}
