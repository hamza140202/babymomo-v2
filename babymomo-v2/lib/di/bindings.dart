import 'package:get/get.dart';
import '../momo_core/momo_core.dart';
import '../features/image_gen/sd_models/sd_model_controller.dart';
import '../features/image_gen/sd_models/sd_runtime_manager.dart';

/// Global dependency injection bindings.
///
/// Initializes all MOMO Core services as GetxServices (app-lifetime singletons).
/// Called once during app startup before any UI is rendered.
class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // ── Security (must be first) ──
    if (!Get.isRegistered<SecurityEngine>()) {
      Get.put<SecurityEngine>(SecurityEngine(), permanent: true);
    }

    // ── Storage (must be second) ──
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(HiveStorageImpl(), permanent: true);
    }

    // ── Runtime Registry ──
    final registry = RuntimeRegistry();
    Get.put<RuntimeRegistry>(registry, permanent: true);

    // ── Inference Router ──
    Get.put<InferenceRouter>(
      InferenceRouter(registry: registry),
      permanent: true,
    );

    // ── Device Engine ──
    if (!Get.isRegistered<DeviceEngine>()) {
      Get.put<DeviceEngine>(DeviceEngine(), permanent: true);
    }

    // ── Memory Engine ──
    Get.put<MemoryEngine>(
      MemoryEngine(storage: Get.find<StorageService>()),
      permanent: true,
    );

    // ── Download Engine ──
    if (!Get.isRegistered<DownloadEngine>()) {
      Get.put<DownloadEngine>(DownloadEngine(), permanent: true);
    }

    // ── Tool Registry ──
    final toolRegistry = ToolRegistry();
    toolRegistry.register(WebSearchTool());
    toolRegistry.register(CalculatorTool());
    toolRegistry.register(StableDiffusionTool());
    Get.put<ToolRegistry>(toolRegistry, permanent: true);

    // ── Plugin Manager ──
    final pluginManager = PluginManager();
    pluginManager.configure(PluginContext(
      runtimeRegistry: registry,
      storage: Get.find<StorageService>(),
      toolRegistry: toolRegistry,
    ));
    Get.put<PluginManager>(pluginManager, permanent: true);

    // ── Runtime Adapters ──
    // TODO: In a real app, API key is loaded from secure storage.
    // Here we use a placeholder or assume it's set by the user later.
    final cloudAdapter = CloudAdapter(
      providerConfig: const CloudProviderConfig(
        provider: CloudProvider.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
        apiKey: 'YOUR_GEMINI_API_KEY_HERE', // Placeholder
        modelId: 'gemini-2.0-flash',
      ),
    );
    // Initialize async later or here (registry does not strictly require pre-init,
    // but the adapter needs init before infer).
    cloudAdapter.initialize(const RuntimeConfig(
      contextLength: 4096,
      useGPU: true,
    ));
    registry.register(cloudAdapter);

    // Local AI (llama.cpp) Adapter
    final localAdapter = LlamaCppAdapter();
    localAdapter.initialize(const RuntimeConfig(
      contextLength: 2048,
      useGPU: true,
    ));
    registry.register(localAdapter);

    // On-device Stable Diffusion Adapter
    final sdAdapter = StableDiffusionAdapter();
    sdAdapter.initialize(const RuntimeConfig(
      contextLength: 256,
      useGPU: true,
    ));
    registry.register(sdAdapter);

    // ── SD Model Controller & Runtime Manager (global — needed by Settings + ImageGen) ──
    if (!Get.isRegistered<SdModelController>()) {
      Get.put<SdModelController>(SdModelController(), permanent: true);
    }
    if (!Get.isRegistered<SdRuntimeManager>()) {
      Get.put<SdRuntimeManager>(SdRuntimeManager(), permanent: true);
    }
  }
}

