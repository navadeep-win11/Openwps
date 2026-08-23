import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';
import 'mock_ai_provider.dart';
import 'open_ai_provider.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final List<AIProvider> _providers = [
    OpenAIProvider(),
    MockAIProvider(),
  ];

  List<AIProvider> get providers => _providers;

  // Settings keys
  static const String _keyAiEnabled = 'ai_enabled';
  static const String _keyProviderId = 'ai_provider_id';
  static const String _keyModel = 'ai_model';
  static const String _keyHistory = 'ai_history';

  // Secure Storage Key Format: 'api_key_${providerId}'

  Future<bool> isAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAiEnabled) ?? false;
  }

  Future<void> setAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiEnabled, enabled);
  }

  Future<String?> getActiveProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProviderId);
  }

  Future<void> setActiveProviderId(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProviderId, providerId);
  }

  Future<String?> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModel);
  }

  Future<void> setActiveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModel, model);
  }

  AIProvider? getActiveProvider(String? providerId) {
    if (providerId == null) return null;
    try {
      return _providers.firstWhere((p) => p.id == providerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveApiKey(String providerId, String apiKey) async {
    await _secureStorage.write(key: 'api_key_$providerId', value: apiKey);
  }

  Future<String?> getApiKey(String providerId) async {
    return await _secureStorage.read(key: 'api_key_$providerId');
  }

  Future<void> deleteApiKey(String providerId) async {
    await _secureStorage.delete(key: 'api_key_$providerId');
  }

  /// Returns a masked version of the API key for UI display (e.g. sk-...1234)
  Future<String?> getMaskedApiKey(String providerId) async {
    final key = await getApiKey(providerId);
    if (key == null || key.isEmpty) return null;
    if (key.length < 16) return '********';
    return '${key.substring(0, 3)}...${key.substring(key.length - 4)}';
  }

  Future<bool> testConnection(String providerId, String model) async {
    final provider = getActiveProvider(providerId);
    if (provider == null) return false;
    final apiKey = await getApiKey(providerId);
    if (apiKey == null || apiKey.isEmpty) return false;

    return await provider.testConnection(apiKey, model);
  }

  Future<String> generateText(String prompt, {String? contextText}) async {
    final enabled = await isAiEnabled();
    if (!enabled) throw Exception('AI is disabled in settings.');

    final providerId = await getActiveProviderId();
    final provider = getActiveProvider(providerId);
    if (provider == null) throw Exception('No AI provider selected.');

    final model = await getActiveModel() ?? provider.availableModels.first;
    final apiKey = await getApiKey(provider.id);

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing for ${provider.name}. Please configure in Settings.');
    }

    final response = await provider.generateText(prompt, apiKey, model, contextText: contextText);
    await _saveToHistory(prompt, response, provider.id, model);
    return response;
  }

  Stream<String> streamText(String prompt, {String? contextText}) async* {
    final enabled = await isAiEnabled();
    if (!enabled) throw Exception('AI is disabled in settings.');

    final providerId = await getActiveProviderId();
    final provider = getActiveProvider(providerId);
    if (provider == null) throw Exception('No AI provider selected.');

    final model = await getActiveModel() ?? provider.availableModels.first;
    final apiKey = await getApiKey(provider.id);

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing for ${provider.name}. Please configure in Settings.');
    }

    String fullResponse = '';
    await for (final chunk in provider.streamText(prompt, apiKey, model, contextText: contextText)) {
      fullResponse += chunk;
      yield chunk;
    }

    await _saveToHistory(prompt, fullResponse, provider.id, model);
  }

  Future<void> _saveToHistory(String prompt, String response, String providerId, String model) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList(_keyHistory) ?? [];

    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'prompt': prompt,
      'response': response,
      'providerId': providerId,
      'model': model,
    };

    historyList.insert(0, jsonEncode(entry));
    // Keep only last 50 entries
    if (historyList.length > 50) {
      historyList.removeLast();
    }

    await prefs.setStringList(_keyHistory, historyList);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList(_keyHistory) ?? [];
    return historyList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}
