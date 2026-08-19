# OpenWPS Security

- **Data Privacy**: No tracking backend. All user data generated and viewed is strictly offline or sent to their linked Google Drive.
- **Secrets Management**: No hardcoded API keys. BYOK implementation uses `flutter_secure_storage` to encrypt API keys provided by the user using Android keystore logic locally.
- **File Access**: Import tools use proper memory streams and local path directories restricting arbitrary path resolution or traversal payloads via OpenXML.
