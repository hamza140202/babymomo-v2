# Privacy Policy for Babymomo AI

**Last Updated**: August 18, 2026  
**Application Package**: `com.momoai.babymomo`  
**Developer Contact**: support@momoai.com

---

## 1. Overview & Core Philosophy
**Babymomo** is an on-device, local-first artificial intelligence companion application. We are deeply committed to user privacy and believe that your conversations, thoughts, and creative prompts should remain strictly yours.

---

## 2. On-Device Local Processing
- **Offline First**: All core natural language processing (via quantized GGUF models) and on-device image diffusion (via Stable Diffusion NDK) execute locally on your physical device.
- **No Conversation Uploads**: Your chat history, prompt inputs, and generated artwork are never transmitted to external servers or sold to third parties.
- **Hardware-Backed Encryption**: Any saved API tokens or user session metadata are encrypted using the Android Keystore system (`AES-GCM-256`).

---

## 3. Data Collection & Permissions

| Category | Collected? | Purpose & Scope |
| :--- | :--- | :--- |
| **Personal Identity / Contacts** | **NO** | Never accessed or collected. |
| **Location Data** | **NO** | Never requested or tracked. |
| **Chat & Image Content** | **NO** | Processed entirely in volatile device memory and local offline storage. |
| **Crash & Diagnostics** | **NO** | Zero telemetry trackers embedded in local mode. |

### Permissions Used:
- `INTERNET` & `ACCESS_NETWORK_STATE`: Used exclusively when you explicitly opt to download new open-source model weights from HuggingFace, or when using cloud fallback mode with your own API key.
- `VIBRATE`: Provides tactile haptic feedback during interactive button presses.

---

## 4. AI-Generated Content & Safety
Babymomo implements on-device moderation mechanisms to help ensure safe and respectful interactions. Users have the ability to reset and delete local conversation history at any time with a single tap.

---

## 5. Third-Party Services
If you explicitly configure and enable optional cloud provider keys (such as OpenAI, Anthropic, or Google Gemini), data sent through those specific requests is governed by the respective provider's privacy policy.

---

## 6. Contact Us
For any questions regarding this Privacy Policy or data security practices, please open an issue in this repository or contact:  
**Email**: privacy@momoai.com
