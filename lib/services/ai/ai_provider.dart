abstract class AIProvider {
  String get id;
  String get name;
  Future<bool> testConnection(String apiKey, String model);
  Future<String> generateText(String prompt, String apiKey, String model, {String? contextText});
  Stream<String> streamText(String prompt, String apiKey, String model, {String? contextText});
  List<String> get availableModels;
}
