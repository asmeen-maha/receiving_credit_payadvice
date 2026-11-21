import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cash_advance.dart';
import '../../data/models/pay_type.dart';
import 'buttons.dart';
import 'chips.dart';
import 'states.dart';
import 'surfaces.dart';

/// Plum pill toast at the bottom of the screen.
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: error ? const Color(0xFFFF9C94) : const Color(0xFF7EE2B4), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ));
}

/// Runs [task] behind a blocking ferris-wheel overlay.
Future<T> runWithProgress<T>(BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x38491630),
    builder: (_) => const PopScope(canPop: false, child: Center(child: FerrisLoader(size: 72))),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

/// Confirm dialog that shows how many rows and how much money will be verified,
/// broken down by pay type. Returns `true` when confirmed.
Future<bool> confirmVerify(
  BuildContext context, {
  required List<CashAdvance> items,
  required PayTypeNames payTypeNames,
  required String subtitle,
}) async {
  final groups = <String?, List<CashAdvance>>{};
  for (final item in items) {
    groups.putIfAbsent(item.accode, () => []).add(item);
  }
  final total = items.totalAmount;
  final single = items.length == 1;

  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x38491630),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassCard(
          color: const Color(0xF2FFFFFF),
          radius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const IconBadge(
                    icon: Icons.done_all_rounded, background: AppColors.verifiedSoft, foreground: AppColors.verified),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(single ? 'ยืนยันตรวจสอบรายการ' : 'ยืนยันตรวจสอบรายการทั้งหมด', style: AppText.display(18)),
                    Text(subtitle, style: AppText.body(13, color: AppColors.muted)),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              if (single)
                _SummaryRow(
                  icon: PayTypeStyle.of(items.first.accode).icon,
                  label: '${items.first.agentLabel} · ${items.first.rsvn ?? ''}',
                  amount: total,
                )
              else
                for (final entry in groups.entries)
                  _SummaryRow(
                    icon: PayTypeStyle.of(entry.key).icon,
                    label: '${payTypeNames.label(entry.key)} · ${entry.value.length} รายการ',
                    amount: entry.value.totalAmount,
                  ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Text('รวม ${items.length} รายการ', style: AppText.body(13, color: Colors.white70)),
                  const Spacer(),
                  Text('${formatMoney(total)} THB', style: AppText.display(18, color: Colors.white)),
                ]),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                PillButton(label: 'กลับ', style: PillStyle.white, onPressed: () => Navigator.pop(context, false)),
                const SizedBox(width: 10),
                PillButton(
                  label: single ? 'ยืนยันตรวจสอบ' : 'ยืนยันตรวจสอบ ${items.length} รายการ',
                  icon: Icons.check_rounded,
                  style: PillStyle.lagoon,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.amount});

  final IconData icon;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: AppText.body(13, color: AppColors.ink2))),
        Text(formatMoney(amount), style: AppText.display(14, weight: FontWeight.w500)),
      ]),
    );
  }
}
