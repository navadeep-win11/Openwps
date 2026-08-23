import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openwps/services/ai/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AIService.getMaskedApiKey', () {
    test('returns null for null or empty key', () async {
      final service = AIService();
      final providerId = 'test_provider';
      expect(await service.getMaskedApiKey(providerId), isNull);
    });

    test('returns ******** for short key (length < 16)', () async {
      final service = AIService();
      final providerId = 'test_provider';

      await service.saveApiKey(providerId, 'sk-1234'); // 7 chars
      expect(await service.getMaskedApiKey(providerId), '********');

      await service.saveApiKey(providerId, 'sk-12345678'); // 11 chars
      expect(await service.getMaskedApiKey(providerId), '********');

      await service.saveApiKey(providerId, '123456789012345'); // 15 chars
      expect(await service.getMaskedApiKey(providerId), '********');
    });

    test('returns masked key for standard long API key (length >= 16)', () async {
      final service = AIService();
      final providerId = 'test_provider';

      // length 16
      await service.saveApiKey(providerId, '1234567890123456');
      expect(await service.getMaskedApiKey(providerId), '123...3456');

      // standard openai key format
      await service.saveApiKey(providerId, 'sk-proj-abc123def456ghi789jkl012');
      expect(await service.getMaskedApiKey(providerId), 'sk-...l012');
    });
  });
}
