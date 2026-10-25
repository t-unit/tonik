import 'package:tonik_parse/src/local_json_pointer.dart';
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
        throw UnimplementedError(
          'Only local media type references are supported, found $ref',
        );
      }
      final pointer = LocalJsonPointer.parse(ref);
      final name = pointer.componentName('mediaTypes');
      if (name == null) {
        throw UnimplementedError(
          'Only components.mediaTypes references are supported, found $ref',
        );
      }
      if (!chain.add(pointer.reference)) {
        throw ArgumentError(
          'Cyclic media type reference: ${[...chain, ref].join(" -> ")}',
        );
      }
      final target = openApiObject.components?.mediaTypes?[name];
      if (target == null) {
        throw ArgumentError('Media type $ref not found');
      }
      current = target;
    }
    return (current as InlinedObject<MediaType>).object;
  }
}
