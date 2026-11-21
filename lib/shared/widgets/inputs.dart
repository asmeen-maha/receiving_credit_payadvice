import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Rounded search field with a clear button.
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'ค้นหาเอเย่นต์ รหัสหรือชื่อ',
    this.width = 280,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          style: AppText.body(13.5),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.faint),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ล้างคำค้นหา',
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// Date chip: calendar icon, main label and an optional hint line underneath.
class DatePill extends StatelessWidget {
  const DatePill({super.key, required this.label, required this.onTap, this.hint, this.badge});

  final String label;
  final String? hint;

  /// Small text after the label, e.g. "วันนี้" or "7 วัน".
  final String? badge;

  /// `null` disables the pill.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: hint == null ? 44 : 52,
          padding: const EdgeInsets.only(left: 14, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.magenta),
                  const SizedBox(width: 8),
                  Text(label, style: AppText.body(13.5, weight: FontWeight.w600)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Text(badge!, style: AppText.body(12, color: AppColors.muted)),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.faint),
                ],
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(hint!, style: AppText.body(11.5, color: AppColors.muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
