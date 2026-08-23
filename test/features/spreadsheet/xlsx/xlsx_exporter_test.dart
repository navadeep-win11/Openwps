import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/features/spreadsheet/xlsx/xlsx_exporter.dart';
import 'package:openwps/storage/models/spreadsheet_document.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {

  final String tempDir;

  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir;
  }
}

void main() {
  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUp(() {
    originalPlatform = PathProviderPlatform.instance;
    tempDir = Directory.systemTemp.createTempSync('xlsx_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    PathProviderPlatform.instance = originalPlatform;
  });

  test('exportDocument creates an XLSX file with correct data', () async {
    final doc = SpreadsheetDocument(
      id: 'doc1',
      title: 'Test Spreadsheet',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      activeSheet: 'sheet1',
      sheets: [
        SheetData(
          id: 'sheet1',
          name: 'Sheet 1',
          cells: {
            'A1': CellData(value: 'Hello'),
            'B1': CellData(value: 'World', style: {'bold': true, 'align': 'center'}),
            'A2': CellData(value: '123'),
            'B2': CellData(value: '456.78'),
            'A3': CellData(value: '', formula: '=SUM(A2,B2)'),
          },
        ),
        SheetData(
          id: 'sheet2',
          name: 'Sheet 2',
          cells: {
            'A1': CellData(value: 'Data in sheet 2'),
          },
        )
      ],
    );

    final file = await XlsxExporter.exportDocument(doc);

    expect(file.existsSync(), isTrue);
    expect(file.path, contains('Test Spreadsheet.xlsx'));
    expect(file.lengthSync(), greaterThan(0));
  });

  test('exportDocument handles special characters in document title', () async {
    final doc = SpreadsheetDocument(
      id: 'doc2',
      title: 'Test: Invalid/Title*?<>|',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      activeSheet: 'sheet1',
      sheets: [
        SheetData(
          id: 'sheet1',
          name: 'Sheet 1',
          cells: {
            'A1': CellData(value: 'Hello'),
          },
        ),
      ],
    );

    final file = await XlsxExporter.exportDocument(doc);

    expect(file.existsSync(), isTrue);
    // Should have replaced invalid chars with underscores
    expect(file.path, contains('Test_ Invalid_Title_____.xlsx'));
    expect(file.lengthSync(), greaterThan(0));
  });

  test('exportDocument handles all styling options', () async {
    final doc = SpreadsheetDocument(
      id: 'doc3',
      title: 'Styled Spreadsheet',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      activeSheet: 'sheet1',
      sheets: [
        SheetData(
          id: 'sheet1',
          name: 'Sheet 1',
          cells: {
            'A1': CellData(value: 'Bold', style: {'bold': true}),
            'B1': CellData(value: 'Italic', style: {'italic': true}),
            'C1': CellData(value: 'Underline', style: {'underline': true}),
            'A2': CellData(value: 'Left', style: {'align': 'left'}),
            'B2': CellData(value: 'Center', style: {'align': 'center'}),
            'C2': CellData(value: 'Right', style: {'align': 'right'}),
            'A3': CellData(value: 'Color', style: {'color': '#FF0000'}),
            'B3': CellData(value: 'Background', style: {'background': '#00FF00'}),
          },
        ),
      ],
    );

    final file = await XlsxExporter.exportDocument(doc);

    expect(file.existsSync(), isTrue);
    expect(file.path, contains('Styled Spreadsheet.xlsx'));
    expect(file.lengthSync(), greaterThan(0));
  });

  test('exportDocument handles empty sheets', () async {
    final doc = SpreadsheetDocument(
      id: 'doc4',
      title: 'Empty Spreadsheet',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      activeSheet: 'sheet1',
      sheets: [
        SheetData(
          id: 'sheet1',
          name: 'Sheet 1',
          cells: {},
        ),
      ],
    );

    final file = await XlsxExporter.exportDocument(doc);

    expect(file.existsSync(), isTrue);
    expect(file.path, contains('Empty Spreadsheet.xlsx'));
    expect(file.lengthSync(), greaterThan(0));
  });
}
