# Test Results

All current core system unit tests pass using `flutter test`.

- Storage tests validation of creating and parsing documents
- DOCX export and robustly importing corrupt document validation
- Spreadsheets validation of simple formula evaluator including nested mathematical formulas
- Presentation validations for initialization and core setup
- General basic Smoke test runs successfully on entry.

*For actual UI End-to-End coverage and visual regression matching, manual QA testing on Android versions >12 is required mostly focusing on `flutter_quill` text selection behavior on lower memory RAM states.*
