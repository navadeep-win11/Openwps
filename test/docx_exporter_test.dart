import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/features/writer/docx/docx_exporter.dart';
import 'package:openwps/storage/models/writer_document.dart';
import 'package:xml/xml.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory('./test_docs_exporter');
    if (!await tempDir.exists()) {
      await tempDir.create();
    }
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DocxExporter basic text export', () async {
    final doc = WriterDocument(
      id: '1',
      title: 'Test Basic',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: jsonEncode([
        {'insert': 'Hello World'},
        {'insert': '\n'}
      ]),
    );

    final exportPath = '${tempDir.path}/basic.docx';
    final file = await DocxExporter.exportDocument(doc, exportPath);
    expect(await file.exists(), isTrue);

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Verify presence of basic files
    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    expect(archive.findFile('_rels/.rels'), isNotNull);
    final documentFile = archive.findFile('word/document.xml');
    expect(documentFile, isNotNull);

    // Verify document content
    final docStr = utf8.decode(documentFile!.content as List<int>);
    final docXml = XmlDocument.parse(docStr);

    final texts = docXml.findAllElements('w:t');
    expect(texts.length, 1);
    expect(texts.first.innerText, 'Hello World');
  });

  test('DocxExporter formatting export', () async {
    final doc = WriterDocument(
      id: '2',
      title: 'Test Format',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: jsonEncode([
        {'insert': 'BoldText', 'attributes': {'bold': true}},
        {'insert': 'ItalicText', 'attributes': {'italic': true}},
        {'insert': '\n'}
      ]),
    );

    final exportPath = '${tempDir.path}/format.docx';
    final file = await DocxExporter.exportDocument(doc, exportPath);
    expect(await file.exists(), isTrue);

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    final docStr = utf8.decode(documentFile!.content as List<int>);
    final docXml = XmlDocument.parse(docStr);

    final runs = docXml.findAllElements('w:r');
    expect(runs.length, 2); // 2 text runs

    // First run should have w:b
    final firstRun = runs.elementAt(0);
    expect(firstRun.findElements('w:rPr').first.findElements('w:b').isNotEmpty, isTrue);
    expect(firstRun.findElements('w:t').first.innerText, 'BoldText');

    // Second run should have w:i
    final secondRun = runs.elementAt(1);
    expect(secondRun.findElements('w:rPr').first.findElements('w:i').isNotEmpty, isTrue);
    expect(secondRun.findElements('w:t').first.innerText, 'ItalicText');
  });

  test('DocxExporter image export', () async {
    // Create a dummy image file
    final dummyImage = File('${tempDir.path}/dummy.png');
    await dummyImage.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10]); // dummy PNG header

    final doc = WriterDocument(
      id: '3',
      title: 'Test Image',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: jsonEncode([
        {'insert': 'Image follows:'},
        {'insert': {'image': dummyImage.path}},
        {'insert': '\n'}
      ]),
    );

    final exportPath = '${tempDir.path}/image.docx';
    final file = await DocxExporter.exportDocument(doc, exportPath);
    expect(await file.exists(), isTrue);

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Verify media file is added
    final mediaFile = archive.findFile('word/media/image1.png');
    expect(mediaFile, isNotNull);

    // Check if the relationships file exists and contains the image relationship
    final relsFile = archive.findFile('word/_rels/document.xml.rels');
    expect(relsFile, isNotNull);
    final relsStr = utf8.decode(relsFile!.content as List<int>);
    final relsXml = XmlDocument.parse(relsStr);

    final relationships = relsXml.findAllElements('Relationship');
    final imageRel = relationships.firstWhere((r) => r.getAttribute('Target') == 'media/image1.png');
    expect(imageRel, isNotNull);
    final relId = imageRel.getAttribute('Id');

    // Check document.xml for the drawing element
    final documentFile = archive.findFile('word/document.xml');
    final docStr = utf8.decode(documentFile!.content as List<int>);
    final docXml = XmlDocument.parse(docStr);

    final drawings = docXml.findAllElements('w:drawing');
    expect(drawings.length, 1);

    final blip = docXml.findAllElements('a:blip').first;
    expect(blip.getAttribute('r:embed'), relId);
  });
}
