# Latest 2026 On-Device Mobile AI Models Research Report

## Executive Summary
Recent breakthroughs in on-device Small Language Models (SLMs) and mobile diffusion architectures offer optimal choices for **Babymomo v2** across 3 performance tiers on Android:

---

## 1. Top Recommended On-Device LLMs (GGUF Q4_K_M)

| Model | Parameters | Size (Q4_K_M) | RAM Req. | Key Strengths & Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Qwen 2.5 / 3** | **0.5B – 1.5B** | 400 MB – 1.1 GB | ~1.2 GB | **Highest intelligence-per-megabyte**. Exceptional multi-turn companion chat, roleplay, and low-latency token streaming on entry-level Android devices (4GB RAM). |
| **SmolLM2** | **360M – 1.7B** | 250 MB – 1.2 GB | ~0.8 GB | **Ultra-light battery saver**. Ideal for instant background tasks, tool routing, and lightweight companions without heating the device. |
| **Phi-4-mini** | **3.8B** | ~2.5 GB | ~4.2 GB | **Top reasoning & code logic**. Outperforms many 7B models in math, structured tool outputs, and reasoning. Requires 8GB+ RAM. |
| **Gemma 2 / 3** | **2B – 4B** | 1.6 GB – 2.8 GB | ~3.0 GB | Clean conversational tone, strong instruction following, and Google LiteRT-LM hardware optimization. |
| **MiniCPM-V 2.6** | **2.8B** | ~2.4 GB | ~3.8 GB | **Best on-device Vision-Language model** (OCR, photo comprehension, camera reasoning). |

---

## 2. Top Recommended On-Device Diffusion Models (Text-to-Image)

| Model | Checkpoint Format | Steps | Inference Time (Snapdragon 8 Gen 2/3) | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **DreamShaper 8 LCM** | FP16 Safetensors | 4 – 6 | ~3.5 – 5.0 seconds | High aesthetic speed, fantasy, anime, digital art. |
| **SDXL Turbo / Lightning** | FP16 Safetensors | 2 – 4 | ~2.5 – 4.0 seconds | Instant preview generation with high prompt fidelity. |
| **Absolute Reality v1.8.1**| FP16 Safetensors | 20 – 28| ~18 – 24 seconds | Studio photography & realistic portraits. |

---

## 3. Recommended Babymomo Catalog Mapping
- **Tier 1 (Fast & Battery Saver)**: `SmolLM2-1.7B-Instruct` or `Qwen2.5-1.5B-Instruct` (Q4_K_M).
- **Tier 2 (Balanced Companion)**: `Qwen2.5-3B-Instruct` or `Gemma-2-2B-IT` (Q4_K_M).
- **Tier 3 (High Quality & Logic)**: `Phi-4-mini-3.8B` (Q4_K_M).
- **Creative Studio (Image)**: `DreamShaper-v7-LCM` (4-step ultra-fast FP16).
