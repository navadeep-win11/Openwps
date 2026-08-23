import 'dart:convert';
import 'dart:io';
import 'package:openwps/storage/models/writer_document.dart';
import 'package:openwps/features/writer/docx/docx_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('benchmark export', () async {
    final tempDir = Directory('./test_docs/temp');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    // create a dummy image
    final imagePath = './test_docs/dummy.png';
    final dummyImage = File(imagePath);
    // write 1MB of random bytes
    await dummyImage.writeAsBytes(List.generate(1024 * 1024, (i) => i % 256));

    List<dynamic> content = [];
    for (int i = 0; i < 50; i++) {
      content.add({"insert": "Image $i\n"});
      content.add({"insert": {"image": imagePath}});
      content.add({"insert": "\n"});
    }

    final doc = WriterDocument(
      id: 'test',
      title: 'test',
      content: jsonEncode(content),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final stopwatch = Stopwatch()..start();
    await DocxExporter.exportDocument(doc, './test_docs/test_export.docx');
    stopwatch.stop();

    print('Export took ${stopwatch.elapsedMilliseconds} ms');
  });
}
