import 'package:flutter/material.dart';

enum PdfAnnotationType { highlight, pen, note }

class PdfAnnotation {
  final String id;
  final int pageNumber;
  final PdfAnnotationType type;
  final Offset position;
  final Size size;
  final Color color;
  final double opacity;
  final String? content; // for notes, or path data for pen
  final DateTime createdAt;
  final DateTime updatedAt;

  PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    required this.opacity,
    this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'type': type.name,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'color': color.value,
      'opacity': opacity,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PdfAnnotation.fromJson(Map<String, dynamic> json) {
    return PdfAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      type: PdfAnnotationType.values.byName(json['type'] as String),
      position: Offset(
          (json['position']['dx'] as num).toDouble(),
          (json['position']['dy'] as num).toDouble(),
      ),
      size: Size(
          (json['size']['width'] as num).toDouble(),
          (json['size']['height'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num).toDouble(),
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  PdfAnnotation copyWith({
    String? content,
    Offset? position,
    Size? size,
    Color? color,
    double? opacity,
    DateTime? updatedAt,
  }) {
    return PdfAnnotation(
      id: id,
      pageNumber: pageNumber,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PdfDocument {
  final String id;
  String title;
  final String filePath; // Path to original PDF
  final DateTime createdAt;
  DateTime updatedAt;
  int pageCount;
  bool isFavorite;
  String storageLocation; // 'local' or 'drive'
  String syncStatus; // 'synced', 'pending', 'error'
  List<PdfAnnotation> annotations;

  PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.pageCount = 0,
    this.isFavorite = false,
    this.storageLocation = 'local',
    this.syncStatus = 'synced',
    this.annotations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pageCount': pageCount,
      'isFavorite': isFavorite,
      'storageLocation': storageLocation,
      'syncStatus': syncStatus,
      'annotations': annotations.map((a) => a.toJson()).toList(),
    };
  }

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pageCount: json['pageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      storageLocation: json['storageLocation'] as String? ?? 'local',
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map((e) => PdfAnnotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  PdfDocument copyWith({
    String? title,
    DateTime? updatedAt,
    int? pageCount,
    bool? isFavorite,
    String? syncStatus,
    List<PdfAnnotation>? annotations,
  }) {
    return PdfDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      storageLocation: storageLocation,
      syncStatus: syncStatus ?? this.syncStatus,
      annotations: annotations ?? this.annotations,
    );
  }
}
