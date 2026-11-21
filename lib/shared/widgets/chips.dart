import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Colors and icon for a pay type (by account code).
class PayTypeStyle {
  final Color background;
  final Color foreground;
  final Color dot;
  final IconData icon;

  const PayTypeStyle(this.background, this.foreground, this.dot, this.icon);

  static const cash =
      PayTypeStyle(AppColors.marigoldSoft, AppColors.marigoldText, AppColors.marigold, Icons.payments_outlined);
  static const card =
      PayTypeStyle(AppColors.magentaSoft, AppColors.magentaDark, AppColors.magenta, Icons.credit_card_rounded);
  static const transfer =
      PayTypeStyle(AppColors.lagoonSoft, AppColors.lagoonText, AppColors.lagoon, Icons.swap_horiz_rounded);
  static const other = PayTypeStyle(Color(0xFFF1ECF0), AppColors.muted, AppColors.faint, Icons.receipt_long_outlined);

  static PayTypeStyle of(String? accode) => switch (accode) {
        AccountCode.cash => cash,
        AccountCode.creditCard => card,
        AccountCode.transfer => transfer,
        _ => other,
      };
}

/// Pill showing the pay type name with its icon and color.
class PayTypeChip extends StatelessWidget {
  const PayTypeChip({super.key, required this.accode, required this.label, this.compact = false});

  final String? accode;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = PayTypeStyle.of(accode);
    return Container(
      height: compact ? 24 : 28,
      padding: const EdgeInsets.only(left: 9, right: 12),
      decoration: BoxDecoration(color: s.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 15, color: s.foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(compact ? 11.5 : 12.5, color: s.foreground, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// "ตรวจแล้ว" / "รอตรวจ" label with icon.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.verified : AppColors.pending;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(verified ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(verified ? 'ตรวจแล้ว' : 'รอตรวจ', style: AppText.body(12.5, color: color, weight: FontWeight.w600)),
      ],
    );
  }
}

/// Small rounded count badge (e.g. "5 พนักงาน").
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.text,
    this.background = AppColors.magenta,
    this.foreground = Colors.white,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
      child: Text(text, style: AppText.display(12, color: foreground)),
    );
  }
}

/// Selectable filter pill ("ทั้งหมด 11").
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dot,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.muted;
    return Material(
      color: selected ? AppColors.ink : Colors.white.withOpacity(.7),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 7),
              ],
              Text(label, style: AppText.body(13, color: fg, weight: FontWeight.w500)),
              if (count != null) ...[
                const SizedBox(width: 7),
                Text('$count', style: AppText.display(12, color: selected ? Colors.white : AppColors.ink2)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-square initials avatar with a tint picked from [seed].
class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.name, required this.seed});

  final String name;
  final String seed;

  static const _tints = [
    (AppColors.magentaSoft, AppColors.magentaDark),
    (AppColors.marigoldSoft, AppColors.marigoldText),
    (AppColors.lagoonSoft, AppColors.lagoonText),
    (Color(0xFFEEE8FF), Color(0xFF5B47C9)),
  ];

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final text = words.map((w) => String.fromCharCode(w.runes.first)).join().toUpperCase();
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tints[seed.hashCode.abs() % _tints.length];
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint.$1, borderRadius: BorderRadius.circular(12)),
      child: Text(_initials, style: AppText.display(12, color: tint.$2)),
    );
  }
}
