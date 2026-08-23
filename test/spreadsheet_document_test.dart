import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';

void main() {
  group('CellData JSON Serialization', () {
    test('toJson and fromJson work with all fields', () {
      final cell = CellData(value: '10', formula: '=A1*2', style: {'bold': true});
      final json = cell.toJson();

      expect(json['value'], '10');
      expect(json['formula'], '=A1*2');
      expect(json['style'], {'bold': true});

      final recovered = CellData.fromJson(json);

      expect(recovered.value, '10');
      expect(recovered.formula, '=A1*2');
      expect(recovered.style, {'bold': true});
    });

    test('toJson and fromJson work with minimal fields', () {
      final cell = CellData(value: '10');
      final json = cell.toJson();

      expect(json['value'], '10');
      expect(json.containsKey('formula'), isFalse);
      expect(json.containsKey('style'), isFalse);

      final recovered = CellData.fromJson(json);

      expect(recovered.value, '10');
      expect(recovered.formula, isNull);
      expect(recovered.style, isNull);
    });
  });

  group('SheetData JSON Serialization', () {
    test('toJson serializes correctly with cells', () {
      final sheetData = SheetData(
        id: 'sheet_1',
        name: 'My Sheet',
        cells: {
          'A1': CellData(value: '10', style: {'bold': true}),
          'B2': CellData(value: '20', formula: '=A1*2'),
        },
      );

      final json = sheetData.toJson();

      expect(json['id'], 'sheet_1');
      expect(json['name'], 'My Sheet');
      expect(json['cells'], isA<Map>());
      expect(json['cells']['A1'], isA<Map>());
      expect(json['cells']['A1']['value'], '10');
      expect(json['cells']['A1']['style'], {'bold': true});
      expect(json['cells']['B2']['value'], '20');
      expect(json['cells']['B2']['formula'], '=A1*2');
    });

    test('fromJson deserializes correctly with cells', () {
      final json = {
        'id': 'sheet_2',
        'name': 'Test Sheet',
        'cells': {
          'C3': {
            'value': 'Hello',
          },
          'D4': {
            'value': 'World',
            'style': {'italic': true},
          }
        }
      };

      final sheetData = SheetData.fromJson(json);

      expect(sheetData.id, 'sheet_2');
      expect(sheetData.name, 'Test Sheet');
      expect(sheetData.cells.length, 2);
      expect(sheetData.cells['C3']?.value, 'Hello');
      expect(sheetData.cells['C3']?.formula, isNull);
      expect(sheetData.cells['C3']?.style, isNull);

      expect(sheetData.cells['D4']?.value, 'World');
      expect(sheetData.cells['D4']?.style, {'italic': true});
    });

    test('toJson and fromJson are reversible', () {
      final sheetData = SheetData(
        id: 'sheet_3',
        name: 'Roundtrip Sheet',
        cells: {
          'A1': CellData(value: '1'),
          'Z99': CellData(value: '2', formula: '=A1+1', style: {'color': 'red'}),
        },
      );

      final json = sheetData.toJson();
      final recovered = SheetData.fromJson(json);

      expect(recovered.id, sheetData.id);
      expect(recovered.name, sheetData.name);
      expect(recovered.cells.length, sheetData.cells.length);

      expect(recovered.cells['A1']?.value, sheetData.cells['A1']?.value);
      expect(recovered.cells['Z99']?.value, sheetData.cells['Z99']?.value);
      expect(recovered.cells['Z99']?.formula, sheetData.cells['Z99']?.formula);
      expect(recovered.cells['Z99']?.style, sheetData.cells['Z99']?.style);
    });

    test('toJson and fromJson work with empty cells', () {
      final sheetData = SheetData(
        id: 'sheet_4',
        name: 'Empty Sheet',
        cells: {},
      );

      final json = sheetData.toJson();
      final recovered = SheetData.fromJson(json);

      expect(recovered.id, 'sheet_4');
      expect(recovered.name, 'Empty Sheet');
      expect(recovered.cells, isEmpty);
    });
  });

  group('SpreadsheetDocument JSON Serialization', () {
    test('toJson and fromJson are reversible', () {
      final doc = SpreadsheetDocument(
        id: 'doc_1',
        title: 'My Doc',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        sheets: [
          SheetData(id: 's1', name: 'Sheet 1', cells: {}),
        ],
        activeSheet: 's1',
        isFavorite: true,
        storageLocation: 'cloud',
        syncStatus: 'pending',
      );

      final json = doc.toJson();
      final recovered = SpreadsheetDocument.fromJson(json);

      expect(recovered.id, doc.id);
      expect(recovered.title, doc.title);
      expect(recovered.createdAt, doc.createdAt);
      expect(recovered.updatedAt, doc.updatedAt);
      expect(recovered.activeSheet, doc.activeSheet);
      expect(recovered.isFavorite, doc.isFavorite);
      expect(recovered.storageLocation, doc.storageLocation);
      expect(recovered.syncStatus, doc.syncStatus);
      expect(recovered.sheets.length, 1);
      expect(recovered.sheets[0].id, 's1');
    });

    test('copyWith creates correct copy', () {
      final doc = SpreadsheetDocument(
        id: 'doc_1',
        title: 'My Doc',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        sheets: [
          SheetData(id: 's1', name: 'Sheet 1', cells: {}),
        ],
        activeSheet: 's1',
      );

      final copy = doc.copyWith(
        title: 'New Title',
        isFavorite: true,
      );

      expect(copy.id, doc.id);
      expect(copy.title, 'New Title');
      expect(copy.isFavorite, true);
      expect(copy.createdAt, doc.createdAt);
      expect(copy.updatedAt, doc.updatedAt);
      expect(copy.sheets.length, 1);
    });
  });
}
