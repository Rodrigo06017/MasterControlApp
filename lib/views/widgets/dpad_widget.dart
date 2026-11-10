import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/xbox_commands.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';

class DPadWidget extends StatelessWidget {
  final double size;

  const DPadWidget({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();
    final armSize = size / 3;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Cross Shadow & Glow
          Container(
            width: size,
            height: armSize,
            decoration: BoxDecoration(
              color: XboxTheme.dpadBody,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XboxTheme.dpadBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
          ),
          Container(
            width: armSize,
            height: size,
            decoration: BoxDecoration(
              color: XboxTheme.dpadBody,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XboxTheme.dpadBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
          ),
          // Center core
          Container(
            width: armSize * 0.95,
            height: armSize * 0.95,
            decoration: const BoxDecoration(
              color: XboxTheme.dpadBody,
              shape: BoxShape.circle,
            ),
          ),

          // UP Button
          Positioned(
            top: 0,
            child: _buildDPadButton(
              context: context,
              button: XboxButton.dpadUp,
              icon: Icons.keyboard_arrow_up_rounded,
              isPressed: vm.isPressed(XboxButton.dpadUp),
              width: armSize,
              height: armSize,
            ),
          ),

          // DOWN Button
          Positioned(
            bottom: 0,
            child: _buildDPadButton(
              context: context,
              button: XboxButton.dpadDown,
              icon: Icons.keyboard_arrow_down_rounded,
              isPressed: vm.isPressed(XboxButton.dpadDown),
              width: armSize,
              height: armSize,
            ),
          ),

          // LEFT Button
          Positioned(
            left: 0,
            child: _buildDPadButton(
              context: context,
              button: XboxButton.dpadLeft,
              icon: Icons.keyboard_arrow_left_rounded,
              isPressed: vm.isPressed(XboxButton.dpadLeft),
              width: armSize,
              height: armSize,
            ),
          ),

          // RIGHT Button
          Positioned(
            right: 0,
            child: _buildDPadButton(
              context: context,
              button: XboxButton.dpadRight,
              icon: Icons.keyboard_arrow_right_rounded,
              isPressed: vm.isPressed(XboxButton.dpadRight),
              width: armSize,
              height: armSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton({
    required BuildContext context,
    required XboxButton button,
    required IconData icon,
    required bool isPressed,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => context.read<ControllerViewModel>().pressButton(button),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isPressed ? XboxTheme.xboxGreen.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 36,
            color: isPressed ? XboxTheme.neonGreen : XboxTheme.textPrimary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
