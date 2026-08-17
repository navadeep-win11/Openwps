# Spreadsheet Engine Selection and Compatibility

## Engine Research
I evaluated multiple potential spreadsheet solutions for Flutter:
1.  **Univer / Handsontable / Luckysheet**: Primarily Javascript/Web-based solutions. Bringing them into Flutter requires using web views, which degrades performance and fails the Android native performance requirements.
2.  **excel / excel_plus / essential_xlsx**: The Dart ecosystem for reading/writing XLSX files is highly fragmented. Packages either fail SDK constraints (`excel_plus`), conflict with required `archive` or `xml` packages (`excel`, `essential_xlsx`, `bcell`), or are entirely unmaintained.
3.  **Syncfusion Flutter XlsIO (`syncfusion_flutter_xlsio`)**: Can natively *write* Excel documents securely. However, *it cannot read/import existing XLSX files*. Syncfusion's UI grid (`syncfusion_flutter_datagrid`) requires a commercial license.
4.  **PlutoGrid (`pluto_grid`)**: A pure Flutter datagrid with excellent performance, built-in editing, column/row resizing, and keyboard navigation.

**Selected Approach:**
I chose a hybrid approach for maximum native performance and adherence to constraints:
- **UI Engine**: `pluto_grid`. It's incredibly fast, pure Dart, and supports cell editing.
- **Formula Engine**: I built a bespoke formula evaluator leveraging `math_expressions` for safe parsing of arithmetic, preventing arbitrary code execution. Supported formulas include `SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `COUNTA`, `IF`.
- **XLSX Import/Export Engine**: Because no Flutter package currently exists that successfully builds alongside our DOCX dependencies *and* allows importing XLSX files without crashing version resolution, **XLSX Import is temporarily disabled/unavailable natively in this milestone**. `syncfusion_flutter_xlsio` will be used exclusively for **XLSX Export**. This satisfies the constraint to document limitations rather than faking unsupported features.

## Known Limitations
- XLSX Import is not possible in this iteration due to fatal Dart package constraints.
- Advanced cell styling borders, nested formulas, charts, and macros are not supported in the custom PlutoGrid UI mapping.
