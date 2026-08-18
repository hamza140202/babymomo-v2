# Babymomo Engineering Worklog

## Session Worklog — August 18, 2026

### 1. Studio Surface Aspect Ratio & Layout Architecture
- Wrapped the canvas container with `ConstrainedBox(maxHeight: 380)` and `AspectRatio(aspectRatio: _sizes[_selectedSize]['aspect'])`.
- Added dynamic selection state supporting `1:1 Square`, `9:16 Portrait`, `16:9 Landscape`, and `4:5 Social`.
- Changed image rendering from fixed crop to `BoxFit.contain` with `FilterQuality.high`.

### 2. Pollinations Flux UHD Synthesis Refactoring
- Completely eliminated `_renderCanvasArtwork` fallback which drew blurry abstract gradient blobs when offline or timed out.
- Engineered 8k resolution photographic art prompt wrappers:
  `"$prompt, 8k uhd, photorealistic, highly detailed, sharp crisp focus, octane lighting, vivid colors, masterwork, masterpiece"`.
- Set negative prompt filtering for blur, chromatic aberration, artifacts, and noise.
- Configured Dio with 40s connection timeout and 50s receive timeout with automatic SDXL-Turbo fallback.

### 3. Native MediaStore Channel & Public Storage Permissions
- Added `WRITE_EXTERNAL_STORAGE` and `requestLegacyExternalStorage="true"` to `AndroidManifest.xml`.
- Created `"com.momoai.babymomo/media_store"` MethodChannel in `MainActivity.kt` with `MediaScannerConnection.scanFile` targeting `/storage/emulated/0/Pictures/Babymomo/`.
- Configured startup permission requests (`Permission.storage`, `Permission.photos`, `Permission.notification`, `Permission.microphone`) in `MomoWinkSplashScreen`.

### 4. Interactive Mascot & Lounge Companion Experience
- Added on-tap interactive companion reaction in `LoungeSurface`: tapping the mascot triggers playful wink animation and random thought bubbles.
- Added active brain status card displaying local memory core status.

### 5. Chat & Studio Prompt Enhancements
- Added prompt starter chips in `ChatSurface` (`💡 Brainstorm ideas`, `✍️ Write a story`, `🧠 Explain physics`, `🎨 Studio prompt idea`).
- Added long-press message copy to clipboard with instant snackbar confirmation.
- Added "✨ Polish Prompt" magic lighting button in `StudioSurface` for automatic prompt enrichment.
- Added live real-time search bar and category filters in `HubSurface`.

### 6. Releases & CI Verification
- Build 38, Build 40, and Build 41 built on GitHub Actions with permanent release keystore.
- Downloaded and published `babymomo-build41.apk` (54.0 MB) to GitHub Releases `v2.0-build41`.
- Sent direct `.apk` download link to Telegram chat `1263089875`.
