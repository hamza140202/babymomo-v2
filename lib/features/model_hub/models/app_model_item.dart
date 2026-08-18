import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Represents a downloadable on-device AI model in the Hub.
class AppModelItem {
  final String id;
  final String name;
  final String type;
  final String sizeStr;
  final String url;
  final String description;
  final int notifId;

  final RxBool isDownloaded = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxBool isPaused = false.obs;
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
      AppModelItem(
        id: 'qwen2_5_0_5b',
        name: 'Qwen-2.5-0.5B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '390 MB',
        url: 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
        description: 'Super-compact 390MB companion model. Blazing fast cold-start speed and ultra-low battery use.',
        notifId: 1002,
      ),
      AppModelItem(
        id: 'smollm2_1_7b',
        name: 'SmolLM2-1.7B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '1.0 GB',
        url: 'https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf',
        description: 'Ultra-lightweight on-device language model. Fast conversational response, zero battery drain.',
        notifId: 1001,
      ),
      AppModelItem(
        id: 'qwen2_5_1_5b',
        name: 'Qwen-2.5-1.5B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '1.1 GB',
        url: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
        description: 'Top-tier on-device reasoning and empathetic conversational companion dialogue.',
        notifId: 1003,
      ),
      AppModelItem(
        id: 'qwen2_5_3b',
        name: 'Qwen-2.5-3B-Instruct (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '2.2 GB',
        url: 'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
        description: 'Deep empathy, extensive vocabulary, and intelligent storytelling for rich long conversations.',
        notifId: 1004,
      ),
      AppModelItem(
        id: 'phi_4_mini',
        name: 'Phi-4-mini 3.8B (Q4_K_M)',
        type: 'Text LLM',
        sizeStr: '2.5 GB',
        url: 'https://huggingface.co/microsoft/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-q4_k_m.gguf',
        description: 'Exceptional math, code logic, and complex analytical reasoning capabilities.',
        notifId: 1005,
      ),
      AppModelItem(
        id: 'bk_sdm_tiny',
        name: 'BK-SDM Tiny (FP16) — 280 MB',
        type: 'Image Diffusion',
        sizeStr: '280 MB',
        url: 'https://huggingface.co/nota-ai/bk-sdm-tiny/resolve/main/bk-sdm-tiny.tar.gz',
        description: 'Ultra-lightweight 280MB mobile diffusion — fastest possible image generation on device.',
        notifId: 1006,
      ),
      AppModelItem(
        id: 'dreamshaper_lcm',
        name: 'DreamShaper 8 LCM (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.1 GB',
        url: 'https://huggingface.co/Lykon/dreamshaper-8-lcm/resolve/main/dreamshaper8LCM_lcm.safetensors',
        description: 'High quality 4-step local text-to-image generation — cinematic results.',
        notifId: 1007,
      ),
      AppModelItem(
        id: 'absolute_reality',
        name: 'Absolute Reality v1.8.1 (FP16)',
        type: 'Image Diffusion',
        sizeStr: '2.1 GB',
        url: 'https://huggingface.co/digiplay/AbsoluteReality_v1.8.1/resolve/main/absolutereality_v181.safetensors',
        description: 'Hyper-realistic photography and cinema-grade portrait outputs.',
        notifId: 1008,
      ),
    ];
  }
}
