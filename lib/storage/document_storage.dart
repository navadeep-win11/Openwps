import 'models/writer_document.dart';

abstract class DocumentStorage {
  Future<List<WriterDocument>> listDocuments();
  Future<WriterDocument> createDocument(String title);
  Future<WriterDocument?> getDocument(String id);
  Future<void> updateDocument(WriterDocument document);
  Future<void> deleteDocument(String id);
  Future<void> renameDocument(String id, String newTitle);
  Future<void> duplicateDocument(String id);
  Future<List<WriterDocument>> searchDocuments(String query);
  Future<void> toggleFavorite(String id);
  Future<List<WriterDocument>> recentDocuments();
  Future<String> saveImage(String documentId, String tempImagePath);
}
