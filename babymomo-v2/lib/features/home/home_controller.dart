import 'package:get/get.dart';

/// BabyMomo — Home Controller.
///
/// Manages home screen state and bottom navigation indices:
/// - 0: Home Dashboard
/// - 1: Chat Arena (ChatPage)
/// - 2: Create Studio (ImageGenPage)
/// - 3: Model Hub (ModelHubPage)
/// - 4: Settings Hub (SettingsPage)
class HomeController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}

