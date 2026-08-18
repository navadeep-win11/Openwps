class SlideElement {
  String id;
  String type; // 'text', 'image', 'shape'
  double x;
  double y;
  double width;
  double height;
  double rotation;
  String content;
  Map<String, dynamic> style;
  int zIndex;

  SlideElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    required this.content,
    required this.style,
    required this.zIndex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'content': content,
    'style': style,
    'zIndex': zIndex,
  };

  factory SlideElement.fromJson(Map<String, dynamic> json) {
    return SlideElement(
      id: json['id'] as String,
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      content: json['content'] as String,
      style: json['style'] as Map<String, dynamic>? ?? {},
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }

  SlideElement copy() {
    return SlideElement(
      id: id,
      type: type,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      content: content,
      style: Map<String, dynamic>.from(style),
      zIndex: zIndex,
    );
  }
}

class SlideData {
  String id;
  String name;
  String background;
  List<SlideElement> elements;

  SlideData({
    required this.id,
    required this.name,
    this.background = '#FFFFFF',
    required this.elements,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'background': background,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory SlideData.fromJson(Map<String, dynamic> json) {
    return SlideData(
      id: json['id'] as String,
      name: json['name'] as String,
      background: json['background'] as String? ?? '#FFFFFF',
      elements: (json['elements'] as List).map((e) => SlideElement.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  SlideData copy() {
    return SlideData(
      id: id,
      name: name,
      background: background,
      elements: elements.map((e) => e.copy()).toList(),
    );
  }
}

class PresentationDocument {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<SlideData> slides;
  String activeSlide;
  bool isFavorite;
  String storageLocation;
  String syncStatus;

  PresentationDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.slides,
    required this.activeSlide,
    this.isFavorite = false,
    this.storageLocation = 'local',
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'slides': slides.map((e) => e.toJson()).toList(),
    'activeSlide': activeSlide,
    'isFavorite': isFavorite,
    'storageLocation': storageLocation,
    'syncStatus': syncStatus,
  };

  factory PresentationDocument.fromJson(Map<String, dynamic> json) {
    return PresentationDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      slides: (json['slides'] as List).map((e) => SlideData.fromJson(e as Map<String, dynamic>)).toList(),
      activeSlide: json['activeSlide'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      storageLocation: json['storageLocation'] as String? ?? 'local',
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  PresentationDocument copyWith({
    String? title,
    DateTime? updatedAt,
    List<SlideData>? slides,
    String? activeSlide,
    bool? isFavorite,
  }) {
    return PresentationDocument(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slides: slides ?? this.slides,
      activeSlide: activeSlide ?? this.activeSlide,
      isFavorite: isFavorite ?? this.isFavorite,
      storageLocation: storageLocation,
      syncStatus: syncStatus,
    );
  }
}
