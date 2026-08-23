import 'package:flutter_test/flutter_test.dart';
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

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('Benchmark listSpreadsheets', () async {
    final dir = Directory('./test_docs_benchmark');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }

    final storage = LocalDocumentStorage();

    print('Creating 500 spreadsheets...');
    for (int i = 0; i < 500; i++) {
      await storage.createSpreadsheet('Spreadsheet $i');
    }

    print('Benchmarking listSpreadsheets()...');

    // Warmup
    await storage.listSpreadsheets();

    final sw = Stopwatch()..start();
    for (int i = 0; i < 10; i++) {
      await storage.listSpreadsheets();
    }
    sw.stop();

    print('Baseline listSpreadsheets: ${sw.elapsedMilliseconds} ms for 10 iterations (avg ${sw.elapsedMilliseconds / 10} ms per call)');

    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
}
