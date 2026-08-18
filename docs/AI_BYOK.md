# OpenWPS AI Assistant (BYOK Architecture)

## Overview
OpenWPS features a secure, local-first AI assistant integrated directly into the Writer, Spreadsheet, Presentation, and PDF modules. To maintain privacy and a strict no-backend architecture, the AI system uses a **Bring Your Own Key (BYOK)** model.

## Architecture
- **No Custom Server:** The Flutter application communicates directly with the selected third-party AI provider API (e.g., OpenAI).
- **Extensible Providers:** `AIProvider` is an abstract interface. Currently, `OpenAIProvider` and a `MockAIProvider` (for testing) are implemented.
- **Secure Storage:** API keys are stored securely on the device using `flutter_secure_storage`. They are never logged, exported, or stored in plaintext JSON/history.

## Setup & Configuration
1. Navigate to **Settings** -> **AI Preferences**.
2. Toggle **Enable AI Features**.
3. Select an **AI Provider** (e.g., OpenAI) and the desired model.
4. Enter your provider's API key securely.
5. Tap **Test Connection** to verify.

## Security & Privacy
- **Key Masking:** Once saved, keys are masked in the UI (e.g., `sk-...1234`).
- **Explicit Context:** OpenWPS never sends your entire document to the AI automatically. Only the explicitly selected text, cell, or slide content is transmitted.
- **Cost Warning:** Users are warned that using the AI feature will incur costs against their own API provider quota.

## Module Integrations
- **Writer:** Select text and tap the AI button (sparkles icon) to generate, rewrite, or explain text. You can insert or replace the text in the document.
- **Spreadsheet:** Select a cell and ask the AI to generate a formula or explain data. Generated formulas require explicit user confirmation before being applied.
- **Presentation:** Generate slide titles or content, inserting the AI output as a new text element on the canvas.
- **PDF:** Analyze or explain selected text in a read-only PDF view.

## Known Limitations
- PDF contextual AI selection integration is deferred because the locked pdfrx 2.4.7 API does not expose the required selection functionality in the current Flutter environment.

## Testing
A `MockAIProvider` is included for automated testing, simulating network delays and streaming text without requiring a real API key.
