// MOMO Core — Public API barrel export.
//
// Import this single file to access all MOMO Core functionality.
// Features and UI should only import from here, never from internal paths.

// Runtime
export 'runtime/runtime_engine.dart';
export 'runtime/runtime_config.dart';
export 'runtime/runtime_registry.dart';
export 'runtime/capability.dart';

// Adapters
export 'runtime/adapters/cloud_adapter.dart';
export 'runtime/adapters/cloud_provider_config.dart';
export 'runtime/adapters/llama_cpp_adapter.dart';
export 'runtime/adapters/litert_adapter.dart';
export 'runtime/adapters/stable_diffusion_adapter.dart';

// Inference
export 'inference/inference_router.dart';
export 'inference/inference_request.dart';
export 'inference/inference_result.dart';
export 'inference/inference_policy.dart';

// Memory
export 'memory/memory_engine.dart';
export 'memory/models/memory_entry.dart';

// Device
export 'device/device_engine.dart';
export 'device/device_profile.dart';
export 'device/performance_tier.dart';

// Storage
export 'storage/storage_service.dart';
export 'storage/hive_storage_impl.dart';

// Download
export 'download/download_engine.dart';

// Security
export 'security/security_engine.dart';

// Multimodal
export 'multimodal/modality.dart';

// Plugin
export 'plugin/plugin_interface.dart';
export 'plugin/plugin_manager.dart';

// Agent
export 'agent/momo_tool.dart';
export 'agent/core_tools.dart';
export 'agent/agent_loop.dart';
