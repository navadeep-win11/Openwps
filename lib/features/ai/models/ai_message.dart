class AIMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
