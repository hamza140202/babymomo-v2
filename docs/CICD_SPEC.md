# CI/CD & GitHub Actions Automation

## 1. Automated Build Pipeline
- File: `.github/workflows/android_release.yml`
- Triggers:
  - Push to `main` / `master`
  - Git Release Tags (`v*`)
  - Manual Trigger (`workflow_dispatch`)

## 2. Artifact Outputs
- Split-per-ABI APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
- Play Store Android App Bundle (`.aab`)
- Automatic GitHub Release creation with attached binary assets and change summaries.
