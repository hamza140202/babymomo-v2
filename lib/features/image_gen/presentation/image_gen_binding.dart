import 'package:get/get.dart';
import 'image_gen_controller.dart';

class ImageGenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImageGenController>(() => ImageGenController());
  }
}

