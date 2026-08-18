import 'package:get/get.dart';
import 'model_hub_controller.dart';

/// BabyMomo — Model Hub bindings.
class ModelHubBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModelHubController>(() => ModelHubController());
  }
}
