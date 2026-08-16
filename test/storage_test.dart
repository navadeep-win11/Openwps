import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/local_document_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_docs';
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('create, get, and delete document', () async {
    final storage = LocalDocumentStorage();
    final doc = await storage.createDocument('Test Doc');

    expect(doc.title, 'Test Doc');
    expect(doc.id, isNotEmpty);

    final fetched = await storage.getDocument(doc.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, doc.id);

    await storage.deleteDocument(doc.id);
    final fetchedAfterDelete = await storage.getDocument(doc.id);
    expect(fetchedAfterDelete, isNull);
  });
}
