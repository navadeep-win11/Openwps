# DOCX Compatibility Report

## 1. Research & Selected Approach
I researched existing Dart/Flutter packages for DOCX handling, including `docx_template`, `docx_to_text`, and `docx_creator`.
Unfortunately, the Dart ecosystem for DOCX is highly fragmented and generally unmaintained. Existing packages have strict, conflicting dependency constraints (specifically regarding the `xml` and `archive` packages) that conflict with modern Flutter environments and `flutter_quill`.

**Decision**: Instead of fighting unmaintained packages or introducing dependency hell, I implemented a robust, bespoke OpenXML parser and generator using the `archive` and `xml` packages natively. This gives us full control over mapping Quill Delta attributes to/from OpenXML `<w:r>` (runs) and `<w:p>` (paragraphs) safely without relying on third-party black boxes.

## 2. Supported Formatting
The `docx_format_mapper` currently translates between Quill Deltas and OpenXML for:
- Bold (`<w:b>`)
- Italic (`<w:i>`)
- Underline (`<w:u>`)
- Strikethrough (`<w:strike>`)
- Text Color (`<w:color>`)
- Text Highlight/Background (`<w:highlight>`)
- Font Size (`<w:sz>`)
- Paragraph Alignment (left, center, right, justify via `<w:jc>`)
- Headings (`<w:pStyle w:val="HeadingX">`)
- Basic Bullet Lists (Fallback naive parsing via `<w:numPr>`)
- Images (`<w:drawing>`) mapped to `word/media` and internal references.

## 3. Unsupported Formatting
- Complex table extraction/generation.
- Advanced nesting (lists within quotes, merged cells).
- Custom font families.
- Exact spacing/indentation values.
- Headers/Footers.

## 4. Import/Export Behavior
- **Import**: Extracts the `document.xml` using `archive`. Resolves relationships from `_rels/document.xml.rels`. Extracts images to the device's temporary directory, then saves them persistently into `LocalDocumentStorage`. Missing files or invalid zips return a handled error, surfacing a UI Snackbar rather than crashing.
- **Export**: Generates an in-memory zip archive. Builds `[Content_Types].xml` and relationships. Translates JSON Deltas into OpenXML tags. Automatically creates unique relationships for image embeds and copies the binary data into the zip's `word/media/` directory.

## 5. Security Handling
The parser uses standard `archive` and `xml` decoding. It looks specifically for `word/document.xml`. It does not execute or parse macros (`vbaProject.bin`). Extraction is heavily sandboxed to memory and the app's secure `ApplicationDocumentsDirectory`.

## 6. Testing Results
- Unit tests (`docx_test.dart`) successfully verify a "round-trip" conversion where text is written -> exported to DOCX -> imported from DOCX -> verified against the resulting Delta.
- Graceful failure is verified against corrupted non-zip files.
