import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';

void main() {
  group('CellData JSON Serialization', () {
    test('toJson with only value', () {
      final cell = CellData(value: 'Test Value');
      final json = cell.toJson();

      expect(json, {'value': 'Test Value'});
      expect(json.containsKey('formula'), isFalse);
      expect(json.containsKey('style'), isFalse);
    });

    test('toJson with value and formula', () {
      final cell = CellData(value: '4', formula: '=2+2');
      final json = cell.toJson();

      expect(json, {
        'value': '4',
        'formula': '=2+2',
      });
      expect(json.containsKey('style'), isFalse);
    });

    test('toJson with value and style', () {
      final cell = CellData(
        value: 'Styled Text',
        style: {'bold': true, 'color': 'red'},
      );
      final json = cell.toJson();

      expect(json, {
        'value': 'Styled Text',
        'style': {'bold': true, 'color': 'red'},
      });
      expect(json.containsKey('formula'), isFalse);
    });

    test('toJson with all fields', () {
      final cell = CellData(
        value: '10',
        formula: '=A1+B1',
        style: {'italic': true},
      );
      final json = cell.toJson();

      expect(json, {
        'value': '10',
        'formula': '=A1+B1',
        'style': {'italic': true},
      });
    });

    test('fromJson with only value', () {
      final json = {'value': 'Test Value'};
      final cell = CellData.fromJson(json);

      expect(cell.value, 'Test Value');
      expect(cell.formula, isNull);
      expect(cell.style, isNull);
    });

    test('fromJson with value and formula', () {
      final json = {
        'value': '4',
        'formula': '=2+2',
      };
      final cell = CellData.fromJson(json);

      expect(cell.value, '4');
      expect(cell.formula, '=2+2');
      expect(cell.style, isNull);
    });

    test('fromJson with value and style', () {
      final json = {
        'value': 'Styled Text',
        'style': {'bold': true, 'color': 'red'},
      };
      final cell = CellData.fromJson(json);

      expect(cell.value, 'Styled Text');
      expect(cell.formula, isNull);
      expect(cell.style, {'bold': true, 'color': 'red'});
    });

    test('fromJson with all fields', () {
      final json = {
        'value': '10',
        'formula': '=A1+B1',
        'style': {'italic': true},
      };
      final cell = CellData.fromJson(json);

      expect(cell.value, '10');
      expect(cell.formula, '=A1+B1');
      expect(cell.style, {'italic': true});
    });

    test('toJson and fromJson roundtrip', () {
      final originalCell = CellData(
        value: '100',
        formula: '=SUM(A1:A10)',
        style: {'fontSize': 14, 'bold': true},
      );

      final json = originalCell.toJson();
      final decodedCell = CellData.fromJson(json);

      expect(decodedCell.value, originalCell.value);
      expect(decodedCell.formula, originalCell.formula);
      expect(decodedCell.style, originalCell.style);
    });
  });
}
