import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/local_document_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_spreadsheets';
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('create, get, and delete spreadsheet', () async {
    final storage = LocalDocumentStorage();
    final doc = await storage.createSpreadsheet('Test Sheet');

    expect(doc.title, 'Test Sheet');
    expect(doc.id, isNotEmpty);
    expect(doc.sheets.length, 1);

    final fetched = await storage.getSpreadsheet(doc.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, doc.id);

    await storage.deleteSpreadsheet(doc.id);
    final fetchedAfterDelete = await storage.getSpreadsheet(doc.id);
    expect(fetchedAfterDelete, isNull);
  });
}
