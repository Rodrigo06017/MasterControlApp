import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/xbox_commands.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';

class ShouldersWidget extends StatelessWidget {
  const ShouldersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Shoulder (LB)
          _buildShoulderButton(
            context: context,
            label: 'LB',
            button: XboxButton.leftShoulder,
            isPressed: vm.isPressed(XboxButton.leftShoulder),
          ),

          // Right Shoulder (RB)
          _buildShoulderButton(
            context: context,
            label: 'RB',
            button: XboxButton.rightShoulder,
            isPressed: vm.isPressed(XboxButton.rightShoulder),
          ),
        ],
      ),
    );
  }

  Widget _buildShoulderButton({
    required BuildContext context,
    required String label,
    required XboxButton button,
    required bool isPressed,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => context.read<ControllerViewModel>().pressButton(button),
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: isPressed ? XboxTheme.xboxGreen.withValues(alpha: 0.3) : XboxTheme.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPressed ? XboxTheme.neonGreen : XboxTheme.divider,
              width: 1.8,
            ),
            boxShadow: [
              if (isPressed)
                BoxShadow(
                  color: XboxTheme.neonGreen.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPressed ? XboxTheme.neonGreen : XboxTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
