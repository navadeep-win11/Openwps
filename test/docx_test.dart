import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/local_document_storage.dart';
import 'package:openwps/features/writer/docx/docx_exporter.dart';
import 'package:openwps/features/writer/docx/docx_importer.dart';
import 'package:archive/archive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_docs';
  }
  @override
  Future<String?> getTemporaryPath() async {
    return './test_docs/temp';
  }
}

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    final tempDir = Directory('./test_docs/temp');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);
  });

  tearDownAll(() async {
    final docsDir = Directory('./test_docs');
    if (await docsDir.exists()) await docsDir.delete(recursive: true);
  });

  test('DOCX basic text export and import round-trip', () async {
    final storage = LocalDocumentStorage();
    final doc = await storage.createDocument('RoundTripTest');

    // Set up some simple text content
    final content = [
      {"insert": "Hello "},
      {"insert": "bold", "attributes": {"bold": true}},
      {"insert": "\n"}
    ];

    final updatedDoc = doc.copyWith(content: jsonEncode(content));

    final exportPath = './test_docs/RoundTripTest.docx';
    final exportedFile = await DocxExporter.exportDocument(updatedDoc, exportPath);

    expect(await exportedFile.exists(), true);

    // Now import it back
    final importedDoc = await DocxImporter.importDocument(exportedFile, storage);
    expect(importedDoc, isNotNull);

    final importedContent = jsonDecode(importedDoc!.content) as List<dynamic>;

    // We expect the importer to read "Hello " and "bold"
    bool foundHello = false;
    bool foundBold = false;
    for (final op in importedContent) {
      if (op['insert'] == 'Hello ') foundHello = true;
      if (op['insert'] == 'bold' && op['attributes'] != null && op['attributes']['bold'] == true) {
        foundBold = true;
      }
    }

    expect(foundHello, true);
    expect(foundBold, true);
  });

  test('DOCX gracefully handles corrupted file import', () async {
    final storage = LocalDocumentStorage();
    final badFile = File('./test_docs/bad.docx');
    await badFile.writeAsString('not a real zip file');

    final importedDoc = await DocxImporter.importDocument(badFile, storage);
    expect(importedDoc, isNull);
  });

  test('DOCX returns null when reading a non-existent file', () async {
    final storage = LocalDocumentStorage();
    final nonExistentFile = File('./test_docs/does_not_exist.docx');

    final importedDoc = await DocxImporter.importDocument(nonExistentFile, storage);
    expect(importedDoc, isNull);
  });

  test('DOCX returns null when zip archive lacks word/document.xml', () async {
    final storage = LocalDocumentStorage();

    // Create a valid zip file without word/document.xml
    final archive = Archive();
    archive.addFile(ArchiveFile('dummy.txt', 12, utf8.encode('Hello World!')));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final noDocXmlFile = File('./test_docs/no_doc_xml.docx');
    await noDocXmlFile.writeAsBytes(zipData!);

    final importedDoc = await DocxImporter.importDocument(noDocXmlFile, storage);
    expect(importedDoc, isNull);
  });
}
