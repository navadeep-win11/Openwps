import 'document_storage.dart';

class LocalDocumentStorage implements DocumentStorage {
  // Simple in-memory mock implementation for Phase 1
  final List<String> _files = ['Q3 Report.presentation', 'Budget FY24.spreadsheet', 'Project Proposal.writer'];

  @override
  Future<List<String>> listFiles() async {
    return _files;
  }

  @override
  Future<void> createFile(String name, String content) async {
    _files.add(name);
  }

  @override
  Future<String> openFile(String name) async {
    return 'Mock content for $name';
  }

  @override
  Future<void> saveFile(String name, String content) async {
    // Mock save
  }

  @override
  Future<void> renameFile(String oldName, String newName) async {
    final index = _files.indexOf(oldName);
    if (index != -1) {
      _files[index] = newName;
    }
  }

  @override
  Future<void> deleteFile(String name) async {
    _files.remove(name);
  }

  @override
  Future<void> duplicateFile(String name) async {
    _files.add('Copy of $name');
  }

  @override
  Future<List<String>> searchFiles(String query) async {
    return _files.where((file) => file.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<void> favoriteFile(String name) async {
    // Mock favorite
  }

  @override
  Future<List<String>> recentFiles() async {
    return _files; // Return all as recent for now
  }
}
