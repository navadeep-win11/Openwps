import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';

void main() {
  group('CellData JSON Serialization', () {
    test('toJson with minimal data', () {
      final cell = CellData(value: '123');
      final json = cell.toJson();

      expect(json, {'value': '123'});
      expect(json.containsKey('formula'), isFalse);
      expect(json.containsKey('style'), isFalse);
    });

    test('toJson with all fields', () {
      final cell = CellData(
        value: '123',
        formula: '=A1+A2',
        style: {'bold': true},
      );
      final json = cell.toJson();

      expect(json, {
        'value': '123',
        'formula': '=A1+A2',
        'style': {'bold': true},
      });
    });

    test('fromJson with minimal data', () {
      final json = {'value': '123'};
      final cell = CellData.fromJson(json);

      expect(cell.value, '123');
      expect(cell.formula, isNull);
      expect(cell.style, isNull);
    });

    test('fromJson with all fields', () {
      final json = {
        'value': '123',
        'formula': '=A1+A2',
        'style': {'bold': true},
      };
      final cell = CellData.fromJson(json);

      expect(cell.value, '123');
      expect(cell.formula, '=A1+A2');
      expect(cell.style, {'bold': true});
    });
  });
}
