import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum PillStyle { primary, soft, white, lagoon, dark }

/// Rounded pill button. When [onPressed] is null the button is disabled and
/// [disabledReason] (if given) is shown as a tooltip.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = PillStyle.primary,
    this.height = 40,
    this.tooltip,
    this.disabledReason,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillStyle style;
  final double height;
  final String? tooltip;
  final String? disabledReason;

  /// Shows a spinner and blocks taps while true.
  final bool busy;
  final bool expand;

  ({Color bg, Color fg, List<BoxShadow>? shadow}) get _colors => switch (style) {
        PillStyle.primary => (
            bg: AppColors.magenta,
            fg: Colors.white,
            shadow: AppColors.glow(AppColors.magenta, opacity: .7)
          ),
        PillStyle.soft => (bg: AppColors.magentaSoft, fg: AppColors.magentaDark, shadow: null),
        PillStyle.white => (
            bg: Colors.white,
            fg: AppColors.ink2,
            shadow: AppColors.glow(const Color(0xFF781E46), opacity: .35)
          ),
        PillStyle.lagoon => (
            bg: AppColors.lagoon,
            fg: Colors.white,
            shadow: AppColors.glow(AppColors.lagoon, opacity: .6)
          ),
        PillStyle.dark => (bg: AppColors.ink, fg: Colors.white, shadow: null),
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final c = _colors;
    final bg = enabled || busy ? c.bg : AppColors.ink.withOpacity(.05);
    final fg = enabled || busy ? c.fg : AppColors.disabled;

    final button = DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: enabled ? c.shadow : null),
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: height * .42),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else if (icon != null)
                  Icon(icon, size: 18, color: fg),
                if (busy || icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis, style: AppText.body(13.5, color: fg, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final message = onPressed == null ? disabledReason : tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}

/// Small round white icon button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 40});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withOpacity(.75),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(dimension: size, child: Icon(icon, size: size * .45, color: AppColors.ink2)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
