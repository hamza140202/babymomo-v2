# MOMO Framework Architecture & Specification

The **MOMO Framework** is the operating intelligence engine powering Babymomo. It is modular, runtime-agnostic, offline-first, and designed to turn smartphones into self-sufficient AI nodes.

---

## 1. MOMO Core Engines Breakdown

```
                   +---------------------------+
                   |     MOMO App Surface      |
                   +---------------------------+
                                 |
+-------------------------------------------------------------+
|                          MOMO CORE                          |
|                                                             |
|  +--------------------+             +--------------------+  |
|  |   Device Engine    |             |  Inference Router  |  |
|  | - Thermal profile  |             | - Local vs Cloud   |  |
|  | - RAM / GPU Tier   |             | - Speed / Quality  |  |
|  +--------------------+             +--------------------+  |
|                                                             |
|  +--------------------+             +--------------------+  |
|  |   Memory Engine    |             |    Agent Engine    |  |
|  | - Short/Long Term  |             | - Tool execution   |  |
|  | - Semantic Tags    |             | - Autonomous loop  |  |
|  +--------------------+             +--------------------+  |
|                                                             |
|  +--------------------+             +--------------------+  |
|  |  Download Engine   |             |  Security Engine   |  |
|  | - Chunked weights  |             | - Keystore encrypt |  |
|  | - MD5 Verification |             | - Local privacy    |  |
|  +--------------------+             +--------------------+  |
+-------------------------------------------------------------+
                                 |
+-------------------------------------------------------------+
|                     MOMO Native Bridges                     |
|            (Pigeon IPC -> Kotlin -> C++ JNI)                |
|                                                             |
|  - llama.cpp (GGUF)                 - LiteRT-LM             |
|  - Stable Diffusion (FP16/LCM)      - OpenCL / Vulkan       |
+-------------------------------------------------------------+
```

---

## 2. Engine Specifications

### 2.1 Device Engine (`DeviceEngine`)
- Profiles hardware at startup: Total RAM, Available RAM, GPU Vendor, Vulkan API level, battery state.
- Assigns a dynamic `PerformanceTier`:
  - **Low (e.g. 4-6GB RAM)**: Cloud fallback preferred, quantized 4-bit small LLMs (1B-2B).
  - **Medium (e.g. 8GB RAM)**: 3B-4B Q4_K_M GGUFs, 4-step LCM image generation.
  - **High (e.g. 12GB+ RAM)**: 7B-8B GGUFs, Full local diffusion pipelines with Vulkan acceleration.

### 2.2 Inference Router (`InferenceRouter`)
- Evaluates user policy (`localOnly`, `cloudFallback`, `cloudOnly`, `bestQuality`).
- Dispatches inference requests dynamically to either:
  - Local Native Bridge (`InferenceBridge` / `ImageGenBridge`)
  - Cloud Providers (`OpenAI`, `Anthropic`, `Gemini`, `OpenRouter`, `NVIDIA NIM`, `Kimi`).

### 2.3 Memory Engine (`MemoryEngine`)
- Offline-first long-term memory store.
- Structures conversations into session trees, user preferences, and fact extraction.
- Integrates directly into prompts as contextual grounding without polluting system prompts.

### 2.4 Agent Engine (`AgentLoop` & `MomoTool`)
- Orchestrates multi-step reasoning.
- Supports tool calling (e.g. device actions, calculator, web search fallback, memory recall).

### 2.5 Download Engine (`DownloadEngine`)
- Resumable, background download manager for multi-gigabyte GGUF and Stable Diffusion model checkpoints.
- MD5 / SHA-256 integrity verification before mounting weights into memory.

### 2.6 Security Engine (`SecurityEngine`)
- Encrypts API keys and user memory data with hardware-backed Android Keystore (`AES-GCM-256`).
- Ensures zero unauthorized data exfiltration.

---

## 3. Play Store Readiness Rules
- **No raw technical quantization terms exposed**: Present simple user presets (*"Fast"*, *"Balanced"*, *"High Quality"*).
- **Graceful degradation**: If local RAM is insufficient, seamlessly guide the user to download smaller models or use cloud keys.
- **Battery & Thermal safety**: Throttle or pause heavy diffusion/GGUF generation when device exceeds thermal thresholds.
