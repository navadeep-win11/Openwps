import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'document_storage.dart';
import 'models/writer_document.dart';
import 'models/spreadsheet_document.dart';
import 'models/presentation_document.dart';

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

    final entities = await dir.list().toList();
    final files = entities.whereType<File>().where((e) => e.path.endsWith('.json')).toList();

    const batchSize = 50;
    for (int i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      final batch = files.sublist(i, end);

      final futures = batch.map((file) async {
        try {
          final jsonString = await file.readAsString();
          final jsonMap = jsonDecode(jsonString);
          return WriterDocument.fromJson(jsonMap);
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      for (final doc in results) {
        if (doc != null) {
          documents.add(doc);
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

  // ==========================================
  // SPREADSHEET METHODS
  // ==========================================

  static const String _spreadsheetsDirName = 'openwps_spreadsheets';

  Future<Directory> _getSpreadsheetsDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${directory.path}/$_spreadsheetsDirName');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  File _getSpreadsheetFile(Directory dir, String id) {
    return File('${dir.path}/$id.json');
  }

  @override
  Future<List<SpreadsheetDocument>> listSpreadsheets() async {
    final dir = await _getSpreadsheetsDir();
    final List<SpreadsheetDocument> documents = [];

    final entities = await dir.list().toList();
    final files = entities.whereType<File>().where((e) => e.path.endsWith('.json')).toList();

    const batchSize = 50;
    for (int i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      final batch = files.sublist(i, end);

      final futures = batch.map((file) async {
        try {
          final jsonString = await file.readAsString();
          final jsonMap = jsonDecode(jsonString);
          return SpreadsheetDocument.fromJson(jsonMap);
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      for (final doc in results) {
        if (doc != null) {
          documents.add(doc);
        }
      }
    }

    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return documents;
  }

  @override
  Future<SpreadsheetDocument> createSpreadsheet(String title) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final document = SpreadsheetDocument(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      sheets: [
        SheetData(
          id: _uuid.v4(),
          name: 'Sheet1',
          cells: {},
        )
      ],
      activeSheet: 'Sheet1',
    );

    await updateSpreadsheet(document);
    return document;
  }

  @override
  Future<SpreadsheetDocument?> getSpreadsheet(String id) async {
    final dir = await _getSpreadsheetsDir();
    final file = _getSpreadsheetFile(dir, id);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return SpreadsheetDocument.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> updateSpreadsheet(SpreadsheetDocument document) async {
    final dir = await _getSpreadsheetsDir();
    final file = _getSpreadsheetFile(dir, document.id);

    final updatedDoc = document.copyWith(updatedAt: DateTime.now());
    final jsonString = jsonEncode(updatedDoc.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  Future<void> deleteSpreadsheet(String id) async {
    final dir = await _getSpreadsheetsDir();
    final file = _getSpreadsheetFile(dir, id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameSpreadsheet(String id, String newTitle) async {
    final doc = await getSpreadsheet(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(title: newTitle);
      await updateSpreadsheet(updatedDoc);
    }
  }

  @override
  Future<void> duplicateSpreadsheet(String id) async {
    final doc = await getSpreadsheet(id);
    if (doc != null) {
      final newId = _uuid.v4();
      final now = DateTime.now();

      final duplicate = SpreadsheetDocument(
        id: newId,
        title: 'Copy of ${doc.title}',
        createdAt: now,
        updatedAt: now,
        sheets: doc.sheets,
        activeSheet: doc.activeSheet,
        isFavorite: doc.isFavorite,
      );

      await updateSpreadsheet(duplicate);
    }
  }

  @override
  Future<List<SpreadsheetDocument>> searchSpreadsheets(String query) async {
    final docs = await listSpreadsheets();
    final lowerQuery = query.toLowerCase();
    return docs.where((doc) => doc.title.toLowerCase().contains(lowerQuery)).toList();
  }

  @override
  Future<void> toggleSpreadsheetFavorite(String id) async {
    final doc = await getSpreadsheet(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(isFavorite: !doc.isFavorite);
      await updateSpreadsheet(updatedDoc);
    }
  }

  @override
  Future<List<SpreadsheetDocument>> recentSpreadsheets() async {
    final docs = await listSpreadsheets();
    return docs.take(5).toList();
  }

  // ==========================================
  // PRESENTATION METHODS
  // ==========================================

  static const String _presentationsDirName = 'openwps_presentations';

  Future<Directory> _getPresentationsDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${directory.path}/$_presentationsDirName');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  File _getPresentationFile(Directory dir, String id) {
    return File('${dir.path}/$id.json');
  }

  @override
  Future<List<PresentationDocument>> listPresentations() async {
    final dir = await _getPresentationsDir();
    final List<PresentationDocument> documents = [];

    final entities = await dir.list().toList();
    final files = entities.whereType<File>().where((e) => e.path.endsWith('.json')).toList();

    const batchSize = 50;
    for (int i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      final batch = files.sublist(i, end);

      final futures = batch.map((file) async {
        try {
          final jsonString = await file.readAsString();
          final jsonMap = jsonDecode(jsonString);
          return PresentationDocument.fromJson(jsonMap);
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      for (final doc in results) {
        if (doc != null) {
          documents.add(doc);
        }
      }
    }

    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return documents;
  }

  @override
  Future<PresentationDocument> createPresentation(String title) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final document = PresentationDocument(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      slides: [
        SlideData(
          id: _uuid.v4(),
          name: 'Slide 1',
          elements: [
            SlideElement(
              id: _uuid.v4(),
              type: 'text',
              x: 100,
              y: 100,
              width: 800,
              height: 200,
              content: 'Double tap to edit title',
              style: {'fontSize': 64.0, 'bold': true, 'align': 'center'},
              zIndex: 0,
            )
          ],
        )
      ],
      activeSlide: 'Slide 1', // We map by name or id, let's use the first slide ID below
    );

    document.activeSlide = document.slides.first.id;

    await updatePresentation(document);
    return document;
  }

  @override
  Future<PresentationDocument?> getPresentation(String id) async {
    final dir = await _getPresentationsDir();
    final file = _getPresentationFile(dir, id);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return PresentationDocument.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> updatePresentation(PresentationDocument document) async {
    final dir = await _getPresentationsDir();
    final file = _getPresentationFile(dir, document.id);

    final updatedDoc = document.copyWith(updatedAt: DateTime.now());
    final jsonString = jsonEncode(updatedDoc.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  Future<void> deletePresentation(String id) async {
    final dir = await _getPresentationsDir();
    final file = _getPresentationFile(dir, id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renamePresentation(String id, String newTitle) async {
    final doc = await getPresentation(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(title: newTitle);
      await updatePresentation(updatedDoc);
    }
  }

  @override
  Future<void> duplicatePresentation(String id) async {
    final doc = await getPresentation(id);
    if (doc != null) {
      final newId = _uuid.v4();
      final now = DateTime.now();

      final duplicate = PresentationDocument(
        id: newId,
        title: 'Copy of ${doc.title}',
        createdAt: now,
        updatedAt: now,
        slides: doc.slides.map((s) => s.copy()).toList(),
        activeSlide: doc.activeSlide,
        isFavorite: doc.isFavorite,
      );

      await updatePresentation(duplicate);
    }
  }

  @override
  Future<List<PresentationDocument>> searchPresentations(String query) async {
    final docs = await listPresentations();
    final lowerQuery = query.toLowerCase();
    return docs.where((doc) => doc.title.toLowerCase().contains(lowerQuery)).toList();
  }

  @override
  Future<void> togglePresentationFavorite(String id) async {
    final doc = await getPresentation(id);
    if (doc != null) {
      final updatedDoc = doc.copyWith(isFavorite: !doc.isFavorite);
      await updatePresentation(updatedDoc);
    }
  }

  @override
  Future<List<PresentationDocument>> recentPresentations() async {
    final docs = await listPresentations();
    return docs.take(5).toList();
  }
}
