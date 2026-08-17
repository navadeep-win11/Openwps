
class CellData {
  String value;
  String? formula;
  Map<String, dynamic>? style;

  CellData({
    required this.value,
    this.formula,
    this.style,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    if (formula != null) 'formula': formula,
    if (style != null) 'style': style,
  };

  factory CellData.fromJson(Map<String, dynamic> json) {
    return CellData(
      value: json['value'] as String,
      formula: json['formula'] as String?,
      style: json['style'] as Map<String, dynamic>?,
    );
  }
}

class SheetData {
  String id;
  String name;
  Map<String, CellData> cells; // Keyed by A1, B2, etc.

  SheetData({
    required this.id,
    required this.name,
    required this.cells,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cells': cells.map((key, value) => MapEntry(key, value.toJson())),
  };

  factory SheetData.fromJson(Map<String, dynamic> json) {
    return SheetData(
      id: json['id'] as String,
      name: json['name'] as String,
      cells: (json['cells'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, CellData.fromJson(value as Map<String, dynamic>))
      ),
    );
  }
}

class SpreadsheetDocument {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<SheetData> sheets;
  String activeSheet;
  bool isFavorite;
  String storageLocation;
  String syncStatus;

  SpreadsheetDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.sheets,
    required this.activeSheet,
    this.isFavorite = false,
    this.storageLocation = 'local',
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sheets': sheets.map((e) => e.toJson()).toList(),
    'activeSheet': activeSheet,
    'isFavorite': isFavorite,
    'storageLocation': storageLocation,
    'syncStatus': syncStatus,
  };

  factory SpreadsheetDocument.fromJson(Map<String, dynamic> json) {
    return SpreadsheetDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sheets: (json['sheets'] as List).map((e) => SheetData.fromJson(e as Map<String, dynamic>)).toList(),
      activeSheet: json['activeSheet'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      storageLocation: json['storageLocation'] as String? ?? 'local',
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  SpreadsheetDocument copyWith({
    String? title,
    DateTime? updatedAt,
    List<SheetData>? sheets,
    String? activeSheet,
    bool? isFavorite,
  }) {
    return SpreadsheetDocument(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sheets: sheets ?? this.sheets,
      activeSheet: activeSheet ?? this.activeSheet,
      isFavorite: isFavorite ?? this.isFavorite,
      storageLocation: storageLocation,
      syncStatus: syncStatus,
    );
  }
}
