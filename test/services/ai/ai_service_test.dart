import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/services/ai/ai_service.dart';
import 'package:openwps/services/ai/open_ai_provider.dart';
import 'package:openwps/services/ai/mock_ai_provider.dart';
import 'package:openwps/services/ai/ai_provider.dart';

void main() {
  group('AIService getActiveProvider', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('should return null when providerId is null', () {
      final provider = aiService.getActiveProvider(null);
      expect(provider, isNull);
    });

    test('should return OpenAIProvider when providerId is "openai"', () {
      final provider = aiService.getActiveProvider('openai');
      expect(provider, isNotNull);
      expect(provider, isA<OpenAIProvider>());
      expect(provider?.id, 'openai');
    });

    test('should return MockAIProvider when providerId is "mock"', () {
      final provider = aiService.getActiveProvider('mock');
      expect(provider, isNotNull);
      expect(provider, isA<MockAIProvider>());
      expect(provider?.id, 'mock');
    });

    test('should return null when providerId is not found', () {
      final provider = aiService.getActiveProvider('nonexistent_provider');
      expect(provider, isNull);
    });
  });
}
