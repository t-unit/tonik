import 'package:tonik_util/src/encoding/encoding_exception.dart';

String multipartTextValue(Object? value) => switch (value) {
  final String value => value,
  final num value => value.toString(),
  final bool value => value.toString(),
  _ => throw EncodingException(
    'Cannot encode ${value.runtimeType} as a text/plain multipart part.',
  ),
};
