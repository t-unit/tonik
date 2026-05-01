/// Builders for code_builder Expressions that call into the encodeAnyTo*
/// runtime helpers in tonik_util. Centralizes the runtime-helper URI and
/// call shape so generators don't refer('encodeAnyTo*') directly.
library;

import 'package:code_builder/code_builder.dart';

const _utilUri = 'package:tonik_util/tonik_util.dart';

Expression encodeAnyToJsonExpression(Expression receiver) =>
    refer('encodeAnyToJson', _utilUri).call([receiver]);

Expression encodeAnyToSimpleExpression(
  Expression receiver, {
  required Expression explode,
  required Expression allowEmpty,
}) => refer('encodeAnyToSimple', _utilUri).call(
  [receiver],
  {'explode': explode, 'allowEmpty': allowEmpty},
);

/// When [useQueryComponent] is non-null, it is forwarded to the runtime helper
/// so primitives use `Uri.encodeQueryComponent` (spaces → `+`) instead of
/// `Uri.encodeComponent` (spaces → `%20`). The choice threads through
/// recursive list/map element encoding.
Expression encodeAnyToFormExpression(
  Expression receiver, {
  required Expression explode,
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) => refer('encodeAnyToForm', _utilUri).call(
  [receiver],
  {
    'explode': explode,
    'allowEmpty': allowEmpty,
    'useQueryComponent': ?useQueryComponent,
  },
);

Expression encodeAnyToMatrixExpression(
  Expression receiver, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
}) => refer('encodeAnyToMatrix', _utilUri).call(
  [receiver, paramName],
  {'explode': explode, 'allowEmpty': allowEmpty},
);

Expression encodeAnyToLabelExpression(
  Expression receiver, {
  required Expression explode,
  required Expression allowEmpty,
}) => refer('encodeAnyToLabel', _utilUri).call(
  [receiver],
  {'explode': explode, 'allowEmpty': allowEmpty},
);

/// When [useQueryComponent] is non-null, it is forwarded to the runtime helper
/// so primitives use `Uri.encodeQueryComponent` (spaces → `+`) instead of
/// `Uri.encodeComponent` (spaces → `%20`).
Expression encodeAnyToUriExpression(
  Expression receiver, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) => refer('encodeAnyToUri', _utilUri).call(
  [receiver],
  {
    'allowEmpty': allowEmpty,
    'useQueryComponent': ?useQueryComponent,
  },
);

Expression encodeAnyToDeepObjectExpression(
  Expression receiver, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
}) => refer('encodeAnyToDeepObject', _utilUri).call(
  [receiver, paramName],
  {'explode': explode, 'allowEmpty': allowEmpty},
);
