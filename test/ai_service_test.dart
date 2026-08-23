import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/services/ai/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AIService History Migration', () {
    test(
      'migrates legacy history from SharedPreferences to SecureStorage',
      () async {
        // 1. Setup legacy data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final legacyEntry = {
          'timestamp': DateTime.now().toIso8601String(),
          'prompt': 'legacy prompt',
          'response': 'legacy response',
          'providerId': 'mock_provider',
          'model': 'mock_model',
        };
        await prefs.setStringList('ai_history', [jsonEncode(legacyEntry)]);
        expect(prefs.containsKey('ai_history'), isTrue);

        // 2. Instantiate service and fetch history
        final service = AIService();
        final history = await service.getHistory();

        // 3. Verify data is returned
        expect(history.length, 1);
        expect(history.first['prompt'], 'legacy prompt');

        // 4. Verify data is removed from SharedPreferences
        expect(prefs.containsKey('ai_history'), isFalse);

        // 5. Verify data is now in SecureStorage
        const storage = FlutterSecureStorage();
        final secureData = await storage.read(key: 'ai_history');
        expect(secureData, isNotNull);
        final decoded = jsonDecode(secureData!) as List;
        expect(decoded.length, 1);
      },
    );

    test(
      'saves new history directly to SecureStorage without SharedPreferences',
      () async {
        final service = AIService();
        // Use internal method to simulate saving history. Note: The method is private but
        // we can indirectly test it by ensuring it writes to secure storage.
        // Since it's private, we will test through streamText or generateText, or directly mocking.
        // Wait, _saveToHistory is private. We can test via generateText, but generateText relies on enabled settings.
        // Let's just test getHistory and clearHistory, and maybe we can use reflection or test it directly.
        // Actually, we can enable AI and use mock provider.

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ai_enabled', true);
        await prefs.setString('ai_provider_id', 'mock');
        await service.saveApiKey(
          'mock',
          'test_key',
        ); // Needed to avoid missing key exception

        // Generate text to trigger save
        await service.generateText('hello');

        final history = await service.getHistory();
        expect(history.length, 1);
        expect(history.first['prompt'], 'hello');

        // Verify nothing is in SharedPreferences
        expect(prefs.containsKey('ai_history'), isFalse);

        // Verify it is in Secure Storage
        const storage = FlutterSecureStorage();
        final secureData = await storage.read(key: 'ai_history');
        expect(secureData, isNotNull);

        // Clear history
        await service.clearHistory();
        final clearedHistory = await service.getHistory();
        expect(clearedHistory.isEmpty, isTrue);

        final secureDataCleared = await storage.read(key: 'ai_history');
        expect(secureDataCleared, isNull);
      },
    );
  });
}
