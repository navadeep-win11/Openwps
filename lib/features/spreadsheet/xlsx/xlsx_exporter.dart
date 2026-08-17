import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import '../../../storage/models/spreadsheet_document.dart';

class XlsxExporter {
  static Future<File> exportDocument(SpreadsheetDocument document) async {
    final Workbook workbook = Workbook();

    // syncfusion_flutter_xlsio creates 1 worksheet by default
    for (int i = 0; i < document.sheets.length; i++) {
      final sheetData = document.sheets[i];
      final Worksheet sheet;

      if (i == 0) {
        sheet = workbook.worksheets[0];
      } else {
        sheet = workbook.worksheets.addWithName(sheetData.name);
      }

      sheet.name = sheetData.name;

      // Iterate over cells and apply to worksheet
      sheetData.cells.forEach((cellId, cellData) {

        final range = sheet.getRangeByName(cellId);

        if (cellData.formula != null && cellData.formula!.startsWith('=')) {
          // Write formula (syncfusion expects formula string without '=')
          range.setFormula(cellData.formula!);
        } else {
          // Check if numeric
          final numVal = double.tryParse(cellData.value);
          if (numVal != null) {
            range.setNumber(numVal);
          } else {
            range.setText(cellData.value);
          }
        }

        // Apply basic styling if available
        if (cellData.style != null) {
          if (cellData.style!['bold'] == true) range.cellStyle.bold = true;
          if (cellData.style!['italic'] == true) range.cellStyle.italic = true;
          if (cellData.style!['underline'] == true) range.cellStyle.underline = true;

          if (cellData.style!['align'] != null) {
            final align = cellData.style!['align'];
            if (align == 'center') range.cellStyle.hAlign = HAlignType.center;
            else if (align == 'right') range.cellStyle.hAlign = HAlignType.right;
            else range.cellStyle.hAlign = HAlignType.left;
          }

          if (cellData.style!['color'] != null) {
             final hex = cellData.style!['color'].toString().replaceFirst('#', '');
             if (hex.length == 6) range.cellStyle.fontColor = '#$hex';
          }

          if (cellData.style!['background'] != null) {
             final hex = cellData.style!['background'].toString().replaceFirst('#', '');
             if (hex.length == 6) range.cellStyle.backColor = '#$hex';
          }
        }
      });
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }

    final safeTitle = document.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${exportsDir.path}/$safeTitle.xlsx');
    await file.writeAsBytes(bytes);

    return file;
  }
}
