import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import '../../../storage/models/writer_document.dart';
import 'docx_format_mapper.dart';

class DocxExporter {
  static Future<File> exportDocument(WriterDocument document, String exportPath) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = XmlBuilder();
    contentTypesXml.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    contentTypesXml.element('Types', attributes: {'xmlns': 'http://schemas.openxmlformats.org/package/2006/content-types'}, nest: () {
      contentTypesXml.element('Default', attributes: {'Extension': 'rels', 'ContentType': 'application/vnd.openxmlformats-package.relationships+xml'});
      contentTypesXml.element('Default', attributes: {'Extension': 'xml', 'ContentType': 'application/xml'});
      contentTypesXml.element('Default', attributes: {'Extension': 'png', 'ContentType': 'image/png'});
      contentTypesXml.element('Default', attributes: {'Extension': 'jpg', 'ContentType': 'image/jpeg'});
      contentTypesXml.element('Default', attributes: {'Extension': 'jpeg', 'ContentType': 'image/jpeg'});
      contentTypesXml.element('Override', attributes: {'PartName': '/word/document.xml', 'ContentType': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml'});
    });
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.buildDocument().toString().length, utf8.encode(contentTypesXml.buildDocument().toString())));

    // 2. _rels/.rels
    final relsXml = XmlBuilder();
    relsXml.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    relsXml.element('Relationships', attributes: {'xmlns': 'http://schemas.openxmlformats.org/package/2006/relationships'}, nest: () {
      relsXml.element('Relationship', attributes: {
        'Id': 'rId1',
        'Type': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument',
        'Target': 'word/document.xml'
      });
    });
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.buildDocument().toString().length, utf8.encode(relsXml.buildDocument().toString())));

    // 3. word/document.xml and extract media
    final deltaOps = jsonDecode(document.content) as List<dynamic>;

    // Pre-fetch images asynchronously to avoid blocking the isolate
    final imageCache = <String, List<int>>{};
    for (final op in deltaOps) {
      final insert = op['insert'];
      if (insert is Map<String, dynamic> && insert.containsKey('image')) {
        final imagePath = insert['image'] as String;
        if (!imageCache.containsKey(imagePath)) {
          final file = File(imagePath);
          if (await file.exists()) {
            imageCache[imagePath] = await file.readAsBytes();
          }
        }
      }
    }

    final docXml = XmlBuilder();
    docXml.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    docXml.element('w:document', attributes: {
      'xmlns:w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'xmlns:r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
      'xmlns:wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
      'xmlns:a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
      'xmlns:pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture'
    }, nest: () {
      docXml.element('w:body', nest: () {

        final documentRelsXml = XmlBuilder();
        documentRelsXml.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
        documentRelsXml.element('Relationships', attributes: {'xmlns': 'http://schemas.openxmlformats.org/package/2006/relationships'}, nest: () {

          int rIdCounter = 1;
          List<dynamic> currentParagraphOps = [];
          Map<String, dynamic>? currentParagraphAttrs;

          void flushParagraph() {
            if (currentParagraphOps.isEmpty && currentParagraphAttrs == null) return;

            docXml.element('w:p', nest: () {
              if (currentParagraphAttrs != null && currentParagraphAttrs!.isNotEmpty) {
                DocxFormatMapper.applyParagraphAttributes(docXml, currentParagraphAttrs!);
              }

              for (final op in currentParagraphOps) {
                final insert = op['insert'];
                final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

                if (insert is String) {
                  final text = insert.replaceAll('\n', ''); // Newlines handled by splitting
                  if (text.isNotEmpty) {
                    docXml.element('w:r', nest: () {
                      if (attrs.isNotEmpty) {
                        DocxFormatMapper.applyRunAttributes(docXml, attrs);
                      }
                      docXml.element('w:t', attributes: {'xml:space': 'preserve'}, nest: () {
                        docXml.text(text);
                      });
                    });
                  }
                } else if (insert is Map<String, dynamic> && insert.containsKey('image')) {
                  final imagePath = insert['image'] as String;
                  final bytes = imageCache[imagePath];
                  if (bytes != null && bytes.isNotEmpty) {
                     final ext = p.extension(imagePath).replaceFirst('.', '');
                     final mediaName = 'image$rIdCounter.$ext';

                     // Add media file to zip
                     archive.addFile(ArchiveFile('word/media/$mediaName', bytes.length, bytes));

                     // Add relationship
                     documentRelsXml.element('Relationship', attributes: {
                       'Id': 'rId$rIdCounter',
                       'Type': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',
                       'Target': 'media/$mediaName'
                     });

                     // Add drawing XML to document
                     docXml.element('w:r', nest: () {
                       docXml.element('w:drawing', nest: () {
                         docXml.element('wp:inline', nest: () {
                           docXml.element('wp:extent', attributes: {'cx': '1143000', 'cy': '1143000'}); // Fixed dummy size
                           docXml.element('wp:docPr', attributes: {'id': '$rIdCounter', 'name': 'Picture $rIdCounter'});
                           docXml.element('a:graphic', nest: () {
                             docXml.element('a:graphicData', attributes: {'uri': 'http://schemas.openxmlformats.org/drawingml/2006/picture'}, nest: () {
                               docXml.element('pic:pic', nest: () {
                                 docXml.element('pic:nvPicPr', nest: () {
                                   docXml.element('pic:cNvPr', attributes: {'id': '$rIdCounter', 'name': 'Picture $rIdCounter'});
                                   docXml.element('pic:cNvPicPr');
                                 });
                                 docXml.element('pic:blipFill', nest: () {
                                   docXml.element('a:blip', attributes: {'r:embed': 'rId$rIdCounter'});
                                   docXml.element('a:stretch', nest: () {
                                     docXml.element('a:fillRect');
                                   });
                                 });
                                 docXml.element('pic:spPr', nest: () {
                                   docXml.element('a:xfrm', nest: () {
                                     docXml.element('a:ext', attributes: {'cx': '1143000', 'cy': '1143000'});
                                   });
                                   docXml.element('a:prstGeom', attributes: {'prst': 'rect'}, nest: () {
                                     docXml.element('a:avLst');
                                   });
                                 });
                               });
                             });
                           });
                         });
                       });
                     });
                     rIdCounter++;
                  }
                }
              }
            });
            currentParagraphOps.clear();
            currentParagraphAttrs = null;
          }

          for (final op in deltaOps) {
            final insert = op['insert'];
            final attrs = op['attributes'] as Map<String, dynamic>?;

            if (insert is String) {
              final parts = insert.split('\n');
              for (int i = 0; i < parts.length; i++) {
                if (i > 0) {
                  // The newline character itself might have paragraph attributes
                  currentParagraphAttrs = attrs;
                  flushParagraph();
                }
                if (parts[i].isNotEmpty) {
                  currentParagraphOps.add({
                    'insert': parts[i],
                    if (attrs != null) 'attributes': attrs
                  });
                }
              }
            } else {
               // Embedded blocks (images)
               currentParagraphOps.add(op);
            }
          }
          flushParagraph(); // Ensure last paragraph is flushed

          docXml.element('w:sectPr', nest: () {
            docXml.element('w:pgSz', attributes: {'w:w': '12240', 'w:h': '15840'});
            docXml.element('w:pgMar', attributes: {'w:top': '1440', 'w:right': '1440', 'w:bottom': '1440', 'w:left': '1440'});
          });

        });

        final docRelsStr = documentRelsXml.buildDocument().toString();
        archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsStr.length, utf8.encode(docRelsStr)));
      });
    });

    final docStr = docXml.buildDocument().toString();
    archive.addFile(ArchiveFile('word/document.xml', docStr.length, utf8.encode(docStr)));

    // Create file
    final outputFile = File(exportPath);
    final zipEncoder = ZipEncoder();
    final encodedBytes = zipEncoder.encode(archive);

      await outputFile.writeAsBytes(encodedBytes);
    return outputFile;
  }
}
