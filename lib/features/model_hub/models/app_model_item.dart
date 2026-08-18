import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Represents an AI model (Text LLM, Vision AI, or Image Diffusion) available in the Brain Hub.
class AppModelItem {
  final String id;
  final String name;
  final String type; // 'Text LLM', 'Vision AI', 'Image Diffusion'
  final String sizeStr;
  final String url;
  final String description;
  final int notifId;
  final bool isVision;

  // Reactive state observables
  final RxBool isDownloaded = false.obs;
  final RxBool isDownloading = false.obs;
  final RxBool isPaused = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString statusMessage = ''.obs;

  CancelToken? _cancelToken;

  AppModelItem({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeStr,
    required this.url,
    required this.description,
    required this.notifId,
    this.isVision = false,
  });

  CancelToken createCancelToken() {
    _cancelToken = CancelToken();
    return _cancelToken!;
  }

  void cancelDownload() {
    _cancelToken?.cancel('user_paused');
  }

  static List<AppModelItem> getDefaultCatalog() {
    return [
      // ─── 👁️ VISION MULTIMODAL AI ───
      AppModelItem(
        id: 'qwen2_vl_2b',
        name: 'Qwen2-VL-2B-Instruct (Q4_K_M)',
        type: 'Vision AI',
        sizeStr: '940 MB',
        url: 'https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/Qwen2-VL-2B-Instruct-Q4_K_M.gguf',
        description: 'Vision-capable on-device multimodal AI — can understand, analyze, and visually explain photos and documents.',
        notifId: 1000,
        isVision: true,
      ),

      // ─── 🧠 REASONING & TEXT COMPANIONS ───
      AppModelItem(
        id: 'deepseek_r1_1_5b',
        name: 'DeepSeek-R1-Distill-Qwen 1.5B (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '1.06 GB',
        url: 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
        description: 'Deep reasoning model with chain-of-thought thinking tokens — exceptional logic and problem solving.',
        notifId: 1001,
      ),
      AppModelItem(
        id: 'llama3_2_1b',
        name: 'Llama-3.2-1B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '770 MB',
        url: 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
        description: 'Meta\'s ultra-compact 1B mobile model — blazing speed, low RAM footprint, and sharp dialogue.',
        notifId: 1002,
      ),
      AppModelItem(
        id: 'dolphin_qwen',
        name: 'Dolphin-3.0-Qwen2.5-1.5B (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '940 MB',
        url: 'https://huggingface.co/bartowski/Dolphin3.0-Qwen2.5-1.5B-GGUF/resolve/main/Dolphin3.0-Qwen2.5-1.5B-Q4_K_M.gguf',
        description: 'Uncensored Dolphin 3.0 conversational engine — fast, unrestricted, and highly creative.',
        notifId: 1003,
      ),
      AppModelItem(
        id: 'smollm2_uncensored',
        name: 'SmolLM2-1.7B-Uncensored (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '1.06 GB',
        url: 'https://huggingface.co/mradermacher/SmolLM2-1.7B-Instruct-Uncensored-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Uncensored.Q4_K_M.gguf',
        description: 'Ultra-compact unrestricted companion assistant for natural personal conversations.',
        notifId: 1004,
      ),
      AppModelItem(
        id: 'gemma2_abliterated',
        name: 'Gemma-2-2B-Abliterated (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '1.6 GB',
        url: 'https://huggingface.co/bartowski/gemma-2-2b-it-abliterated-GGUF/resolve/main/gemma-2-2b-it-abliterated-Q4_K_M.gguf',
        description: 'Google Gemma 2 2B abliterated — permanently uncensored, brilliant reasoning and general chat.',
        notifId: 1005,
      ),
      AppModelItem(
        id: 'qwen2_5_3b',
        name: 'Qwen-2.5-3B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '2.0 GB',
        url: 'https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf',
        description: 'Best balance of deep empathy, extensive vocabulary, and rich companion storytelling.',
        notifId: 1006,
      ),
      AppModelItem(
        id: 'qwen2_5_0_5b',
        name: 'Qwen-2.5-0.5B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '390 MB',
        url: 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
        description: 'Super-compact 390MB companion model. Instant cold-start and ultra-low battery consumption.',
        notifId: 1007,
      ),

      // ─── 🎨 CREATIVE DIFFUSION STUDIO ───
      AppModelItem(
        id: 'dreamshaper_lcm',
        name: 'DreamShaper 8 LCM (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.0 GB',
        url: 'https://huggingface.co/Lykon/DreamShaper/resolve/main/DreamShaper8_LCM.safetensors',
        description: 'High-speed 4-step local text-to-image generation — cinematic results.',
        notifId: 1008,
      ),
      AppModelItem(
        id: 'cyberrealistic_v8',
        name: 'CyberRealistic V8 (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.0 GB',
        url: 'https://huggingface.co/cyberdelia/CyberRealistic/resolve/main/CyberRealistic_V8_FP16.safetensors',
        description: 'Photorealistic, uncensored on-device image generation — FP16 optimized for mobile.',
        notifId: 1009,
      ),
      AppModelItem(
        id: 'anylora_anime',
        name: 'AnyLoRA Anime Stylized (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.0 GB',
        url: 'https://huggingface.co/Lykon/AnyLoRA/resolve/main/AnyLoRA_noVae_fp16-pruned.safetensors',
        description: 'Highly versatile stylized and Anime visual art generation.',
        notifId: 1010,
      ),
      AppModelItem(
        id: 'absolute_reality',
        name: 'Absolute Reality v1.8.1 (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.0 GB',
        url: 'https://huggingface.co/digiplay/AbsoluteReality_v1.8.1/resolve/main/absolutereality_v181.safetensors',
        description: 'Hyper-realistic photography and cinema-grade portrait outputs.',
        notifId: 1011,
      ),
      AppModelItem(
        id: 'bk_sdm_tiny',
        name: 'BK-SDM Tiny (FP16)',
        type: 'Image Diffusion',
        sizeStr: '1.2 GB',
        url: 'https://huggingface.co/nota-ai/bk-sdm-tiny/resolve/main/unet/diffusion_pytorch_model.safetensors',
        description: 'Ultra-lightweight on-device diffusion — fastest possible mobile image generation.',
        notifId: 1012,
      ),
    ];
  }
}
