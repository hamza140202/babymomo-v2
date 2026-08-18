# Android AI & Mobile Release Rules

## 1. 🔑 Permanent Keystore Signing Invariant
- **Rule**: Every Android/Flutter release MUST be signed with the permanent release keystore (ndroid/app/babymomo_release.keystore, Alias: abymomo, Password: abymomo2026).
- **Enforcement**:
  - Keystore must remain committed to the repo (git add -f android/app/babymomo_release.keystore if .gitignore ignores *.keystore).
  - ndroid/app/build.gradle.kts must configure signingConfigs.create("release") referencing this file.
  - Never rely on ephemeral CI-generated debug certificates, as it causes Android signature mismatch and forces users to uninstall before updating.

## 2. 🎨 Branding & HTML Preview Fidelity Invariant
- **Rule**: When design specifications exist in ssets/branding/ (e.g. preview_wink_splash.html, preview_custom_icons.html, preview_screens.html, preview_logo.html):
  - Treat the embedded SVGs and cubic bezier curves as the **1:1 mathematical ground truth**.
  - **Splash Screen**: Render the free-standing porcelain mochi mascot (with organic cubic bezier body, 12° head tilt, and eyelash-flick wink arc) rather than placing it inside a square container icon box.
  - **Navigation Bar**: Render the custom 3D pastel mochi icon system (Lounge mascot on sunset badge, Chat speech pillow on violet badge, Studio magic star on rose badge, Hub neural chip on cyan badge).
  - Never approximate custom character or icon paths with default geometric primitives (plain circles/rectangles) when custom bezier paths are defined.

## 3. 🧠 Real Model Execution Guard (No Fake Canned Replies)
- **Rule**: When an on-device AI model is not loaded or active:
  - Never emit simulated or canned dialogue.
  - Immediately present a clear, actionable prompt directing the user to the Model Hub to download/mount a real model.

## 4. 📦 Direct APK Telegram Delivery
- **Rule**: The Telegram Bot API rejects file uploads greater than 50MB (the release APK is ~53.9MB).
- **Enforcement**:
  - Always attach the raw .apk file to a GitHub Release (2.0-buildXX).
  - Send the direct rowser_download_url link to Telegram so the user gets a 1-tap .apk download without zip extraction.
