import 'dart:async';
import 'ai_provider.dart';

class MockAIProvider implements AIProvider {
  @override
  String get id => 'mock';

  @override
  String get name => 'Mock Testing Provider';

  @override
  List<String> get availableModels => ['mock-model-v1', 'mock-model-v2'];

  @override
  Future<bool> testConnection(String apiKey, String model) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return apiKey.isNotEmpty;
  }

  @override
  Future<String> generateText(String prompt, String apiKey, String model, {String? contextText}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (apiKey.isEmpty) throw Exception('Invalid API Key');

    return 'This is a mock response from Mock Provider to: "$prompt"';
  }

  @override
  Stream<String> streamText(String prompt, String apiKey, String model, {String? contextText}) async* {
    if (apiKey.isEmpty) throw Exception('Invalid API Key');

    final response = 'This is a streamed mock response to: "$prompt"';
    final words = response.split(' ');

    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield '$word ';
    }
  }
}
