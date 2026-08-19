# Known Limitations

- **XLSX Native Import**: Temporarily unsupported and disabled natively due to unmaintained Dart package environment fragmentation.
- **PDF Text Selection with AI Context**: Deferred due to limitations and stability issues in `pdfrx` 2.4.7 for text extractions reliably.
- **Advanced Presentation PPTX Support**: Currently acts as a text extraction and basic slide text rendering fallback export due to lack of comprehensive unmaintained OpenXML PPTX packages in Dart.
- **Extensive UI Design Polish**: Further iterations of UX flows could be better consolidated using an overarching design system like Material 3 defaults for all modals.
