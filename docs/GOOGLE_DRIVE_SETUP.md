# Google Drive API Setup for OpenWPS

To enable Google Drive integration in OpenWPS, you must configure a project in the Google Cloud Console.

## 1. Create a Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select an existing one.

## 2. Enable APIs
1. Go to "APIs & Services" > "Library".
2. Search for "Google Drive API" and click "Enable".

## 3. Configure OAuth Consent Screen
1. Go to "APIs & Services" > "OAuth consent screen".
2. Choose User Type (Internal or External). For general use, choose "External".
3. Fill in the required application details (App name: OpenWPS, User support email, Developer contact email).
4. Add the following scopes:
   - `https://www.googleapis.com/auth/drive.file`
     - Allows OpenWPS to see, edit, create, and delete only the specific Google Drive files you use with this app. This is the minimum required scope for safety.
     - **Note:** Do NOT request full `https://www.googleapis.com/auth/drive` access.
   - `email` and `profile` (for identifying the connected account).
5. Save and continue. Add test users if your app is in "Testing" status.

## 4. Create OAuth Client ID
1. Go to "APIs & Services" > "Credentials".
2. Click "Create Credentials" > "OAuth client ID".
3. Select "Android" as the Application type.
4. Enter a name (e.g., "OpenWPS Android").
5. Package name: `org.openwps.app` (or the actual package name of your app from `android/app/build.gradle`).
6. SHA-1 certificate fingerprint:
   - For development, get this from your debug keystore:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - For production, use the SHA-1 from your release keystore or Google Play Console App Signing.
7. Click "Create".

## 5. Add Configuration to Project
In Android, the `google_sign_in` plugin handles authentication automatically if the package name and SHA-1 fingerprint match the registered OAuth Client ID. There are no client secrets to store in the codebase for Android client-side OAuth.

**CRITICAL SECURITY WARNING:**
- NEVER commit a `google-services.json` or any JSON containing Client Secrets or API Keys to GitHub.
- With this configuration, the client secret is NOT used by the Android app; authentication relies on the SHA-1 fingerprint.
