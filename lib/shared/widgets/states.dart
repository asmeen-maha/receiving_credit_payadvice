import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Spinning ferris wheel — the app's loading indicator.
class FerrisLoader extends StatefulWidget {
  const FerrisLoader({super.key, this.size = 56, this.color = AppColors.magenta});

  final double size;
  final Color color;

  @override
  State<FerrisLoader> createState() => _FerrisLoaderState();
}

class _FerrisLoaderState extends State<FerrisLoader> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.attractions_rounded, size: widget.size, color: widget.color),
    );
  }
}

enum StateKind { loading, empty, error }

/// Friendly placeholder card for loading / empty / error.
class StateView extends StatelessWidget {
  const StateView.loading({super.key, this.message = 'ดึงข้อมูลจากเซิร์ฟเวอร์'})
      : kind = StateKind.loading,
        title = 'กำลังโหลดรายการ…',
        actionLabel = null,
        onAction = null;

  const StateView.empty({
    super.key,
    this.message = 'ยังไม่มีรายการในช่วงวันที่นี้ ลองเลือกวันอื่น หรือกลับมาดูอีกครั้งภายหลัง',
    this.actionLabel,
    this.onAction,
  })  : kind = StateKind.empty,
        title = 'ไม่พบข้อมูล';

  const StateView.error({super.key, required this.onAction})
      : kind = StateKind.error,
        title = 'เชื่อมต่อไม่สำเร็จ',
        message = 'ระบบยังไม่ได้รับข้อมูลจากเซิร์ฟเวอร์ รายการเดิมยังปลอดภัย กดลองอีกครั้งได้เลย',
        actionLabel = 'ลองอีกครั้ง';

  final StateKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Widget art = switch (kind) {
      StateKind.loading => const FerrisLoader(),
      StateKind.empty => const IconBadge(
          icon: Icons.manage_search_rounded,
          background: AppColors.magentaSoft,
          foreground: AppColors.magenta,
          size: 64,
          radius: 22,
        ),
      StateKind.error => const IconBadge(
          icon: Icons.wifi_off_rounded,
          background: AppColors.dangerSoft,
          foreground: AppColors.danger,
          size: 64,
          radius: 22,
        ),
    };

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art,
              const SizedBox(height: 14),
              Text(title, style: AppText.display(16)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: AppText.body(13, color: AppColors.muted)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                PillButton(
                  label: actionLabel!,
                  icon: kind == StateKind.error ? Icons.refresh_rounded : Icons.calendar_month_rounded,
                  style: kind == StateKind.error ? PillStyle.primary : PillStyle.soft,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
