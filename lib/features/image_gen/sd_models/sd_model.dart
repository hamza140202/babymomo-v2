/// Represents a locally-runnable Stable Diffusion checkpoint model.
class SdModel {
  final String id;
  final String name;
  final String version;
  final String description;
  final double sizeGB;
  final String downloadUrl;
  final String expectedHash; // SHA-256 of the .safetensors file
  final String baseModel; // e.g. "SD 1.5", "SDXL"
  final List<String> styleTags; // e.g. ["photorealistic", "portraits"]
  final bool isLcm; // LCM models need fewer steps (~4-8)
  final bool isUncensored;
  final int recommendedSteps;
  final double recommendedCfg;

  const SdModel({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.sizeGB,
    required this.downloadUrl,
    required this.expectedHash,
    required this.baseModel,
    required this.styleTags,
    this.isLcm = false,
    this.isUncensored = false,
    required this.recommendedSteps,
    required this.recommendedCfg,
  });
}

enum SdModelStatus {
  notDownloaded,
  downloading,
  paused,
  downloaded,
  active,
  loading,
}
