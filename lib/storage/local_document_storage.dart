import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'document_storage.dart';
import 'models/writer_document.dart';

class LocalDocumentStorage implements DocumentStorage {
  final Uuid _uuid = const Uuid();
  static const String _documentsDirName = 'openwps_documents';

  Future<Directory> _getDocumentsDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${directory.path}/$_documentsDirName');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  File _getFile(Directory dir, String id) {
    return File('${dir.path}/$id.json');
  }

  @override
  Future<List<WriterDocument>> listDocuments() async {
    final dir = await _getDocumentsDir();
    final List<WriterDocument> documents = [];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final jsonString = await entity.readAsString();
          final jsonMap = jsonDecode(jsonString);
          documents.add(WriterDocument.fromJson(jsonMap));
        } catch (e) {
          // Skip invalid files
        }
      }
    }

    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return documents;
  }

  @override
  Future<WriterDocument> createDocument(String title) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Default empty Delta content: [{"insert":"\n"}]
    final document = WriterDocument(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      content: '[{"insert":"\\n"}]',
    );

    await updateDocument(document);
    return document;
  }

  @override
  Future<WriterDocument?> getDocument(String id) async {
    final dir = await _getDocumentsDir();
    final file = _getFile(dir, id);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return WriterDocument.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> updateDocument(WriterDocument document) async {
    final dir = await _getDocumentsDir();
    final file = _getFile(dir, document.id);

    // Update timestamp on save
    final updatedDoc = document.copyWith(updatedAt: DateTime.now());

    final jsonString = jsonEncode(updatedDoc.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  Future<void> deleteDocument(String id) async {
    final dir = await _getDocumentsDir();
    final file = _getFile(dir, id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameDocument(String id, String newTitle) async {
    final doc = await getDocument(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(title: newTitle);
      await updateDocument(updatedDoc);
    }
  }

  @override
  Future<void> duplicateDocument(String id) async {
    final doc = await getDocument(id);
    if (doc != null) {
      final newId = _uuid.v4();
      final now = DateTime.now();

      final duplicate = WriterDocument(
        id: newId,
        title: 'Copy of ${doc.title}',
        createdAt: now,
        updatedAt: now,
        content: doc.content,
        isFavorite: doc.isFavorite,
      );

      await updateDocument(duplicate);
    }
  }

  @override
  Future<List<WriterDocument>> searchDocuments(String query) async {
    final docs = await listDocuments();
    final lowerQuery = query.toLowerCase();
    return docs.where((doc) => doc.title.toLowerCase().contains(lowerQuery)).toList();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await getDocument(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(isFavorite: !doc.isFavorite);
      await updateDocument(updatedDoc);
    }
  }

  @override
  Future<List<WriterDocument>> recentDocuments() async {
    final docs = await listDocuments();
    return docs.take(5).toList(); // Return top 5 most recently updated
  }

  @override
  Future<String> saveImage(String documentId, String tempImagePath) async {
    final dir = await _getDocumentsDir();
    final imagesDir = Directory('${dir.path}/images/$documentId');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final sourceFile = File(tempImagePath);
    final ext = sourceFile.path.split('.').last;
    final newFileName = '${_uuid.v4()}.$ext';
    final destFile = File('${imagesDir.path}/$newFileName');

    await sourceFile.copy(destFile.path);
    return destFile.path;
  }
}
