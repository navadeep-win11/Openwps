import 'models/writer_document.dart';
import 'models/spreadsheet_document.dart';
import 'models/presentation_document.dart';

abstract class DocumentStorage {
  // Writer methods
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

  // Spreadsheet methods
  Future<List<SpreadsheetDocument>> listSpreadsheets();
  Future<SpreadsheetDocument> createSpreadsheet(String title);
  Future<SpreadsheetDocument?> getSpreadsheet(String id);
  Future<void> updateSpreadsheet(SpreadsheetDocument document);
  Future<void> deleteSpreadsheet(String id);
  Future<void> renameSpreadsheet(String id, String newTitle);
  Future<void> duplicateSpreadsheet(String id);
  Future<List<SpreadsheetDocument>> searchSpreadsheets(String query);
  Future<void> toggleSpreadsheetFavorite(String id);
  Future<List<SpreadsheetDocument>> recentSpreadsheets();

  // Presentation methods
  Future<List<PresentationDocument>> listPresentations();
  Future<PresentationDocument> createPresentation(String title);
  Future<PresentationDocument?> getPresentation(String id);
  Future<void> updatePresentation(PresentationDocument document);
  Future<void> deletePresentation(String id);
  Future<void> renamePresentation(String id, String newTitle);
  Future<void> duplicatePresentation(String id);
  Future<List<PresentationDocument>> searchPresentations(String query);
  Future<void> togglePresentationFavorite(String id);
  Future<List<PresentationDocument>> recentPresentations();
}
