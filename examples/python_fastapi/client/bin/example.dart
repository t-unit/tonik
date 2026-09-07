import 'package:python_fastapi_api/python_fastapi_api.dart';
import 'package:python_fastapi_example/live.dart';
import 'package:tonik_util/tonik_util.dart';

Future<void> main() async {
  final server = liveServer();
  final api = CatalogApi(server);
  try {
    final product = success(await api.jsonProduct());
    print('${product.customer.name} ordered ${product.name}.');
    final upload = success(
      await api.upload(
        body: BodyUpload(
          file: TonikFileBytes([0, 1, 127, 128, 255], fileName: 'sample.bin'),
          text: 'café + tea & milk',
          count: 2,
          enabled: true,
        ),
      ),
    ) as UploadResponse200;
    print('Received ${upload.body.fileName}: ${upload.body.bytes}');
  } finally {
    server.close();
  }
}
