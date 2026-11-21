import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cash_advance.dart';
import '../../../data/models/pay_type.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/chips.dart';

/// A pay-advance row drawn as a ticket: details on the left, amount and the
/// verify button on the tear-off stub. A [verified] ticket turns mint, shows
/// "ตรวจแล้ว" on the stub and gets a rubber stamp (design B).
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.item,
    required this.payTypeNames,
    required this.busy,
    required this.onVerify,
    this.verified = false,
  });

  final CashAdvance item;
  final PayTypeNames payTypeNames;
  final bool busy;
  final bool verified;

  /// `null` when the row cannot be verified (no account code).
  final VoidCallback? onVerify;

  static const stubWidth = 164.0;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: const _TicketClipper(notchFromRight: stubWidth, radius: 10),
      color: verified ? const Color(0xFFF4FBF7) : Colors.white,
      elevation: verified ? 3 : 6,
      shadowColor: verified ? const Color(0x301E9E6A) : const Color(0x40781E46),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        _body(),
        if (verified) const Positioned(right: stubWidth + 10, top: 10, child: _VerifiedStamp()),
      ]),
    );
  }

  Widget _body() {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF7EEF3), borderRadius: BorderRadius.circular(6)),
                child: Text(item.agentcode ?? '-', style: AppText.display(11.5, color: AppColors.muted)),
              ),
              const SizedBox(width: 8),
              Flexible(child: PayTypeChip(accode: item.accode, label: payTypeNames.label(item.accode), compact: true)),
            ]),
            const Spacer(),
            Text(item.agentname ?? '-',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(14.5, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              _Meta(label: 'RSVN', value: item.rsvn ?? '-'),
              const SizedBox(width: 14),
              _Meta(label: 'Voucher', value: item.voucher ?? '-'),
            ]),
          ]),
        ),
      ),
      CustomPaint(painter: _DashedLinePainter(verified: verified), child: const SizedBox(width: 2)),
      Container(
        width: stubWidth - 2,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                verified ? const [Color(0xFFF1FAF5), Color(0xFFE6F6EE)] : const [Color(0xFFFFF9FB), Color(0xFFFFF3F8)],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('AMOUNT · THB', style: AppText.caption()),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatMoney(item.amountValue), style: AppText.display(21)),
          ),
          const Spacer(),
          if (verified)
            const _VerifiedBadge()
          else
            PillButton(
              label: 'ตรวจสอบ',
              icon: Icons.check_rounded,
              style: PillStyle.soft,
              height: 34,
              busy: busy,
              onPressed: onVerify,
              disabledReason: 'รายการนี้ไม่มีรหัสบัญชี ตรวจสอบไม่ได้',
            ),
        ]),
      ),
    ]);
  }
}

/// Green "ตรวจแล้ว" label in place of the verify button.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFE0F5EA), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.verified),
        const SizedBox(width: 6),
        Text('ตรวจแล้ว', style: AppText.body(13, color: AppColors.verified, weight: FontWeight.w600)),
      ]),
    );
  }
}

/// Tilted rubber stamp over a verified ticket.
class _VerifiedStamp extends StatelessWidget {
  const _VerifiedStamp();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: -0.157, // -9°
        child: Opacity(
          opacity: .85,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 1, 10, 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.verified, width: 2.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ตรวจแล้ว',
                  style: AppText.display(15, color: AppColors.verified, weight: FontWeight.w600)
                      .copyWith(letterSpacing: .6, height: 1.3)),
              Text('VERIFIED',
                  style: AppText.body(9.5, color: AppColors.verified, weight: FontWeight.w600)
                      .copyWith(letterSpacing: 1, height: 1.1)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(text: '$label ', style: AppText.body(12, color: AppColors.muted)),
      TextSpan(text: value, style: AppText.display(13, color: AppColors.ink2)),
    ]));
  }
}

/// Rounded rectangle with two semicircle notches at the stub's tear line.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.notchFromRight, required this.radius});

  final double notchFromRight;
  final double radius;

  static const _corner = 20.0;

  /// Drawn with lines and arcs instead of `Path.combine`, which the HTML web
  /// renderer does not implement ("combinePaths not implemented").
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height, x = w - notchFromRight, r = radius;
    const c = _corner;
    const corner = Radius.circular(c);
    final notch = Radius.circular(r);
    return Path()
      ..moveTo(c, 0)
      ..lineTo(x - r, 0)
      ..arcToPoint(Offset(x + r, 0), radius: notch, clockwise: false) // top notch
      ..lineTo(w - c, 0)
      ..arcToPoint(Offset(w, c), radius: corner)
      ..lineTo(w, h - c)
      ..arcToPoint(Offset(w - c, h), radius: corner)
      ..lineTo(x + r, h)
      ..arcToPoint(Offset(x - r, h), radius: notch, clockwise: false) // bottom notch
      ..lineTo(c, h)
      ..arcToPoint(Offset(0, h - c), radius: corner)
      ..lineTo(0, c)
      ..arcToPoint(const Offset(c, 0), radius: corner)
      ..close();
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.notchFromRight != notchFromRight || old.radius != radius;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({this.verified = false});

  final bool verified;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = verified ? const Color(0xFFBFE6D2) : const Color(0xFFF1D4E1)
      ..strokeWidth = 2;
    for (var y = 14.0; y < size.height - 14; y += 9) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.verified != verified;
}
