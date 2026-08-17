import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/spreadsheet_document.dart';
import 'engine/formula_evaluator.dart';
import 'widgets/formula_bar.dart';
import 'widgets/spreadsheet_toolbar.dart';
import 'xlsx/xlsx_exporter.dart';

class SpreadsheetScreen extends StatefulWidget {
  final String documentId;

  const SpreadsheetScreen({super.key, required this.documentId});

  @override
  State<SpreadsheetScreen> createState() => _SpreadsheetScreenState();
}

class _SpreadsheetScreenState extends State<SpreadsheetScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  SpreadsheetDocument? _document;
  bool _isLoading = true;
  final ValueNotifier<String> _saveStatus = ValueNotifier<String>('Saved');
  Timer? _debounceTimer;

  late PlutoGridStateManager _stateManager;
  final TextEditingController _formulaController = TextEditingController();
  final FocusNode _formulaFocusNode = FocusNode();
  String _selectedCellPosition = '';
  Map<String, dynamic> _currentStyle = {};

  final List<PlutoColumn> _columns = [];
  final List<PlutoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _storage.getSpreadsheet(widget.documentId);
    if (doc != null) {
      _document = doc;
      _initializeGrid(doc.sheets.first); // Assuming single sheet for initial view
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeGrid(SheetData sheet) {
    _columns.clear();
    _rows.clear();

    // Generate A-Z columns
    for (int i = 0; i < 26; i++) {
      String colName = String.fromCharCode('A'.codeUnitAt(0) + i);
      _columns.add(PlutoColumn(
        title: colName,
        field: colName,
        type: PlutoColumnType.text(),
        width: 100,
        enableColumnDrag: true,
        enableRowDrag: false,
        enableContextMenu: false,
      ));
    }

    // Generate 100 rows initially
    for (int r = 1; r <= 100; r++) {
      Map<String, PlutoCell> rowCells = {};
      for (var col in _columns) {
        final cellId = '${col.field}$r';
        final cellData = sheet.cells[cellId];

        String displayValue = '';
        if (cellData != null) {
          if (cellData.formula != null && cellData.formula!.startsWith('=')) {
             displayValue = FormulaEvaluator(sheet).evaluate(cellData.formula!);
          } else {
             displayValue = cellData.value;
          }
        }

        rowCells[col.field] = PlutoCell(value: displayValue);
      }
      _rows.add(PlutoRow(cells: rowCells));
    }
  }

  void _onDocumentChanged() {
    _saveStatus.value = 'Saving...';
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveDocument();
    });
  }

  Future<void> _saveDocument() async {
    if (_document == null) return;
    try {
      final updatedDoc = _document!.copyWith(updatedAt: DateTime.now());
      await _storage.updateSpreadsheet(updatedDoc);
      _document = updatedDoc;
      _saveStatus.value = 'Saved';
    } catch (e) {
      _saveStatus.value = 'Save failed';
    }
  }

  void _handleCellChange(PlutoGridOnChangedEvent event) {
    if (_document == null) return;

    final String col = event.column.field;
    final int row = event.rowIdx + 1;
    final cellId = '$col$row';
    final newValue = event.value.toString();

    final sheet = _document!.sheets.first;
    CellData cellData = sheet.cells[cellId] ?? CellData(value: '');

    if (newValue.startsWith('=')) {
      cellData.formula = newValue;
      cellData.value = FormulaEvaluator(sheet).evaluate(newValue);
    } else {
      cellData.formula = null;
      cellData.value = newValue;
    }

    sheet.cells[cellId] = cellData;

    // Trigger grid re-render for evaluated value
    if (cellData.formula != null) {
      _stateManager.changeCellValue(event.row.cells[col]!, cellData.value, force: true, callOnChangedEvent: false);
    }

    // Re-evaluate entire sheet naively for dependent cells
    _reEvaluateAllFormulas(sheet);

    _onDocumentChanged();
  }

  void _reEvaluateAllFormulas(SheetData sheet) {
    bool changed = false;
    for (int r = 0; r < _rows.length; r++) {
      for (var col in _columns) {
        final cellId = '${col.field}${r + 1}';
        final cellData = sheet.cells[cellId];
        if (cellData != null && cellData.formula != null) {
          final newValue = FormulaEvaluator(sheet).evaluate(cellData.formula!);
          if (newValue != cellData.value) {
            cellData.value = newValue;
            _stateManager.changeCellValue(_rows[r].cells[col.field]!, newValue, force: true, callOnChangedEvent: false);
            changed = true;
          }
        }
      }
    }
    if (changed) {
      _stateManager.notifyListeners();
    }
  }

  void _handleCellSelected(PlutoGridOnSelectedEvent event) {
    if (event.rowIdx == null || event.cell == null) return;

    final col = event.cell!.column.field;
    final row = event.rowIdx! + 1;
    final cellId = '$col$row';

    setState(() {
      _selectedCellPosition = cellId;
    });

    final sheet = _document!.sheets.first;
    final cellData = sheet.cells[cellId];

    if (cellData != null && cellData.formula != null) {
      _formulaController.text = cellData.formula!;
    } else {
      _formulaController.text = event.cell!.value.toString();
    }

    setState(() {
      _currentStyle = cellData?.style ?? {};
    });
  }

  void _applyFormatting(String key, dynamic value) {
    if (_document == null || _selectedCellPosition.isEmpty) return;

    final sheet = _document!.sheets.first;
    CellData cellData = sheet.cells[_selectedCellPosition] ?? CellData(value: '');
    cellData.style ??= {};

    if (value == null || value == false) {
      cellData.style!.remove(key);
    } else {
      cellData.style![key] = value;
    }

    sheet.cells[_selectedCellPosition] = cellData;

    setState(() {
      _currentStyle = Map.from(cellData.style!);
    });

    _stateManager.notifyListeners();
    _onDocumentChanged();
  }

  void _onFormulaSubmitted() {
    if (_document == null || _selectedCellPosition.isEmpty) return;

    final col = _selectedCellPosition.replaceAll(RegExp(r'[0-9]'), '');
    final rowIdx = int.parse(_selectedCellPosition.replaceAll(RegExp(r'[A-Z]'), '')) - 1;
    final plutoCell = _rows[rowIdx].cells[col]!;

    _stateManager.changeCellValue(plutoCell, _formulaController.text, force: true);
    // changeCellValue triggers onChanged event, which handles logic
  }

  Future<void> _exportToXlsx() async {
    if (_document == null) return;
    _saveStatus.value = 'Exporting...';
    try {
      final file = await XlsxExporter.exportDocument(_document!);
      if (mounted) {
        _saveStatus.value = 'Saved';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        _saveStatus.value = 'Export failed';
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _formulaController.dispose();
    _formulaFocusNode.dispose();
    _saveStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Spreadsheet not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ValueListenableBuilder<String>(
                valueListenable: _saveStatus,
                builder: (context, status, child) {
                  return Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: status == 'Save failed'
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outline,
                        ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToXlsx,
          ),
        ],
      ),
      body: Column(
        children: [
          SpreadsheetToolbar(
            currentStyle: _currentStyle,
            onStyleChanged: _applyFormatting,
            onAddRow: () {
               _stateManager.appendRows([PlutoRow(cells: {for (var col in _columns) col.field: PlutoCell(value: '')})]);
               _onDocumentChanged();
            },
            onAddColumn: () {
               // adding columns dynamically is complex in pluto_grid, we pre-allocate A-Z for this iteration
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max columns reached')));
            },
          ),
          FormulaBar(
            selectedCellPosition: _selectedCellPosition,
            textController: _formulaController,
            focusNode: _formulaFocusNode,
            onSubmitted: _onFormulaSubmitted,
            onFocusGained: () {},
          ),
          Expanded(
            child: PlutoGrid(
              columns: _columns,
              rows: _rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                _stateManager = event.stateManager;
                _stateManager.setSelectingMode(PlutoGridSelectingMode.cell);
              },
              onChanged: _handleCellChange,
              onSelected: _handleCellSelected,
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  gridBackgroundColor: Theme.of(context).colorScheme.surface,
                  rowHeight: 32,
                  columnHeight: 32,
                  enableCellBorderVertical: true,
                  enableCellBorderHorizontal: true,
                  borderColor: Theme.of(context).colorScheme.outlineVariant,
                  activatedColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  activatedBorderColor: Theme.of(context).colorScheme.primary,
                ),
                enterKeyAction: PlutoGridEnterKeyAction.editingAndMoveDown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
