import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../momo_ui/theme/momo_theme.dart';
import '../../momo_ui/icons/momo_custom_icons.dart';
import 'navigation_controller.dart';
import '../lounge/presentation/lounge_surface.dart';
import '../chat/presentation/chat_surface.dart';
import '../studio/presentation/studio_surface.dart';
import '../model_hub/presentation/hub_surface.dart';

/// Clean, modular Navigation Shell hosting the 4 core surfaces.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Obx(() {
      final isDark = controller.isDarkMode.value;

      return Scaffold(
        backgroundColor:
            isDark ? MomoColors.background : MomoColors.lightBackground,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            LoungeSurface(),
            ChatSurface(),
            StudioSurface(),
            HubSurface(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark
                ? MomoColors.surface.withOpacity(0.92)
                : MomoColors.lightSurface,
            border: Border(
                top: BorderSide(color: MomoColors.glassBorder, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                  controller,
                  0,
                  'Lounge',
                  MomoCustomIcons.lounge(
                      isActive: controller.currentIndex.value == 0),
                  isDark),
              _navItem(
                  controller,
                  1,
                  'Chat',
                  MomoCustomIcons.chat(
                      isActive: controller.currentIndex.value == 1),
                  isDark),
              _navItem(
                  controller,
                  2,
                  'Studio',
                  MomoCustomIcons.studio(
                      isActive: controller.currentIndex.value == 2),
                  isDark),
              _navItem(
                  controller,
                  3,
                  'Hub',
                  MomoCustomIcons.hub(
                      isActive: controller.currentIndex.value == 3),
                  isDark),
            ],
          ),
        ),
      );
    });
  }

  Widget _navItem(NavigationController ctrl, int idx, String label, Widget icon,
      bool isDark) {
    return GestureDetector(
      onTap: () => ctrl.changeTab(idx),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Obx(() => Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: ctrl.currentIndex.value == idx
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: ctrl.currentIndex.value == idx
                      ? (isDark ? Colors.white : MomoColors.primary)
                      : MomoColors.textSecondary,
                ),
              )),
        ],
      ),
    );
  }
}
