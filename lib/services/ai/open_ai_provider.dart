import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class OpenAIProvider implements AIProvider {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  @override
  String get id => 'openai';

  @override
  String get name => 'OpenAI';

  @override
  List<String> get availableModels => ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo', 'gpt-4o', 'gpt-4o-mini'];

  @override
  Future<bool> testConnection(String apiKey, String model) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [{'role': 'user', 'content': 'Test'}],
          'max_tokens': 5,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> generateText(String prompt, String apiKey, String model, {String? contextText}) async {
    final messages = _buildMessages(prompt, contextText);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Stream<String> streamText(String prompt, String apiKey, String model, {String? contextText}) async* {
    final messages = _buildMessages(prompt, contextText);

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'Accept': 'text/event-stream',
    });

    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': true,
    });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
         final body = await response.stream.bytesToString();
         throw Exception('OpenAI Stream Error: ${response.statusCode} - $body');
      }

      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty || !line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data);
          final content = json['choices']?[0]?['delta']?['content'];
          if (content != null) {
            yield content as String;
          }
        } catch (e) {
          // Ignore parsing errors for partial chunks
        }
      }
    } finally {
      client.close();
    }
  }

  List<Map<String, String>> _buildMessages(String prompt, String? contextText) {
    final messages = <Map<String, String>>[];
    if (contextText != null && contextText.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': 'You are a helpful assistant integrated into an office suite (OpenWPS). Context: $contextText'
      });
    } else {
       messages.add({
        'role': 'system',
        'content': 'You are a helpful assistant integrated into an office suite (OpenWPS).'
      });
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
