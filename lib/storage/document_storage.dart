abstract class DocumentStorage {
  Future<List<String>> listFiles();
  Future<void> createFile(String name, String content);
  Future<String> openFile(String name);
  Future<void> saveFile(String name, String content);
  Future<void> renameFile(String oldName, String newName);
  Future<void> deleteFile(String name);
  Future<void> duplicateFile(String name);
  Future<List<String>> searchFiles(String query);
  Future<void> favoriteFile(String name);
  Future<List<String>> recentFiles();
}
