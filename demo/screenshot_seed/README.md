# Screenshot Demo Seed

This folder contains a privacy-safe demo dataset for Android emulator screenshots.

Files:
- `install_android_emulator.ps1`: Generates the current `SharedPreferences` payloads and can install them into a connected emulator.
- `files/`: Placeholder document files referenced by the seeded document metadata.
- `generated/`: Output folder for the exact `cruises_json_v3`, `document_store_v1`, `share_intake_queue_v1`, and `FlutterSharedPreferences.xml` artifacts.

Quick use:
1. Install and launch the app once on an Android emulator.
2. Close the app.
3. Run `powershell -ExecutionPolicy Bypass -File .\demo\screenshot_seed\install_android_emulator.ps1`
4. Reopen the app.

Notes:
- The script targets package `de.mailsmart.cruiseplanner`.
- It seeds one fictional cruise and placeholder documents only.
- It overwrites the app's `FlutterSharedPreferences.xml` on the emulator, so a clean screenshot emulator is recommended.
