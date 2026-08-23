import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/features/spreadsheet/engine/formula_evaluator.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';

void main() {
  group('Formula Evaluator', () {
    late SheetData sheet;

    setUp(() {
      sheet = SheetData(
        id: '1',
        name: 'Sheet1',
        cells: {
          'A1': CellData(value: '10'),
          'A2': CellData(value: '20'),
          'A3': CellData(value: '30'),
          'B1': CellData(value: '5.5'),
          'C1': CellData(value: 'Test'),
        },
      );
    });

    test('evaluates basic math', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=1+1'), '2');
      expect(eval.evaluate('=10*2'), '20');
      expect(eval.evaluate('=10/2'), '5');
      expect(eval.evaluate('=10-2'), '8');
    });

    test('evaluates basic cell references', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=A1+A2'), '30');
      expect(eval.evaluate('=A2*B1'), '110');
    });

    test('evaluates SUM function with range', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=SUM(A1:A3)'), '60');
    });

    test('evaluates AVERAGE function', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=AVERAGE(A1:A3)'), '20');
    });

    test('evaluates MIN and MAX functions', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=MIN(A1:A3)'), '10');
      expect(eval.evaluate('=MAX(A1:A3)'), '30');
    });

    test('evaluates IF function naively', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=IF(A1>5,"Yes","No")'), 'YES');
      expect(eval.evaluate('=IF(A1<5,"Yes","No")'), 'NO');
    });

    test('handles empty cells gracefully', () {
      final eval = FormulaEvaluator(sheet);
      expect(eval.evaluate('=D1+1'), '1'); // D1 is null, treated as 0
    });

    test('evaluates simple circular reference', () {
      final circularSheet = SheetData(
        id: '2',
        name: 'Sheet2',
        cells: {
          'A1': CellData(value: '', formula: '=A1'),
        },
      );
      final eval = FormulaEvaluator(circularSheet);
      expect(eval.evaluate('=A1'), '#CIRCULAR!');
    });
  });
}
