
class WriterDocument {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  String content; // JSON string representing Quill Delta
  bool isFavorite;
  String storageLocation; // 'local' or 'drive'
  String syncStatus; // 'synced', 'pending', 'error'

  WriterDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
    this.isFavorite = false,
    this.storageLocation = 'local',
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'content': content,
      'isFavorite': isFavorite,
      'storageLocation': storageLocation,
      'syncStatus': syncStatus,
    };
  }

  factory WriterDocument.fromJson(Map<String, dynamic> json) {
    return WriterDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      content: json['content'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      storageLocation: json['storageLocation'] as String? ?? 'local',
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  WriterDocument copyWith(WriterDocumentUpdate update) {
    return WriterDocument(
      id: id,
      title: update.title ?? title,
      createdAt: createdAt,
      updatedAt: update.updatedAt ?? updatedAt,
      content: update.content ?? content,
      isFavorite: update.isFavorite ?? isFavorite,
      storageLocation: storageLocation,
      syncStatus: update.syncStatus ?? syncStatus,
    );
  }
}

class WriterDocumentUpdate {
  final String? title;
  final DateTime? updatedAt;
  final String? content;
  final bool? isFavorite;
  final String? syncStatus;

  const WriterDocumentUpdate({
    this.title,
    this.updatedAt,
    this.content,
    this.isFavorite,
    this.syncStatus,
  });
}
