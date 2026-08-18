import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/local_document_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_presentations';
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('create, get, and update presentation', () async {
    final storage = LocalDocumentStorage();
    final doc = await storage.createPresentation('Test Presentation');

    expect(doc.title, 'Test Presentation');
    expect(doc.id, isNotEmpty);
    expect(doc.slides.length, 1);

    final fetched = await storage.getPresentation(doc.id);
    expect(fetched, isNotNull);
    expect(fetched!.slides.first.elements.first.type, 'text');

    fetched.title = 'Updated Title';
    await storage.updatePresentation(fetched);

    final updated = await storage.getPresentation(doc.id);
    expect(updated!.title, 'Updated Title');

    await storage.deletePresentation(doc.id);
  });
}
