# Native Bridge & NDK Specification

## 1. Type-Safe Pigeon Interfaces
Pigeon handles IPC across Flutter and Kotlin to prevent runtime messaging bugs.

### APIs:
1. `DeviceApi`: Battery, RAM, GPU vendor, thermal status.
2. `InferenceApi`: GGUF loading, context allocation, streaming token generation.
3. `ImageGenApi`: SD model weight init, prompt conditioning, LCM sampling steps, bitmap callbacks.
4. `SecurityApi`: Hardware-backed Android Keystore token storage.

## 2. CMake & C++ Build System
- Android NDK: `r27b`
- Compilation targets: `arm64-v8a`, `armeabi-v7a`
- Accelerators: OpenCL / Vulkan backend enabled dynamically when GPU compute is supported.
