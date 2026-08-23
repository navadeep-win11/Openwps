import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';

void main() {
  group('CellData JSON serialization', () {
    test('toJson with required fields only', () {
      final cell = CellData(value: 'Hello');
      final json = cell.toJson();
      expect(json, {'value': 'Hello'});
    });

    test('toJson with all fields', () {
      final cell = CellData(
        value: '10',
        formula: '=1+9',
        style: {'bold': true},
      );
      final json = cell.toJson();
      expect(json, {
        'value': '10',
        'formula': '=1+9',
        'style': {'bold': true},
      });
    });

    test('fromJson with required fields only', () {
      final json = {'value': 'World'};
      final cell = CellData.fromJson(json);
      expect(cell.value, 'World');
      expect(cell.formula, isNull);
      expect(cell.style, isNull);
    });

    test('fromJson with all fields', () {
      final json = {
        'value': '20',
        'formula': '=10*2',
        'style': {'italic': true},
      };
      final cell = CellData.fromJson(json);
      expect(cell.value, '20');
      expect(cell.formula, '=10*2');
      expect(cell.style, {'italic': true});
    });
  });

  group('SheetData JSON serialization', () {
    test('toJson', () {
      final sheet = SheetData(
        id: 's1',
        name: 'Sheet 1',
        cells: {
          'A1': CellData(value: 'Test'),
          'B2': CellData(value: '42', formula: '=40+2'),
        },
      );
      final json = sheet.toJson();
      expect(json, {
        'id': 's1',
        'name': 'Sheet 1',
        'cells': {
          'A1': {'value': 'Test'},
          'B2': {'value': '42', 'formula': '=40+2'},
        },
      });
    });

    test('fromJson', () {
      final json = {
        'id': 's2',
        'name': 'Data',
        'cells': {
          'C3': {'value': 'Apple'},
        },
      };
      final sheet = SheetData.fromJson(json);
      expect(sheet.id, 's2');
      expect(sheet.name, 'Data');
      expect(sheet.cells.length, 1);
      expect(sheet.cells['C3']?.value, 'Apple');
    });
  });

  group('SpreadsheetDocument JSON serialization', () {
    final date = DateTime.utc(2023, 1, 1, 12, 0, 0);

    test('toJson', () {
      final doc = SpreadsheetDocument(
        id: 'doc1',
        title: 'Budget',
        createdAt: date,
        updatedAt: date,
        sheets: [
          SheetData(id: 's1', name: '2023', cells: {'A1': CellData(value: '100')})
        ],
        activeSheet: 's1',
        isFavorite: true,
        storageLocation: 'drive',
        syncStatus: 'pending',
      );

      final json = doc.toJson();
      expect(json, {
        'id': 'doc1',
        'title': 'Budget',
        'createdAt': '2023-01-01T12:00:00.000Z',
        'updatedAt': '2023-01-01T12:00:00.000Z',
        'sheets': [
          {
            'id': 's1',
            'name': '2023',
            'cells': {
              'A1': {'value': '100'},
            }
          }
        ],
        'activeSheet': 's1',
        'isFavorite': true,
        'storageLocation': 'drive',
        'syncStatus': 'pending',
      });
    });

    test('fromJson with all fields', () {
      final json = {
        'id': 'doc2',
        'title': 'Expenses',
        'createdAt': '2023-05-15T08:30:00.000Z',
        'updatedAt': '2023-05-16T14:45:00.000Z',
        'sheets': [
          {
            'id': 's2',
            'name': 'May',
            'cells': {}
          }
        ],
        'activeSheet': 's2',
        'isFavorite': false,
        'storageLocation': 'local',
        'syncStatus': 'synced',
      };

      final doc = SpreadsheetDocument.fromJson(json);
      expect(doc.id, 'doc2');
      expect(doc.title, 'Expenses');
      expect(doc.createdAt, DateTime.utc(2023, 5, 15, 8, 30, 0));
      expect(doc.updatedAt, DateTime.utc(2023, 5, 16, 14, 45, 0));
      expect(doc.sheets.length, 1);
      expect(doc.sheets[0].id, 's2');
      expect(doc.activeSheet, 's2');
      expect(doc.isFavorite, false);
      expect(doc.storageLocation, 'local');
      expect(doc.syncStatus, 'synced');
    });

    test('fromJson missing optional fields falls back to defaults', () {
      final json = {
        'id': 'doc3',
        'title': 'Notes',
        'createdAt': '2023-10-01T00:00:00.000Z',
        'updatedAt': '2023-10-01T00:00:00.000Z',
        'sheets': [],
        'activeSheet': 'sheet1',
      };

      final doc = SpreadsheetDocument.fromJson(json);
      expect(doc.isFavorite, false);
      expect(doc.storageLocation, 'local');
      expect(doc.syncStatus, 'synced');
    });

    test('copyWith', () {
      final doc = SpreadsheetDocument(
        id: 'doc1',
        title: 'Original',
        createdAt: date,
        updatedAt: date,
        sheets: [],
        activeSheet: 's1',
      );

      final newDate = DateTime.utc(2023, 2, 2);
      final newSheets = [SheetData(id: 's2', name: 'New', cells: {})];

      final copied = doc.copyWith(
        title: 'Modified',
        updatedAt: newDate,
        sheets: newSheets,
        activeSheet: 's2',
        isFavorite: true,
      );

      expect(copied.id, 'doc1'); // Should not change
      expect(copied.createdAt, date); // Should not change
      expect(copied.title, 'Modified');
      expect(copied.updatedAt, newDate);
      expect(copied.sheets, newSheets);
      expect(copied.activeSheet, 's2');
      expect(copied.isFavorite, true);
      expect(copied.storageLocation, 'local');
      expect(copied.syncStatus, 'synced');
    });
  });
}
