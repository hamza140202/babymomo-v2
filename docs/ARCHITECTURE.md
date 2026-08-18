# Architecture & System Design — Babymomo v2

## 1. Vision & Strategy
Babymomo is an offline-first, consumer-centric mobile AI platform powered by the MOMO framework.

## 2. Layered Architecture

```
+-------------------------------------------------------------+
|               Babymomo Experience Layer                     |
|  (Chat UI, Image Studio, Model Hub, Mascot Companion)       |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|                      MOMO Core Engine                       |
| - Device Profiler    - Inference Router   - Memory Engine   |
| - Download Manager   - Security/Keystore  - Agent Loop      |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|                 Pigeon Type-Safe IPC Bridge                 |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|              Native Android (Kotlin + C++ NDK)              |
| - llama.cpp / LiteRT (GGUF)   - Stable Diffusion (FP16/LCM) |
| - OpenCL / Vulkan Acceleration                              |
+-------------------------------------------------------------+
```

## 3. Storage & Persistence
- Hive CE for persistent chat threads, model metadata, and vector/semantic memory chunks.
- Android Keystore for secure cloud API tokens.
