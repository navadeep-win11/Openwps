import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../../../storage/document_storage.dart';
import '../../../storage/models/writer_document.dart';
import 'docx_format_mapper.dart';

class DocxImporter {
  static Future<WriterDocument?> importDocument(File docxFile, DocumentStorage storage) async {
    try {
      final bytes = await docxFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find document.xml
      final docXmlFile = archive.findFile('word/document.xml');
      if (docXmlFile == null) return null;

      final docXmlString = utf8.decode(docXmlFile.content as List<int>);
      final docXml = XmlDocument.parse(docXmlString);

      // Find relationships to map media
      final relsFile = archive.findFile('word/_rels/document.xml.rels');
      final Map<String, String> mediaMap = {};
      if (relsFile != null) {
        final relsString = utf8.decode(relsFile.content as List<int>);
        final relsXml = XmlDocument.parse(relsString);
        for (final rel in relsXml.findAllElements('Relationship')) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          final type = rel.getAttribute('Type');
          if (id != null && target != null && type != null && type.endsWith('image')) {
            // Target is usually like media/image1.png
            mediaMap[id] = 'word/$target';
          }
        }
      }

      final List<Map<String, dynamic>> deltaOps = [];

      // We need a document ID to save images under. We'll create the document first.
      final newDocTitle = docxFile.uri.pathSegments.last.replaceAll('.docx', '');
      final newDoc = await storage.createDocument(newDocTitle);

      for (final pElement in docXml.findAllElements('w:p')) {
        final pAttrs = DocxFormatMapper.extractParagraphAttributes(pElement);
        bool hasRuns = false;

        for (final child in pElement.children) {
          if (child is XmlElement) {
             if (child.name.local == 'r') {
               hasRuns = true;
               final rAttrs = DocxFormatMapper.extractRunAttributes(child);

               // Check for drawing (image)
               final drawing = child.findElements('w:drawing').firstOrNull;
               if (drawing != null) {
                 final blip = drawing.findAllElements('a:blip').firstOrNull;
                 if (blip != null) {
                   final embedId = blip.getAttribute('r:embed');
                   if (embedId != null && mediaMap.containsKey(embedId)) {
                     final mediaPathInZip = mediaMap[embedId]!;
                     final mediaFile = archive.findFile(mediaPathInZip);
                     if (mediaFile != null) {
                       // Save to local temp first, then to persistent storage
                       final tempDir = await getTemporaryDirectory();
                       final tempImagePath = '${tempDir.path}/${mediaPathInZip.split('/').last}';
                       final tempFile = File(tempImagePath);
                       await tempFile.writeAsBytes(mediaFile.content as List<int>);

                       final persistentPath = await storage.saveImage(newDoc.id, tempImagePath);

                       deltaOps.add({
                         'insert': {'image': persistentPath},
                         if (rAttrs.isNotEmpty) 'attributes': rAttrs
                       });

                       // Cleanup temp
                       if (await tempFile.exists()) await tempFile.delete();
                     }
                   }
                 }
               }

               // Check for text
               final t = child.findElements('w:t').firstOrNull;
               if (t != null) {
                 final text = t.innerText;
                 if (text.isNotEmpty) {
                   deltaOps.add({
                     'insert': text,
                     if (rAttrs.isNotEmpty) 'attributes': rAttrs
                   });
                 }
               }
             }
          }
        }

        // End of paragraph marker
        deltaOps.add({
          'insert': '\n',
          if (pAttrs.isNotEmpty) 'attributes': pAttrs
        });

        // If paragraph was completely empty, it still gets a newline to preserve spacing
        if (!hasRuns && pAttrs.isEmpty) {
           // Already added above
        }
      }

      // If deltaOps is empty, ensure at least one newline
      if (deltaOps.isEmpty) {
        deltaOps.add({'insert': '\n'});
      }

      final finalDoc = newDoc.copyWith(WriterDocumentOptions(content: jsonEncode(deltaOps)));
      await storage.updateDocument(finalDoc);
      return finalDoc;

    } catch (e) {
      // In a real app we'd log the error, here we safely return null for the UI to handle
      return null;
    }
  }
}
