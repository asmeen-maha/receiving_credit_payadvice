import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cash_advance.dart';
import '../../../data/models/pay_type.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/surfaces.dart';

const _thaiWeekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

/// Magenta hero tile: total amount, counts, pay-type split and a per-day bar chart.
class HeroTotalTile extends StatelessWidget {
  const HeroTotalTile({
    super.key,
    required this.rows,
    required this.payTypeNames,
    required this.startDate,
    required this.endDate,
  });

  final List<CashAdvance> rows;
  final PayTypeNames payTypeNames;
  final DateTime startDate;
  final DateTime endDate;

  /// Daily totals for the selected range (at most the last 14 days).
  List<(DateTime, double)> get _daily {
    final start = DateUtils.dateOnly(startDate);
    final end = DateUtils.dateOnly(endDate);
    final days = math.min(end.difference(start).inDays + 1, 14);
    final totals = <DateTime, double>{};
    for (final r in rows) {
      final d = DateTime.tryParse(r.trdate ?? '');
      if (d != null) totals.update(DateUtils.dateOnly(d), (v) => v + r.amountValue, ifAbsent: () => r.amountValue);
    }
    return [
      for (var i = days - 1; i >= 0; i--)
        (end.subtract(Duration(days: i)), totals[end.subtract(Duration(days: i))] ?? 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final agents = rows.map((r) => r.agentcode).toSet().length;
    final byType = <String?, double>{};
    for (final r in rows) {
      byType.update(r.accode, (v) => v + r.amountValue, ifAbsent: () => r.amountValue);
    }
    final daily = _daily;
    final peak = daily.fold(0.0, (m, d) => math.max(m, d.$2));
    final white82 = Colors.white.withOpacity(.82);

    return GlassCard(
      gradient: AppColors.heroGradient,
      shadow: AppColors.glow(AppColors.magentaDark, opacity: .75),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('ยอดเงินเชื่อ', style: AppText.body(13, color: white82, weight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text('TOTAL CREDIT', style: AppText.caption(color: white82)),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(TextSpan(children: [
              TextSpan(text: formatMoney(rows.totalAmount), style: AppText.display(50, color: Colors.white)),
              TextSpan(text: '  THB', style: AppText.display(18, color: white82, weight: FontWeight.w500)),
            ])),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _HeroChip(text: '${rows.length} รายการ'),
            _HeroChip(text: '$agents เอเย่นต์'),
            for (final e in byType.entries)
              _HeroChip(text: '${payTypeNames.label(e.key)} ${formatMoney(e.value)}', dot: PayTypeStyle.of(e.key).dot),
          ]),
          const Spacer(),
          if (daily.length > 1 && peak > 0) ...[
            Text('ยอดรายวัน · สูงสุด ${formatMoney(peak)}', style: AppText.body(12, color: white82)),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, d) in daily.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Tooltip(
                        message: '${DateFmt.thaiShort(d.$1)} · ${formatMoney(d.$2)}',
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Container(
                            height: math.max(4, 70 * d.$2 / peak),
                            decoration: BoxDecoration(
                              color: i == daily.length - 1 ? Colors.white : Colors.white.withOpacity(.28),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_thaiWeekdays[d.$1.weekday - 1]}${d.$1.day}',
                            style: AppText.body(10.5, color: white82),
                            maxLines: 1,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text, this.dot});

  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: Color.lerp(dot, Colors.white, .35), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(text, style: AppText.body(12.5, color: Colors.white)),
      ]),
    );
  }
}

/// Small KPI tile: big count, amount underneath, optional progress ring.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.icon,
    required this.iconBackground,
    this.progress,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;
  final IconData icon;
  final Color iconBackground;

  /// 0..1 — shows a ring instead of the icon.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w500)),
          const Spacer(),
          Text('$count', style: AppText.display(44, color: color)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: formatMoney(amount), style: AppText.display(13, color: AppColors.ink2, weight: FontWeight.w500)),
            TextSpan(
              text: progress == null ? ' ฿' : ' ฿ · ${(progress! * 100).round()}%',
              style: AppText.body(13, color: AppColors.muted),
            ),
          ])),
        ]),
        Positioned(
          right: 0,
          top: 0,
          child: progress == null
              ? IconBadge(icon: icon, background: iconBackground, foreground: color, size: 40)
              : SizedBox.square(
                  dimension: 44,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: iconBackground,
                  ),
                ),
        ),
      ]),
    );
  }
}

/// Report actions tile.
class ReportsTile extends StatelessWidget {
  const ReportsTile({
    super.key,
    required this.cashierCount,
    required this.canOpenIncome,
    required this.isSingleDay,
    required this.onIncome,
    required this.onCreditReport,
    required this.onUseToday,
  });

  final int cashierCount;
  final bool canOpenIncome;
  final bool isSingleDay;
  final VoidCallback onIncome;
  final VoidCallback onCreditReport;
  final VoidCallback onUseToday;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('รายงาน', style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text('REPORTS', style: AppText.caption()),
        ]),
        const SizedBox(height: 12),
        _ReportButton(
          icon: Icons.description_outlined,
          tint: AppColors.magentaSoft,
          color: AppColors.magenta,
          title: 'ใบนำส่งรายได้ฝ่ายบัตร',
          subtitle: 'Income remittance · ดูตัวอย่างก่อนพิมพ์',
          trailing: CountBadge(
            text: '$cashierCount พนักงาน',
            background: canOpenIncome ? AppColors.magenta : AppColors.ink.withOpacity(.08),
            foreground: canOpenIncome ? Colors.white : AppColors.muted,
          ),
          onTap: canOpenIncome ? onIncome : null,
          disabledReason:
              isSingleDay ? 'ไม่มีรายการของพนักงานในวันนี้' : 'ใบนำส่งรายได้สร้างได้ทีละวัน — เลือกวันเดียว',
        ),
        const SizedBox(height: 10),
        _ReportButton(
          icon: Icons.print_outlined,
          tint: AppColors.lagoonSoft,
          color: AppColors.lagoon,
          title: 'รายงานเงินรับล่วงหน้าเงินเชื่อ',
          subtitle:
              isSingleDay ? 'Advance payment & credit · แยกตามพนักงาน' : 'Advance payment & credit · ตามช่วงวันที่',
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          onTap: onCreditReport,
        ),
        const Spacer(),
        if (!isSingleDay)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.lagoon),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'ใบนำส่งรายได้ใช้ได้เมื่อเลือกวันเดียว  ', style: AppText.body(12, color: AppColors.muted)),
                WidgetSpan(
                  child: InkWell(
                    onTap: onUseToday,
                    child: Text('ใช้วันนี้',
                        style: AppText.body(12, color: AppColors.magenta, weight: FontWeight.w600)
                            .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.magenta)),
                  ),
                ),
              ])),
            ),
          ]),
      ]),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({
    required this.icon,
    required this.tint,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.disabledReason,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = Opacity(
      opacity: enabled ? 1 : .6,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconBadge(icon: icon, background: tint, foreground: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, overflow: TextOverflow.ellipsis, style: AppText.body(14, weight: FontWeight.w600)),
                  Text(subtitle, overflow: TextOverflow.ellipsis, style: AppText.body(12, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              trailing,
            ]),
          ),
        ),
      ),
    );
    return !enabled && disabledReason != null ? Tooltip(message: disabledReason, child: button) : button;
  }
}
