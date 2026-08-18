# PDF Compatibility Report

## 1. Selected PDF Engine
`pdfrx`

## 2. Why selected
`pdfrx` is an active, modern Flutter PDF viewer build on top of pdfium. It provides rich functionality, solid performance, text selection, and annotation capabilities. It offers great rendering performance and provides standard APIs to search the document.

## 3. Supported PDF Features
- **Rendering:** Uses pdfium, highly accurate.
- **Search:** Text search with highlighting.
- **Text Selection:** Text selection is supported.
- **Page Navigation:** Supported.
- **Zoom:** Built-in matrix transformation zoom.

## 4. Annotation Support
- **Highlight:** Implemented via a sidecar/overlay approach natively on top of the rendered PDF page.
- **Pen/Freehand:** Implemented as Flutter paths on top of the page.
- **Notes:** Text notes attached to specific coordinates.

## 5. Export Support
Not fully supported by default without additional native integrations. Annotations will be saved in an OpenWPS sidecar JSON format.

## 6. Security Handling
Untrusted files are safe as pdfium disables javascript and external links by default or can be configured.

## 7. Known Limitations
- Modifying the original PDF is not natively available via pdfrx. Annotations are kept in a separate layer.
