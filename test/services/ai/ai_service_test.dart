import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openwps/services/ai/ai_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('AIService getMaskedApiKey', () {
    test('returns null when api key is null', () async {
      final service = AIService();
      final masked = await service.getMaskedApiKey('openai');
      expect(masked, isNull);
    });

    test('returns null when api key is empty', () async {
      final service = AIService();
      await service.saveApiKey('openai', '');
      final masked = await service.getMaskedApiKey('openai');
      expect(masked, isNull);
    });

    test('returns ******** when api key length is 8 or less', () async {
      final service = AIService();
      await service.saveApiKey('openai', '12345678');
      final masked = await service.getMaskedApiKey('openai');
      expect(masked, '********');

      await service.saveApiKey('openai', '1234');
      final masked2 = await service.getMaskedApiKey('openai');
      expect(masked2, '********');
    });

    test('returns masked key when api key length is greater than 8', () async {
      final service = AIService();
      await service.saveApiKey('openai', '123456789');
      final masked = await service.getMaskedApiKey('openai');
      expect(masked, '123...6789');

      await service.saveApiKey('openai', 'sk-proj-abc123456789def');
      final masked2 = await service.getMaskedApiKey('openai');
      expect(masked2, 'sk-...9def');
    });
  });
}
