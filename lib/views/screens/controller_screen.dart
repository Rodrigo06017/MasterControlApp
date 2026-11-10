import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/dpad_widget.dart';
import '../widgets/media_remote_widget.dart';
import '../widgets/nexus_button_widget.dart';
import '../widgets/shoulders_widget.dart';
import 'discovery_sheet.dart';

class ControllerScreen extends StatelessWidget {
  const ControllerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();
    final isConnected = vm.connectionState == ConnectionStateEnum.connected;

    return Scaffold(
      backgroundColor: XboxTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? XboxTheme.neonGreen : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: isConnected ? XboxTheme.neonGreen : Colors.redAccent,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isConnected ? (vm.activeDevice?.name ?? 'XBOX') : 'DESCONECTADO',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find_rounded, color: XboxTheme.neonGreen),
            tooltip: 'Buscar o conectar Xbox',
            onPressed: () => DiscoverySheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Mode Toggle Switch (Gamepad vs Películas/Media)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: XboxTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: XboxTheme.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        context: context,
                        label: 'MANDO JUEGOS',
                        icon: Icons.sports_esports_rounded,
                        isSelected: vm.currentMode == ControllerMode.gamepad,
                        onTap: () => vm.setMode(ControllerMode.gamepad),
                      ),
                    ),
                    Expanded(
                      child: _buildModeTab(
                        context: context,
                        label: 'PELÍCULAS / MEDIA',
                        icon: Icons.movie_filter_rounded,
                        isSelected: vm.currentMode == ControllerMode.media,
                        onTap: () => vm.setMode(ControllerMode.media),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Main Body Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: vm.currentMode == ControllerMode.gamepad
                    ? _buildGamepadLayout(context)
                    : const MediaRemoteWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? XboxTheme.xboxGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: XboxTheme.xboxGreen.withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : XboxTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : XboxTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamepadLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final controlSize = (screenWidth * 0.42).clamp(140.0, 190.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Bumpers (LB, RB)
          const ShouldersWidget(),

          const SizedBox(height: 28),

          // Nexus (Guide), View, Menu center cluster
          const NexusButtonWidget(),

          const SizedBox(height: 36),

          // Core Controls (D-Pad on left, A/B/X/Y on right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // D-Pad
                DPadWidget(size: controlSize),

                // Action Buttons
                ActionButtonsWidget(size: controlSize),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Quick Connection status hint
          Consumer<ControllerViewModel>(
            builder: (context, vm, _) {
              if (vm.connectionState != ConnectionStateEnum.connected) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: XboxTheme.neonGreen,
                      side: const BorderSide(color: XboxTheme.xboxGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.wifi_rounded, size: 20),
                    label: const Text('Conectar a tu Xbox en red local'),
                    onPressed: () => DiscoverySheet.show(context),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
