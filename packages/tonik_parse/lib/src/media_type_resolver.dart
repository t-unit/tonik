import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';

class MediaTypeResolver(final OpenApiObject openApiObject) {
  MediaType resolve(ReferenceWrapper<MediaType> wrapper) {
    final chain = <String>{};
    var current = wrapper;
    while (current is Reference<MediaType>) {
      final ref = current.ref;
      if (isExternalReference(ref)) {
        return MediaType(schema: null, encoding: null);
      }
      final segments = ref.startsWith('#')
          ? Uri.decodeComponent(ref.substring(1))
                .split('/')
                .map(
                  (segment) =>
                      segment.replaceAll('~1', '/').replaceAll('~0', '~'),
                )
                .toList()
          : <String>[];
      if (segments.length != 4 ||
          segments[0].isNotEmpty ||
          segments[1] != 'components' ||
          segments[2] != 'mediaTypes') {
        throw UnimplementedError(
          'Only components.mediaTypes references are supported, found $ref',
        );
      }
      if (!chain.add(ref)) {
        throw ArgumentError(
          'Cyclic media type reference: ${[...chain, ref].join(" -> ")}',
        );
      }
      final name = segments.last;
      final target = openApiObject.components?.mediaTypes?[name];
      if (target == null) {
        throw ArgumentError('Media type $ref not found');
      }
      current = target;
    }
    return (current as InlinedObject<MediaType>).object;
  }
}
