import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/xbox_commands.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';

class NexusButtonWidget extends StatelessWidget {
  const NexusButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();
    final isConnected = vm.connectionState == ConnectionStateEnum.connected;
    final isPressed = vm.isPressed(XboxButton.nexus);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // View Button (Back / Two Windows)
        _buildSmallSysButton(
          context: context,
          icon: Icons.filter_none_rounded,
          label: 'VIEW',
          button: XboxButton.view,
          isPressed: vm.isPressed(XboxButton.view),
        ),

        const SizedBox(width: 24),

        // Glowing Xbox Nexus (Guide) Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => context.read<ControllerViewModel>().pressButton(XboxButton.nexus),
          child: AnimatedScale(
            scale: isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isConnected ? XboxTheme.neonGreen.withValues(alpha: 0.9) : Colors.white70,
                    isConnected ? XboxTheme.xboxGreen : const Color(0xFF2C3038),
                    const Color(0xFF0F1114),
                  ],
                  stops: const [0.2, 0.6, 1.0],
                ),
                border: Border.all(
                  color: isConnected ? XboxTheme.neonGreen : Colors.white38,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isConnected
                        ? XboxTheme.neonGreen.withValues(alpha: isPressed ? 0.8 : 0.45)
                        : Colors.white24,
                    blurRadius: isConnected ? 18 : 8,
                    spreadRadius: isConnected ? 3 : 1,
                  ),
                  const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(36, 36),
                  painter: _XboxLogoPainter(
                    color: isConnected ? Colors.black87 : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Menu Button (Start / Hamburger)
        _buildSmallSysButton(
          context: context,
          icon: Icons.menu_rounded,
          label: 'MENU',
          button: XboxButton.menu,
          isPressed: vm.isPressed(XboxButton.menu),
        ),
      ],
    );
  }

  Widget _buildSmallSysButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required XboxButton button,
    required bool isPressed,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => context.read<ControllerViewModel>().pressButton(button),
      child: AnimatedScale(
        scale: isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPressed ? XboxTheme.xboxGreen.withValues(alpha: 0.3) : XboxTheme.surfaceBright,
            shape: BoxShape.circle,
            border: Border.all(
              color: isPressed ? XboxTheme.neonGreen : XboxTheme.divider,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isPressed ? XboxTheme.neonGreen : XboxTheme.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the iconic Xbox logo sphere shape
class _XboxLogoPainter extends CustomPainter {
  final Color color;

  _XboxLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Iconic Xbox 'X' cuts
    final path = Path();
    // Top segment
    path.moveTo(w * 0.22, h * 0.18);
    path.quadraticBezierTo(w * 0.5, h * 0.40, w * 0.78, h * 0.18);
    path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.22, h * 0.18);

    // Bottom left segment
    path.moveTo(w * 0.14, h * 0.35);
    path.quadraticBezierTo(w * 0.38, h * 0.52, w * 0.25, h * 0.84);
    path.quadraticBezierTo(w * 0.05, h * 0.60, w * 0.14, h * 0.35);

    // Bottom right segment
    path.moveTo(w * 0.86, h * 0.35);
    path.quadraticBezierTo(w * 0.62, h * 0.52, w * 0.75, h * 0.84);
    path.quadraticBezierTo(w * 0.95, h * 0.60, w * 0.86, h * 0.35);

    // Center lower groove
    path.moveTo(w * 0.36, h * 0.88);
    path.quadraticBezierTo(w * 0.5, h * 0.65, w * 0.64, h * 0.88);
    path.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.36, h * 0.88);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _XboxLogoPainter oldDelegate) => oldDelegate.color != color;
}
