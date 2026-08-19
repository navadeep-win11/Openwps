# OpenWPS Architecture

## Overview
OpenWPS is a Flutter application focusing on editing DOCX, XLSX, PPTX and PDF files locally, integrating with Google Drive for sync, and optional BYOK AI using various LLMs providers. It uses `flutter_quill` for document rich text editing and `pdfrx` for PDF viewer.

## Core Modules
- **Writer**: Uses `flutter_quill` for text editing. Implements OpenXML conversion for DOCX support natively via `xml` and `archive`.
- **Spreadsheet**: Uses `pluto_grid` for viewing grid data. Basic evaluators to read formulas. Implements partial OpenXML conversion.
- **Presentation**: Custom Canvas-based 1920x1080 logical layout for slides. Exports to basic PPTX formats natively.
- **PDF**: Uses `pdfrx` 2.4.7 for viewing. Annotations added as JSON overlay.
- **Drive**: Syncs via `google_sign_in` directly with drive.
- **AI**: Integrates with OpenAI optionally providing an API Key locally stored.

## Storage & Backend
Local first using `path_provider` to a document directory format caching. No custom backend required or provided.
