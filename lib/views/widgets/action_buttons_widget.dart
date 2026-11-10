import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/xbox_commands.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';

class ActionButtonsWidget extends StatelessWidget {
  final double size;

  const ActionButtonsWidget({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();
    final btnSize = size * 0.30;
    final offset = (size - btnSize) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Y Button (Top / Yellow)
          Positioned(
            top: 0,
            left: offset,
            child: _buildActionButton(
              context: context,
              label: 'Y',
              button: XboxButton.y,
              color: XboxTheme.btnY,
              isPressed: vm.isPressed(XboxButton.y),
              size: btnSize,
            ),
          ),

          // A Button (Bottom / Green)
          Positioned(
            bottom: 0,
            left: offset,
            child: _buildActionButton(
              context: context,
              label: 'A',
              button: XboxButton.a,
              color: XboxTheme.btnA,
              isPressed: vm.isPressed(XboxButton.a),
              size: btnSize,
            ),
          ),

          // X Button (Left / Blue)
          Positioned(
            left: 0,
            top: offset,
            child: _buildActionButton(
              context: context,
              label: 'X',
              button: XboxButton.x,
              color: XboxTheme.btnX,
              isPressed: vm.isPressed(XboxButton.x),
              size: btnSize,
            ),
          ),

          // B Button (Right / Red)
          Positioned(
            right: 0,
            top: offset,
            child: _buildActionButton(
              context: context,
              label: 'B',
              button: XboxButton.b,
              color: XboxTheme.btnB,
              isPressed: vm.isPressed(XboxButton.b),
              size: btnSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required XboxButton button,
    required Color color,
    required bool isPressed,
    required double size,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => context.read<ControllerViewModel>().pressButton(button),
      child: AnimatedScale(
        scale: isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: isPressed ? 0.9 : 0.75),
                color.withValues(alpha: isPressed ? 0.5 : 0.35),
                const Color(0xFF141618),
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
            border: Border.all(
              color: color.withValues(alpha: isPressed ? 1.0 : 0.8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isPressed ? 0.8 : 0.3),
                blurRadius: isPressed ? 16 : 8,
                spreadRadius: isPressed ? 2 : 0,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.44,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
