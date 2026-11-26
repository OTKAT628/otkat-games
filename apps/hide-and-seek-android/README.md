# OTKAT Hide & Seek — Android wrapper

This folder contains the Capacitor configuration used to package the mobile 3D browser playtest as an Android APK.

## Build

The GitHub Actions workflow `.github/workflows/build-hide-and-seek-apk.yml` creates the Capacitor Android project in CI, copies `web/hide-and-seek/3d.html` as the app entry point, builds a debug APK, and uploads it as a workflow artifact.

No signing key or paid service is required for a debug APK. The first build must be downloaded from the successful workflow run's Artifacts section and installed manually on Android. Android may ask to allow installation from the browser or file manager.

## Notes

- The app currently loads the Three.js runtime from jsDelivr, so an internet connection is required at launch.
- This is a debug/test APK, not a Play Store release.
- The project does not contain production signing credentials.
- The 3D playtest is still an early prototype; multiplayer, persistence, polished animation, and final assets are not included.
