import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/ai/ai_service.dart';
import '../models/ai_message.dart';

class AIBottomSheet extends StatefulWidget {
  final String? contextText;
  final Function(String)? onInsertText;
  final Function(String)? onReplaceText;

  const AIBottomSheet({
    super.key,
    this.contextText,
    this.onInsertText,
    this.onReplaceText,
  });

  @override
  State<AIBottomSheet> createState() => _AIBottomSheetState();
}

class _AIBottomSheetState extends State<AIBottomSheet> {
  final AIService _aiService = AIService();
  final TextEditingController _promptController = TextEditingController();
  final List<AIMessage> _messages = [];
  bool _isGenerating = false;
  StreamSubscription? _streamSub;
  String _currentStreamText = '';

  @override
  void initState() {
    super.initState();
    _checkSetup();
    if (widget.contextText != null && widget.contextText!.isNotEmpty) {
      _messages.add(AIMessage(
        text: 'Context provided: "${widget.contextText!.length > 100 ? '${widget.contextText!.substring(0, 100)}...' : widget.contextText}"',
        isUser: false,
      ));
    }
  }

  Future<void> _checkSetup() async {
     final enabled = await _aiService.isAiEnabled();
     if (!enabled) {
        setState(() {
          _messages.add(AIMessage(text: 'AI is currently disabled. Please enable it in Settings.', isUser: false));
        });
     }
  }

  void _sendMessage() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AIMessage(text: text, isUser: true));
      _isGenerating = true;
      _currentStreamText = '';
    });
    _promptController.clear();

    try {
      final stream = _aiService.streamText(text, contextText: widget.contextText);
      _streamSub = stream.listen(
        (chunk) {
          setState(() {
            _currentStreamText += chunk;
          });
        },
        onDone: () {
          setState(() {
            _messages.add(AIMessage(text: _currentStreamText, isUser: false));
            _isGenerating = false;
            _currentStreamText = '';
          });
        },
        onError: (e) {
          setState(() {
            _messages.add(AIMessage(text: 'Error: ${e.toString()}', isUser: false));
            _isGenerating = false;
            _currentStreamText = '';
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(AIMessage(text: 'Error: ${e.toString()}', isUser: false));
        _isGenerating = false;
      });
    }
  }

  void _stopGenerating() {
    _streamSub?.cancel();
    setState(() {
      if (_currentStreamText.isNotEmpty) {
        _messages.add(AIMessage(text: '$_currentStreamText [Stopped]', isUser: false));
      }
      _isGenerating = false;
      _currentStreamText = '';
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
             alignment: Alignment.centerLeft,
             child: const Text('Data is sent to your configured provider. Usage costs apply.', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isGenerating) {
                   return _buildChatBubble('Generating... $_currentStreamText', false, isStreaming: true);
                }
                final msg = _messages[index];
                return _buildChatBubble(msg.text, msg.isUser);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Ask AI...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isGenerating,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isGenerating)
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    onPressed: _stopGenerating,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, {bool isStreaming = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            if (!isUser && !isStreaming && text.length > 50 && !text.startsWith('Error') && !text.startsWith('AI is') && !text.startsWith('Context')) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy', style: TextStyle(fontSize: 12)),
                    onPressed: () => _copyToClipboard(text),
                  ),
                  if (widget.onReplaceText != null)
                    TextButton.icon(
                      icon: const Icon(Icons.find_replace, size: 16),
                      label: const Text('Replace', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                         widget.onReplaceText!(text);
                         Navigator.pop(context);
                      },
                    ),
                  if (widget.onInsertText != null)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Insert', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                         widget.onInsertText!(text);
                         Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
