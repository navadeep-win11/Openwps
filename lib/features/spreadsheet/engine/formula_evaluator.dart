import 'package:math_expressions/math_expressions.dart';
import '../../../storage/models/spreadsheet_document.dart';

class FormulaEvaluator {
  final SheetData sheet;

  FormulaEvaluator(this.sheet);

  String evaluate(String formula) {
    if (!formula.startsWith('=')) {
      return formula;
    }

    try {
      String expressionStr = formula.substring(1).toUpperCase();

      // Simple implementation for basic functions: SUM, AVERAGE, MIN, MAX, COUNT, COUNTA
      expressionStr = _resolveFunctions(expressionStr);

      // Resolve cell references (e.g. A1, B2)
      expressionStr = _resolveCellReferences(expressionStr);

      // Evaluate IF manually (naive implementation)
      if (expressionStr.startsWith('IF(')) {
         return _evaluateIf(expressionStr);
      }

      final parser = Parser();
      final expression = parser.parse(expressionStr);
      final contextModel = ContextModel();
      final result = expression.evaluate(EvaluationType.REAL, contextModel);

      // Format result gracefully
      if (result is double) {
        if (result == result.toInt()) {
          return result.toInt().toString();
        }
        return result.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return result.toString();
    } catch (e) {
      if (e.toString().contains('#CIRCULAR!')) {
        return '#CIRCULAR!';
      }
      return '#ERROR!';
    }
  }

  String _resolveFunctions(String expr) {
    final funcRegex = RegExp(r'(SUM|AVERAGE|MIN|MAX|COUNT|COUNTA)\(([A-Z]+[0-9]+:[A-Z]+[0-9]+|[A-Z]+[0-9]+(,[A-Z]+[0-9]+)*)\)');
    return expr.replaceAllMapped(funcRegex, (match) {
      final funcName = match.group(1)!;
      final argsStr = match.group(2)!;
      final cells = _parseRangeOrList(argsStr);
      final values = cells.map((c) => _getNumericCellValue(c)).where((v) => v != null).cast<double>().toList();

      if (funcName == 'COUNTA') {
        final allCells = cells.map((c) => _getCellValue(c)).where((v) => v.isNotEmpty).length;
        return allCells.toString();
      }

      if (values.isEmpty) return '0';

      switch (funcName) {
        case 'SUM':
          return values.reduce((a, b) => a + b).toString();
        case 'AVERAGE':
          return (values.reduce((a, b) => a + b) / values.length).toString();
        case 'MIN':
          return values.reduce((a, b) => a < b ? a : b).toString();
        case 'MAX':
          return values.reduce((a, b) => a > b ? a : b).toString();
        case 'COUNT':
          return values.length.toString();
        default:
          return '0';
      }
    });
  }

  String _evaluateIf(String expr) {
    // Basic IF(condition, true_val, false_val)
    final inner = expr.substring(3, expr.length - 1);
    final parts = _splitRespectingQuotes(inner, ',');
    if (parts.length == 3) {
      final conditionStr = parts[0].trim();
      final trueVal = parts[1].trim().replaceAll('"', '');
      final falseVal = parts[2].trim().replaceAll('"', '');

      bool conditionResult = false;
      try {
         // evaluate condition like A1>10. We use a naive approach since math_expressions doesn't do logical operators natively in this context without custom functions.
         if (conditionStr.contains('>')) {
            final split = conditionStr.split('>');
            final left = _evaluateMath(split[0]);
            final right = _evaluateMath(split[1]);
            conditionResult = left > right;
         } else if (conditionStr.contains('<')) {
            final split = conditionStr.split('<');
            final left = _evaluateMath(split[0]);
            final right = _evaluateMath(split[1]);
            conditionResult = left < right;
         } else if (conditionStr.contains('=')) {
            final split = conditionStr.split('=');
            final left = _evaluateMath(split[0]);
            final right = _evaluateMath(split[1]);
            conditionResult = left == right;
         } else {
            conditionResult = _evaluateMath(conditionStr) != 0;
         }
      } catch (_) {}

      return conditionResult ? trueVal : falseVal;
    }
    return '#ERROR!';
  }

  double _evaluateMath(String expr) {
     final parsed = Parser().parse(_resolveCellReferences(expr));
     return parsed.evaluate(EvaluationType.REAL, ContextModel());
  }

  List<String> _parseRangeOrList(String args) {
    if (args.contains(':')) {
      final parts = args.split(':');
      if (parts.length == 2) {
        return _generateRange(parts[0], parts[1]);
      }
    }
    return args.split(',').map((s) => s.trim()).toList();
  }

  List<String> _generateRange(String start, String end) {
    final startCol = start.replaceAll(RegExp(r'[0-9]'), '');
    final startRow = int.parse(start.replaceAll(RegExp(r'[A-Z]'), ''));
    final endCol = end.replaceAll(RegExp(r'[0-9]'), '');
    final endRow = int.parse(end.replaceAll(RegExp(r'[A-Z]'), ''));

    final List<String> result = [];
    final startColInt = _colToInt(startCol);
    final endColInt = _colToInt(endCol);

    for (int r = startRow; r <= endRow; r++) {
      for (int c = startColInt; c <= endColInt; c++) {
        result.add('${_intToCol(c)}$r');
      }
    }
    return result;
  }

  String _resolveCellReferences(String expr) {
    final cellRegex = RegExp(r'[A-Z]+[0-9]+');
    return expr.replaceAllMapped(cellRegex, (match) {
      final cellId = match.group(0)!;
      final val = _getNumericCellValue(cellId);
      return val != null ? val.toString() : '0';
    });
  }

  double? _getNumericCellValue(String cellId) {
    final strVal = _getCellValue(cellId);
    if (strVal == '#CIRCULAR!') {
      throw Exception('#CIRCULAR!');
    }
    return double.tryParse(strVal);
  }

  String _getCellValue(String cellId) {
    final cell = sheet.cells[cellId];
    if (cell == null) return '';
    // If the referenced cell has a formula, we ideally need a recursive evaluation tree or topological sort.
    // For this milestone, we evaluate it cleanly if it's a formula, preventing infinite loops via depth check if we wanted to be robust.
    // We will just read the literal value that was already calculated, or recursively evaluate it once.
    if (cell.formula != null && cell.formula!.startsWith('=')) {
        // Prevent simple self-reference loop
        if (cell.formula!.contains(cellId)) return '#CIRCULAR!';
        return FormulaEvaluator(sheet).evaluate(cell.formula!);
    }
    return cell.value;
  }

  int _colToInt(String col) {
    int res = 0;
    for (int i = 0; i < col.length; i++) {
      res = res * 26 + (col.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return res;
  }

  String _intToCol(int col) {
    String res = '';
    while (col > 0) {
      int rem = (col - 1) % 26;
      res = String.fromCharCode('A'.codeUnitAt(0) + rem) + res;
      col = (col - 1) ~/ 26;
    }
    return res;
  }

  List<String> _splitRespectingQuotes(String str, String separator) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (str[i] == '"') inQuotes = !inQuotes;
      if (str[i] == separator && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(str[i]);
      }
    }
    result.add(current.toString());
    return result;
  }
}
