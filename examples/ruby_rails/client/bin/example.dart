import 'package:ruby_rails_api/ruby_rails_api.dart';
import 'package:ruby_rails_example/live.dart';
import 'package:tonik_util/tonik_util.dart';

Future<void> main() async {
  final server = liveServer();
  final api = CatalogApi(server);
  try {
    final product = success(await api.jsonProduct());
    print('${product.customer.name} ordered ${product.name}.');
    final upload = success(
      await api.upload(
        body: UploadFields(
          file: TonikFileBytes([0, 1, 127, 128, 255], fileName: 'sample.bin'),
          text: 'café + tea & milk',
          count: 2,
          enabled: true,
        ),
      ),
    );
    print('Received ${upload.fileName}: ${upload.bytes}');
  } finally {
    server.close();
  }
}
