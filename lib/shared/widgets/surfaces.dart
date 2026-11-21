import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Blush page background with soft pink / peach / mint glows.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.blush),
      child: Stack(
        children: [
          const _Glow(alignment: Alignment(-1.05, -1.2), color: Color(0xFFFFD1E4), size: 1100),
          const _Glow(alignment: Alignment(1.1, -1.1), color: Color(0xFFFFE4C8), size: 900),
          const _Glow(alignment: Alignment(0.5, 1.4), color: Color(0xFFD3F1EA), size: 1200),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.size});

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: size,
            height: size * .65,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [color, color.withOpacity(0)], stops: const [0, .62]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted tile. Uses translucency instead of a blur so it stays cheap on Flutter web.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.color = AppColors.glass,
    this.gradient,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: gradient == null ? Border.all(color: AppColors.glassBorder) : null,
        boxShadow: shadow ?? AppColors.softShadow,
      ),
      child: child,
    );
  }
}

/// Rounded square holding an icon (used in tiles and list items).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 42,
    this.radius = 14,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: foreground, size: size * .48),
    );
  }
}
