import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/spreadsheet_document.dart';
import 'engine/formula_evaluator.dart';
import 'widgets/formula_bar.dart';
import 'widgets/spreadsheet_toolbar.dart';
import '../ai/widgets/ai_bottom_sheet.dart';
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
  Key _gridKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _storage.getSpreadsheet(widget.documentId);
    if (doc != null) {
      _document = doc;
      final activeSheetData = _document!.sheets.firstWhere(
        (s) => s.id == _document!.activeSheet,
        orElse: () => _document!.sheets.first,
      );
      _initializeGrid(activeSheetData);
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
        renderer: (rendererContext) {
          final cellId = '$colName${rendererContext.rowIdx + 1}';
          final cellData = sheet.cells[cellId];
          final style = cellData?.style ?? {};

          Color? bgColor;
          if (style['background'] != null) {
            try { bgColor = Color(int.parse(style['background'].replaceAll('#', '0xFF'))); } catch (_) {}
          }
          Color? fgColor;
          if (style['color'] != null) {
            try { fgColor = Color(int.parse(style['color'].replaceAll('#', '0xFF'))); } catch (_) {}
          }

          Alignment align = Alignment.centerLeft;
          if (style['align'] == 'center') align = Alignment.center;
          if (style['align'] == 'right') align = Alignment.centerRight;

          return Container(
            alignment: align,
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              rendererContext.cell.value.toString(),
              style: TextStyle(
                color: fgColor,
                fontWeight: style['bold'] == true ? FontWeight.bold : FontWeight.normal,
                fontStyle: style['italic'] == true ? FontStyle.italic : FontStyle.normal,
                decoration: style['underline'] == true ? TextDecoration.underline : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
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

    final sheet = _document!.sheets.firstWhere(
      (s) => s.id == _document!.activeSheet,
      orElse: () => _document!.sheets.first,
    );
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

    final sheet = _document!.sheets.firstWhere(
      (s) => s.id == _document!.activeSheet,
      orElse: () => _document!.sheets.first,
    );
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

    final sheet = _document!.sheets.firstWhere(
      (s) => s.id == _document!.activeSheet,
      orElse: () => _document!.sheets.first,
    );
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

      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSheet,
              tooltip: 'Add Sheet',
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _document!.sheets.length,
                itemBuilder: (context, index) {
                  final sheet = _document!.sheets[index];
                  final isActive = sheet.id == _document!.activeSheet;
                  return InkWell(
                    onTap: () => _switchSheet(sheet.id),
                    onLongPress: () => _showSheetOptions(context, sheet),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sheet.name,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

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
            onAiPressed: _openAIBottomSheet,
            currentStyle: _currentStyle,
            onStyleChanged: _applyFormatting,
            onAddRow: () {
               _stateManager.insertRows(_stateManager.refRows.length, [PlutoRow(cells: {for (var col in _columns) col.field: PlutoCell(value: '')})]);
               _onDocumentChanged();
            },
            onDeleteRow: () {
               if (_stateManager.currentCell != null) {
                  _stateManager.removeRows([_stateManager.currentCell!.row]);
                  _onDocumentChanged();
               } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a cell in the row to delete')));
               }
            },
            onAddColumn: () {
                final newColIndex = _columns.length;

                String colName = '';
                int tempCol = newColIndex + 1;
                while (tempCol > 0) {
                  int rem = (tempCol - 1) % 26;
                  colName = String.fromCharCode('A'.codeUnitAt(0) + rem) + colName;
                  tempCol = (tempCol - 1) ~/ 26;
                }

                final newCol = PlutoColumn(
                  title: colName,
                  field: colName,
                  type: PlutoColumnType.text(),
                  width: 100,
                  enableColumnDrag: true,
                  enableRowDrag: false,
                  enableContextMenu: false,
                  renderer: (rendererContext) {
                    final sheet = _document!.sheets.firstWhere((s) => s.id == _document!.activeSheet, orElse: () => _document!.sheets.first);
                    final cellId = '$colName${rendererContext.rowIdx + 1}';
                    final cellData = sheet.cells[cellId];
                    final style = cellData?.style ?? {};

                    Color? bgColor;
                    if (style['background'] != null) {
                      try { bgColor = Color(int.parse(style['background'].replaceAll('#', '0xFF'))); } catch (_) {}
                    }
                    Color? fgColor;
                    if (style['color'] != null) {
                      try { fgColor = Color(int.parse(style['color'].replaceAll('#', '0xFF'))); } catch (_) {}
                    }

                    Alignment align = Alignment.centerLeft;
                    if (style['align'] == 'center') align = Alignment.center;
                    if (style['align'] == 'right') align = Alignment.centerRight;

                    return Container(
                      alignment: align,
                      color: bgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        rendererContext.cell.value.toString(),
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: style['bold'] == true ? FontWeight.bold : FontWeight.normal,
                          fontStyle: style['italic'] == true ? FontStyle.italic : FontStyle.normal,
                          decoration: style['underline'] == true ? TextDecoration.underline : TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );

                setState(() {
                  _columns.add(newCol);
                });
                _stateManager.insertColumns(_columns.length - 1, [newCol]);
                _onDocumentChanged();
            },
            onDeleteColumn: () {
               if (_stateManager.currentColumn != null) {
                  final colToDelete = _stateManager.currentColumn!;
                  setState(() {
                    _columns.removeWhere((c) => c.field == colToDelete.field);
                  });
                  _stateManager.removeColumns([colToDelete]);
                  _onDocumentChanged();
               } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a column to delete')));
               }
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
              key: _gridKey,
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

  void _switchSheet(String sheetId) {
    if (_document == null || _document!.activeSheet == sheetId) return;

    // Save current active sheet edits
    _saveDocument();

    final newSheet = _document!.sheets.firstWhere((s) => s.id == sheetId);
    setState(() {
      _document!.activeSheet = sheetId;
      _initializeGrid(newSheet);
      _gridKey = UniqueKey(); // Force PlutoGrid to rebuild with new rows/cols
    });
  }

  void _addSheet() {
    if (_document == null) return;

    final newId = const Uuid().v4();
    int newIndex = _document!.sheets.length + 1;
    String newName = 'Sheet$newIndex';

    // Ensure unique name
    while (_document!.sheets.any((s) => s.name == newName)) {
      newIndex++;
      newName = 'Sheet$newIndex';
    }

    setState(() {
      _document!.sheets.add(SheetData(id: newId, name: newName, cells: {}));
      _switchSheet(newId);
    });
    _onDocumentChanged();
  }

  void _deleteSheet(String sheetId) {
    if (_document == null) return;
    if (_document!.sheets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last sheet')),
      );
      return;
    }

    setState(() {
      _document!.sheets.removeWhere((s) => s.id == sheetId);
      if (_document!.activeSheet == sheetId) {
        _switchSheet(_document!.sheets.first.id);
      }
    });
    _onDocumentChanged();
  }

  void _renameSheet(String sheetId) {
    if (_document == null) return;
    final sheet = _document!.sheets.firstWhere((s) => s.id == sheetId);
    final controller = TextEditingController(text: sheet.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Sheet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  sheet.name = newName;
                });
                _onDocumentChanged();
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _openAIBottomSheet() {
    String? contextText;
    if (_stateManager.currentCell != null) {
       contextText = 'Cell Context: ${_stateManager.currentCell!.value}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AIBottomSheet(
          contextText: contextText,
          onReplaceText: (text) {
             if (_stateManager.currentCell != null) {
                showDialog(
                   context: context,
                   builder: (dialogContext) => AlertDialog(
                      title: const Text('Apply AI Generation'),
                      content: Text('Apply the following to the selected cell?\n\n$text'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                        TextButton(
                           onPressed: () {
                              _stateManager.changeCellValue(_stateManager.currentCell!, text, force: true);
                              Navigator.pop(dialogContext);
                           },
                           child: const Text('Apply'),
                        )
                      ],
                   )
                );
             }
          },
        ),
      ),
    );
  }

  void _showSheetOptions(BuildContext context, SheetData sheet) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameSheet(sheet.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSheet(sheet.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
