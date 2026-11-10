import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/xbox_commands.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';
import 'dpad_widget.dart';

class MediaRemoteWidget extends StatelessWidget {
  const MediaRemoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Navigation DPad for Streaming Menus
          const Text(
            'NAVEGACIÓN EN PANTALLA',
            style: TextStyle(
              color: XboxTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const DPadWidget(size: 190),

          const SizedBox(height: 24),

          // Quick Select & Back Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPillButton(
                context: context,
                label: 'SELECCIONAR (A)',
                color: XboxTheme.btnA,
                icon: Icons.check_circle_outline_rounded,
                onTap: () => vm.pressButton(XboxButton.a),
              ),
              const SizedBox(width: 16),
              _buildPillButton(
                context: context,
                label: 'VOLVER (B)',
                color: XboxTheme.btnB,
                icon: Icons.arrow_back_rounded,
                onTap: () => vm.pressButton(XboxButton.b),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(color: XboxTheme.divider, height: 1),
          const SizedBox(height: 24),

          // Media Player Controls Title
          const Text(
            'REPRODUCCIÓN Y PELÍCULAS',
            style: TextStyle(
              color: XboxTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Main Play / Pause & Seek Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind (<<)
              _buildRoundMediaBtn(
                context: context,
                icon: Icons.replay_10_rounded,
                size: 54,
                isPressed: vm.isPressed(XboxMediaCommand.rewind),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.rewind),
              ),
              const SizedBox(width: 24),

              // Huge Play/Pause Button
              _buildRoundMediaBtn(
                context: context,
                icon: Icons.play_arrow_rounded,
                secondaryIcon: Icons.pause_rounded,
                size: 78,
                isLargePrimary: true,
                isPressed: vm.isPressed(XboxMediaCommand.playPauseToggle),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.playPauseToggle),
              ),
              const SizedBox(width: 24),

              // Fast Forward (>>)
              _buildRoundMediaBtn(
                context: context,
                icon: Icons.forward_10_rounded,
                size: 54,
                isPressed: vm.isPressed(XboxMediaCommand.fastForward),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.fastForward),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Secondary Media Controls: Prev, Stop, Next
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniMediaBtn(
                context: context,
                icon: Icons.skip_previous_rounded,
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.previous),
              ),
              const SizedBox(width: 20),
              _buildMiniMediaBtn(
                context: context,
                icon: Icons.stop_rounded,
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.stop),
              ),
              const SizedBox(width: 20),
              _buildMiniMediaBtn(
                context: context,
                icon: Icons.skip_next_rounded,
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.next),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(color: XboxTheme.divider, height: 1),
          const SizedBox(height: 24),

          // Audio / Volume Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildVolumeCard(
                context: context,
                icon: Icons.volume_down_rounded,
                label: 'VOL -',
                isPressed: vm.isPressed(XboxMediaCommand.volumeDown),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.volumeDown),
              ),
              _buildVolumeCard(
                context: context,
                icon: Icons.volume_off_rounded,
                label: 'MUTE',
                isPressed: vm.isPressed(XboxMediaCommand.mute),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.mute),
              ),
              _buildVolumeCard(
                context: context,
                icon: Icons.volume_up_rounded,
                label: 'VOL +',
                isPressed: vm.isPressed(XboxMediaCommand.volumeUp),
                onTap: () => vm.pressMediaCommand(XboxMediaCommand.volumeUp),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundMediaBtn({
    required BuildContext context,
    required IconData icon,
    IconData? secondaryIcon,
    required double size,
    bool isLargePrimary = false,
    required bool isPressed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLargePrimary ? XboxTheme.xboxGreen : XboxTheme.surfaceBright,
            border: Border.all(
              color: isLargePrimary ? XboxTheme.neonGreen : XboxTheme.divider,
              width: isLargePrimary ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isLargePrimary)
                BoxShadow(
                  color: XboxTheme.neonGreen.withValues(alpha: isPressed ? 0.6 : 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.50,
              color: isLargePrimary ? Colors.white : XboxTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMediaBtn({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: XboxTheme.surfaceBright,
          border: Border.all(color: XboxTheme.divider, width: 1.2),
        ),
        child: Center(
          child: Icon(icon, size: 22, color: XboxTheme.textPrimary.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  Widget _buildVolumeCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPressed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPressed ? XboxTheme.xboxGreen.withValues(alpha: 0.25) : XboxTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPressed ? XboxTheme.neonGreen : XboxTheme.divider,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: isPressed ? XboxTheme.neonGreen : XboxTheme.textPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPressed ? XboxTheme.neonGreen : XboxTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
