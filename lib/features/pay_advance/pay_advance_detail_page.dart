import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/surfaces.dart';

/// Data shown on the document detail screen.
class PayAdvanceDocument {
  final String docNo;
  final String status;
  final double amount;
  final String date;
  final String requester;
  final String agent;
  final String purpose;
  final String slipName;

  const PayAdvanceDocument({
    required this.docNo,
    required this.status,
    required this.amount,
    required this.date,
    required this.requester,
    required this.agent,
    required this.purpose,
    required this.slipName,
  });

  /// Placeholder until the document API exists.
  static const sample = PayAdvanceDocument(
    docNo: 'ADV-20260526-001',
    status: 'อนุมัติแล้ว · Approved',
    amount: 15000,
    date: '26 พ.ค. 2569',
    requester: 'John Doe',
    agent: '-',
    purpose: 'Client Meeting & Travel',
    slipName: 'สลิปรูปแบบ PDF',
  );
}

/// DRAFT — not linked from the navigation yet. Pay Advance document detail.
class PayAdvanceDetailPage extends StatelessWidget {
  const PayAdvanceDetailPage({super.key, this.document = PayAdvanceDocument.sample, this.onOpenSlip, this.onReport});

  final PayAdvanceDocument document;
  final VoidCallback? onOpenSlip;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final d = document;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.muted),
              label: Text('กลับไปที่เอกสาร Pay Advance', style: AppText.body(14, color: AppColors.muted)),
            ),
            const SizedBox(height: 12),
            // Amount tile
            GlassCard(
              radius: 24,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE0EC), Color(0xFFFFE9D4), Color(0xFFE2F5EF)],
                stops: [0, .6, 1],
              ),
              padding: const EdgeInsets.all(26),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(d.docNo, style: AppText.display(14, color: AppColors.ink2)),
                  const Spacer(),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.only(left: 10, right: 14),
                    decoration: BoxDecoration(
                      color: AppColors.verified,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: AppColors.glow(AppColors.verified, opacity: .8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(d.status, style: AppText.body(13, color: Colors.white, weight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 22),
                Text.rich(TextSpan(children: [
                  TextSpan(text: formatMoney(d.amount), style: AppText.display(60)),
                  TextSpan(text: '  THB', style: AppText.display(22, color: AppColors.muted, weight: FontWeight.w500)),
                ])),
                const SizedBox(height: 22),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  PillButton(label: 'รายงาน Pay Advance', icon: Icons.description_outlined, onPressed: onReport),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            // Info tiles
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(8),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                _Info(icon: Icons.description_outlined, label: 'เลขที่เอกสาร', eng: 'Doc No.', value: d.docNo),
                _Info(icon: Icons.calendar_month_rounded, label: 'วันที่', eng: 'Date', value: d.date, tint: 1),
                _Info(
                    icon: Icons.person_outline_rounded, label: 'ผู้ขอ', eng: 'Requester', value: d.requester, tint: 2),
                _Info(icon: Icons.confirmation_number_outlined, label: 'เอเย่นต์', eng: 'Agent', value: d.agent),
                _Info(
                    icon: Icons.track_changes_rounded,
                    label: 'วัตถุประสงค์',
                    eng: 'Purpose',
                    value: d.purpose,
                    tint: 1,
                    wide: true),
              ]),
            ),
            const SizedBox(height: 16),
            // Attachment
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const IconBadge(
                  icon: Icons.picture_as_pdf_rounded,
                  background: AppColors.dangerSoft,
                  foreground: AppColors.danger,
                  size: 56,
                  radius: 16,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('หลักฐานการชำระเงิน · Payment slip', style: AppText.body(12.5, color: AppColors.muted)),
                    Text(d.slipName, style: AppText.body(15, weight: FontWeight.w600)),
                  ]),
                ),
                PillButton(
                    label: 'เปิดดู', icon: Icons.visibility_outlined, style: PillStyle.soft, onPressed: onOpenSlip),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.label,
    required this.eng,
    required this.value,
    this.tint = 0,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String eng;
  final String value;
  final int tint;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    const tints = [
      (AppColors.magentaSoft, AppColors.magenta),
      (AppColors.marigoldSoft, AppColors.pending),
      (AppColors.lagoonSoft, AppColors.lagoon),
    ];
    return Container(
      width: wide ? double.infinity : 320,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.7), borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBadge(icon: icon, background: tints[tint].$1, foreground: tints[tint].$2, size: 34, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: label, style: AppText.body(12, color: AppColors.muted)),
              TextSpan(text: '  ${eng.toUpperCase()}', style: AppText.caption()),
            ])),
            Text(value, style: AppText.body(14, weight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
