# OTKAT Games installers

Two native wrappers are provided:

- Android: debug APK built from the local `web/` game catalogue and bundled assets.
- Windows: x64 NSIS installer built with Electron; game files are bundled locally.

## Build artifacts

GitHub Actions workflows:

- `.github/workflows/build-android-apk.yml`
- `.github/workflows/build-windows-exe.yml`

Each workflow uploads its output as a 30-day Actions artifact. Open the repository Actions tab, select a successful run, and download its artifact.

## Release limitations

The Android workflow currently produces a debug APK, signed with the standard debug key. It is suitable for installation/testing but is not a Play Store release. A private upload keystore and protected GitHub secrets are required for a production-signed APK.

The Windows installer is unsigned. Windows SmartScreen may show an unknown-publisher warning. A trusted code-signing certificate is required to remove that warning.

These builds bundle the browser game catalogue; they do not provide cloud accounts, multiplayer servers, or automatic updates.
