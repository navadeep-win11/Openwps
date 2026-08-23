import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/features/writer/docx/docx_importer.dart';
import 'package:openwps/storage/document_storage.dart';
import 'package:openwps/storage/models/presentation_document.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';
import 'package:openwps/storage/models/writer_document.dart';
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

class MockDocumentStorage implements DocumentStorage {
  final Map<String, WriterDocument> _documents = {};
  int _createCount = 0;
  final List<String> savedImages = [];

  @override
  Future<WriterDocument> createDocument(String title) async {
    _createCount++;
    final id = 'mock-doc-$_createCount';
    final doc = WriterDocument(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: '[]',
    );
    _documents[id] = doc;
    return doc;
  }

  @override
  Future<WriterDocument?> getDocument(String id) async {
    return _documents[id];
  }

  @override
  Future<void> updateDocument(WriterDocument document) async {
    _documents[document.id] = document;
  }

  @override
  Future<String> saveImage(String documentId, String tempImagePath) async {
    savedImages.add(tempImagePath);
    return 'mock-path-for-$documentId';
  }

  // Unimplemented mock methods
  @override Future<void> deleteDocument(String id) async {}
  @override Future<void> duplicateDocument(String id) async {}
  @override Future<List<WriterDocument>> listDocuments() async => _documents.values.toList();
  @override Future<List<WriterDocument>> recentDocuments() async => [];
  @override Future<void> renameDocument(String id, String newTitle) async {}
  @override Future<List<WriterDocument>> searchDocuments(String query) async => [];
  @override Future<void> toggleFavorite(String id) async {}

  @override Future<SpreadsheetDocument> createSpreadsheet(String title) { throw UnimplementedError(); }
  @override Future<void> deleteSpreadsheet(String id) { throw UnimplementedError(); }
  @override Future<void> duplicateSpreadsheet(String id) { throw UnimplementedError(); }
  @override Future<SpreadsheetDocument?> getSpreadsheet(String id) { throw UnimplementedError(); }
  @override Future<List<SpreadsheetDocument>> listSpreadsheets() { throw UnimplementedError(); }
  @override Future<List<SpreadsheetDocument>> recentSpreadsheets() { throw UnimplementedError(); }
  @override Future<void> renameSpreadsheet(String id, String newTitle) { throw UnimplementedError(); }
  @override Future<List<SpreadsheetDocument>> searchSpreadsheets(String query) { throw UnimplementedError(); }
  @override Future<void> toggleSpreadsheetFavorite(String id) { throw UnimplementedError(); }
  @override Future<void> updateSpreadsheet(SpreadsheetDocument document) { throw UnimplementedError(); }

  @override Future<PresentationDocument> createPresentation(String title) { throw UnimplementedError(); }
  @override Future<void> deletePresentation(String id) { throw UnimplementedError(); }
  @override Future<void> duplicatePresentation(String id) { throw UnimplementedError(); }
  @override Future<PresentationDocument?> getPresentation(String id) { throw UnimplementedError(); }
  @override Future<List<PresentationDocument>> listPresentations() { throw UnimplementedError(); }
  @override Future<List<PresentationDocument>> recentPresentations() { throw UnimplementedError(); }
  @override Future<void> renamePresentation(String id, String newTitle) { throw UnimplementedError(); }
  @override Future<List<PresentationDocument>> searchPresentations(String query) { throw UnimplementedError(); }
  @override Future<void> togglePresentationFavorite(String id) { throw UnimplementedError(); }
  @override Future<void> updatePresentation(PresentationDocument document) { throw UnimplementedError(); }
}

Future<File> createMockDocx({
  required String path,
  String? documentXml,
  String? relsXml,
  Map<String, List<int>> media = const {},
}) async {
  final archive = Archive();

  if (documentXml != null) {
    final bytes = utf8.encode(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
  }
  if (relsXml != null) {
    final bytes = utf8.encode(relsXml);
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', bytes.length, bytes));
  }

  for (final entry in media.entries) {
    archive.addFile(ArchiveFile('word/${entry.key}', entry.value.length, entry.value));
  }

  final zipData = ZipEncoder().encode(archive);
  final file = File(path);
  await file.writeAsBytes(zipData!);
  return file;
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

  test('Missing document.xml returns null', () async {
    final storage = MockDocumentStorage();
    final file = await createMockDocx(path: './test_docs/missing.docx');
    final doc = await DocxImporter.importDocument(file, storage);
    expect(doc, isNull);
  });

  test('Basic Text Import', () async {
    final storage = MockDocumentStorage();
    final docXml = '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p>
            <w:r>
              <w:t>Hello World</w:t>
            </w:r>
          </w:p>
        </w:body>
      </w:document>
    ''';
    final file = await createMockDocx(path: './test_docs/basic.docx', documentXml: docXml);
    final doc = await DocxImporter.importDocument(file, storage);

    expect(doc, isNotNull);
    final content = jsonDecode(doc!.content) as List<dynamic>;

    expect(content.length, 2);
    expect(content[0]['insert'], 'Hello World');
    expect(content[1]['insert'], '\n');
  });

  test('Text with Styles (Bold)', () async {
    final storage = MockDocumentStorage();
    final docXml = '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p>
            <w:r>
              <w:rPr>
                <w:b/>
              </w:rPr>
              <w:t>Bold Text</w:t>
            </w:r>
          </w:p>
        </w:body>
      </w:document>
    ''';
    final file = await createMockDocx(path: './test_docs/styles.docx', documentXml: docXml);
    final doc = await DocxImporter.importDocument(file, storage);

    expect(doc, isNotNull);
    final content = jsonDecode(doc!.content) as List<dynamic>;

    expect(content.length, 2);
    expect(content[0]['insert'], 'Bold Text');
    expect(content[0]['attributes'], isNotNull);
    expect(content[0]['attributes']['bold'], true);
    expect(content[1]['insert'], '\n');
  });

  test('Image Import calls saveImage', () async {
    final storage = MockDocumentStorage();
    final docXml = '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <w:body>
          <w:p>
            <w:r>
              <w:drawing>
                <wp:inline>
                  <a:graphic>
                    <a:graphicData>
                      <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                        <pic:blipFill>
                          <a:blip r:embed="rId1" />
                        </pic:blipFill>
                      </pic:pic>
                    </a:graphicData>
                  </a:graphic>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
        </w:body>
      </w:document>
    ''';

    final relsXml = '''
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png" />
      </Relationships>
    ''';

    final file = await createMockDocx(
      path: './test_docs/image.docx',
      documentXml: docXml,
      relsXml: relsXml,
      media: {'media/image1.png': [1, 2, 3]}, // dummy image bytes
    );

    final doc = await DocxImporter.importDocument(file, storage);

    expect(doc, isNotNull);
    expect(storage.savedImages.length, 1);

    final content = jsonDecode(doc!.content) as List<dynamic>;
    expect(content.length, 2);
    expect(content[0]['insert']['image'], 'mock-path-for-mock-doc-1');
    expect(content[1]['insert'], '\n');
  });

  test('Empty Paragraphs handling', () async {
    final storage = MockDocumentStorage();
    final docXml = '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p></w:p>
        </w:body>
      </w:document>
    ''';
    final file = await createMockDocx(path: './test_docs/empty_p.docx', documentXml: docXml);
    final doc = await DocxImporter.importDocument(file, storage);

    expect(doc, isNotNull);
    final content = jsonDecode(doc!.content) as List<dynamic>;

    expect(content.length, 1);
    expect(content[0]['insert'], '\n');
  });
}
