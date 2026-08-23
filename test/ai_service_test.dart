import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/services/ai/ai_service.dart';

void main() {
  group('AIService.maskApiKey', () {
    test('returns null for null or empty keys', () {
      expect(AIService.maskApiKey(null), isNull);
      expect(AIService.maskApiKey(''), isNull);
    });

    test('returns entirely masked string for keys shorter than 15 characters', () {
      expect(AIService.maskApiKey('12345'), '********');
      expect(AIService.maskApiKey('123456789'), '********');
      expect(AIService.maskApiKey('12345678901234'), '********'); // 14 characters
    });

    test('returns partially masked string for keys 15 characters or longer', () {
      expect(AIService.maskApiKey('123456789012345'), '123...2345'); // 15 characters
      expect(AIService.maskApiKey('sk-1234567890abcdef'), 'sk-...cdef'); // 19 characters
    });
  });
}
