import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'sd_model.dart';

/// Repository of available Stable Diffusion checkpoint models.
/// Download URLs point to publicly accessible HuggingFace safetensors files.
class SdModelRepository {
  SdModelRepository._();

  /// The four SD models available for local on-device generation.
  static const List<SdModel> models = [
    SdModel(
      id: 'absolute_reality',
      name: 'Absolute Reality',
      version: '1.8.1',
      description:
          'Hyper-realistic photography-grade outputs. Stunning portrait, landscape, and product photography — indistinguishable from real photos.',
      sizeGB: 2.13,
      downloadUrl:
          'https://huggingface.co/digiplay/AbsoluteReality_v1.8.1/resolve/main/absolutereality_v181.safetensors',
      // Hash left empty — we use sure-shot approach (no deletion on mismatch)
      expectedHash: '',
      baseModel: 'SD 1.5',
      styleTags: ['photorealistic', 'portrait', 'landscape', 'DSLR'],
      isUncensored: true,
      recommendedSteps: 28,
      recommendedCfg: 7.0,
    ),
    SdModel(
      id: 'cyberrealistic',
      name: 'CyberRealistic',
      version: 'v4.1 FP16',
      description:
          'Ultra-sharp, cinema-quality realism. Trained on vast photography datasets. Best model for faces, skin texture, and natural lighting.',
      sizeGB: 2.03,
      downloadUrl:
          'https://huggingface.co/cyberdelia/CyberRealistic/resolve/main/CyberRealistic_V4.1_FP16.safetensors',
      expectedHash: '',
      baseModel: 'SD 1.5',
      styleTags: ['cinematic', 'faces', 'photorealistic', 'sharp'],
      isUncensored: true,
      recommendedSteps: 30,
      recommendedCfg: 7.5,
    ),
    SdModel(
      id: 'dreamshaper_lcm',
      name: 'DreamShaper 8 LCM',
      version: 'v7 LCM',
      description:
          'Lightning-fast generation via LCM distillation. Requires only 4-8 steps! Creative, artistic, fantasy and dreamlike imagery at blazing speed.',
      sizeGB: 2.13,
      downloadUrl:
          'https://huggingface.co/SimianLuo/LCM_Dreamshaper_v7/resolve/main/LCM_Dreamshaper_v7_4k.safetensors',
      expectedHash: '',
      baseModel: 'SD 1.5 LCM',
      styleTags: ['fast', 'artistic', 'fantasy', 'creative'],
      isLcm: true,
      isUncensored: true,
      recommendedSteps: 6,
      recommendedCfg: 2.0,
    ),
    SdModel(
      id: 'realistic_vision',
      name: 'Realistic Vision',
      version: 'v5.1',
      description:
          'Fine-tuned for stunning human portraits and everyday scenes. Unmatched skin tones, natural hair, and authentic environments.',
      sizeGB: 1.98,
      downloadUrl:
          'https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors',
      expectedHash: '',
      baseModel: 'SD 1.5',
      styleTags: ['portrait', 'realistic', 'skin', 'natural'],
      isUncensored: true,
      recommendedSteps: 25,
      recommendedCfg: 7.0,
    ),
  ];

  /// Returns the local storage path for a given model file.
  /// Stored in app's external storage: /models/sd/{id}.safetensors
  static Future<String> getModelPath(String modelId) async {
    final extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/models/sd/$modelId.safetensors';
    }
    return '${extDir.path}/models/sd/$modelId.safetensors';
  }

  /// Returns true if the model file exists on disk.
  static Future<bool> isModelDownloaded(String modelId) async {
    final path = await getModelPath(modelId);
    return File(path).existsSync();
  }

  /// Returns [SdModel] by id, null if not found.
  static SdModel? findById(String id) {
    try {
      return models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
