import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openwps/services/ai/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AIService aiService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    aiService = AIService();
  });

  group('AIService generateText error paths', () {
    test('throws Exception when AI is disabled', () async {
      SharedPreferences.setMockInitialValues({
        'ai_enabled': false,
      });

      expect(
        () => aiService.generateText('Test prompt'),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('AI is disabled in settings.')),
        ),
      );
    });

    test('throws Exception when no AI provider selected', () async {
      SharedPreferences.setMockInitialValues({
        'ai_enabled': true,
        // No provider ID set
      });

      expect(
        () => aiService.generateText('Test prompt'),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('No AI provider selected.')),
        ),
      );
    });

    test('throws Exception when API Key is missing for provider', () async {
      SharedPreferences.setMockInitialValues({
        'ai_enabled': true,
        'ai_provider_id': 'mock', // Correct id for MockAIProvider
      });
      // No secure storage values set, so apiKey will be null

      final provider = aiService.getActiveProvider('mock');

      expect(
        () => aiService.generateText('Test prompt'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API Key is missing for ${provider?.name}. Please configure in Settings.'),
          ),
        ),
      );
    });
  });
}
