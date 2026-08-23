import 'package:openwps/storage/local_document_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_docs_benchmark';
  }
}

void main() async {
  PathProviderPlatform.instance = MockPathProviderPlatform();

  final dir = Directory('./test_docs_benchmark');
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }

  final storage = LocalDocumentStorage();

  print('Creating 500 documents...');
  for (int i = 0; i < 500; i++) {
    await storage.createDocument('Doc $i');
  }

  print('Benchmarking listDocuments()...');

  // Warmup
  await storage.listDocuments();

  final sw = Stopwatch()..start();
  for (int i = 0; i < 10; i++) {
    await storage.listDocuments();
  }
  sw.stop();

  print('Baseline: ${sw.elapsedMilliseconds} ms for 10 iterations (avg ${sw.elapsedMilliseconds / 10} ms per call)');

  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}
