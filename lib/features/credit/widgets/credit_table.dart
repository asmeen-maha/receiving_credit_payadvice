import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cash_advance.dart';
import '../../../data/models/pay_type.dart';
import '../../../shared/widgets/chips.dart';

/// Column layout shared by the header and every row.
class _Cols extends StatelessWidget {
  const _Cols(this.cells);

  /// check, agent, rsvn, voucher, payType, amount, status, action
  final List<Widget> cells;

  static const _flex = [0, 34, 10, 10, 16, 13, 11, 0];
  static const _fixed = {0: 56.0, 7: 150.0};
  static const _right = {5, 7};

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < cells.length; i++)
        _fixed.containsKey(i)
            ? SizedBox(
                width: _fixed[i],
                child: Align(
                    alignment: _right.contains(i) ? Alignment.centerRight : Alignment.centerLeft, child: cells[i]),
              )
            : Expanded(
                flex: _flex[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                      alignment: _right.contains(i) ? Alignment.centerRight : Alignment.centerLeft, child: cells[i]),
                ),
              ),
    ]);
  }
}

class CreditTableHeader extends StatelessWidget {
  const CreditTableHeader({super.key});

  Widget _h(String thai, String eng) => Text.rich(
      TextSpan(children: [
        TextSpan(text: thai, style: AppText.body(12, color: AppColors.muted, weight: FontWeight.w600)),
        TextSpan(text: '  ${eng.toUpperCase()}', style: AppText.caption()),
      ]),
      overflow: TextOverflow.ellipsis);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: _Cols([
        _h('ตรวจ', ''),
        _h('ชื่อเอเย่นต์', 'Agent'),
        _h('การจอง', 'RSVN'),
        _h('บัตร', 'Voucher'),
        _h('ประเภทการจ่าย', 'PayType'),
        _h('จำนวนเงิน', 'Amount'),
        _h('สถานะ', 'Status'),
        _h('ใบรับ', 'Voucher print'),
      ]),
    );
  }
}

/// One credit row card.
class CreditRow extends StatelessWidget {
  const CreditRow({
    super.key,
    required this.item,
    required this.payTypeNames,
    required this.busy,
    required this.onVerify,
    required this.onPrintVoucher,
  });

  final CashAdvance item;
  final PayTypeNames payTypeNames;

  /// A request for this row is in flight.
  final bool busy;
  final VoidCallback? onVerify;
  final VoidCallback? onPrintVoucher;

  @override
  Widget build(BuildContext context) {
    final verified = item.isVerified;
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: verified ? AppColors.rowVerified : AppColors.row,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _Cols([
        VerifyToggle(verified: verified, busy: busy, onTap: onVerify),
        Row(children: [
          AgentAvatar(name: item.agentname ?? '', seed: item.agentcode ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.agentname ?? '-',
                      overflow: TextOverflow.ellipsis, style: AppText.body(13.5, weight: FontWeight.w600)),
                  Text(item.agentcode ?? '',
                      style: AppText.display(11.5, color: AppColors.faint, weight: FontWeight.w500)),
                ]),
          ),
        ]),
        Text(item.rsvn ?? '-', style: AppText.display(13, color: AppColors.ink2, weight: FontWeight.w500)),
        Text(item.voucher ?? '-', style: AppText.display(13, color: AppColors.ink2, weight: FontWeight.w500)),
        PayTypeChip(accode: item.accode, label: payTypeNames.label(item.accode)),
        Text(formatMoney(item.amountValue), style: AppText.display(15)),
        StatusLabel(verified: verified),
        _PrintButton(enabled: verified && !busy, onTap: onPrintVoucher),
      ]),
    );
  }
}

/// Round dashed circle that fills green once the row is verified.
class VerifyToggle extends StatelessWidget {
  const VerifyToggle({super.key, required this.verified, required this.onTap, this.busy = false});

  final bool verified;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = onTap != null && !verified && !busy;
    return Tooltip(
      message:
          verified ? 'ตรวจสอบแล้ว' : (onTap == null ? 'รายการนี้ไม่มีรหัสบัญชี ตรวจสอบไม่ได้' : 'ตรวจสอบรายการนี้'),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: canTap ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: verified ? AppColors.verified : Colors.white,
            border: verified
                ? null
                : Border.all(color: onTap == null ? const Color(0xFFEDE3E8) : const Color(0xFFE4BFD0), width: 2),
            boxShadow: verified ? AppColors.glow(AppColors.verified, opacity: .8) : null,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magenta),
                )
              : Icon(Icons.check_rounded, size: 17, color: verified ? Colors.white : const Color(0x00000000)),
        ),
      ),
    );
  }
}

class _PrintButton extends StatelessWidget {
  const _PrintButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? Colors.white : AppColors.disabled;
    return Tooltip(
      message: enabled ? 'พิมพ์ใบสำคัญรับ' : 'ตรวจสอบก่อนจึงพิมพ์ได้',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: enabled ? AppColors.glow(AppColors.magenta, opacity: .7) : null,
        ),
        child: Material(
          color: enabled ? AppColors.magenta : AppColors.ink.withOpacity(.05),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled ? onTap : null,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.print_rounded, size: 16, color: fg),
                const SizedBox(width: 7),
                Text('พิมพ์ใบรับ', style: AppText.body(12.5, color: fg, weight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer: subtotal per pay type and the grand total pill.
class CreditTableFooter extends StatelessWidget {
  const CreditTableFooter({super.key, required this.rows, required this.payTypeNames, required this.filtered});

  final List<CashAdvance> rows;
  final PayTypeNames payTypeNames;

  /// Rows are a filtered subset — label the total accordingly.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final byType = <String?, double>{};
    for (final r in rows) {
      byType.update(r.accode, (v) => v + r.amountValue, ifAbsent: () => r.amountValue);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in byType.entries)
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration:
                    BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: PayTypeStyle.of(e.key).dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('${payTypeNames.label(e.key)}  ', style: AppText.body(12.5, color: AppColors.muted)),
                  Text(formatMoney(e.value), style: AppText.display(12.5, color: AppColors.ink2)),
                ]),
              ),
          ]),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.only(left: 20, right: 8),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(filtered ? 'รวมที่แสดง' : 'รวมทั้งหมด Total', style: AppText.body(12.5, color: Colors.white70)),
            const SizedBox(width: 12),
            Text(formatMoney(rows.totalAmount), style: AppText.display(20, color: Colors.white)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(999)),
              child: Text('THB', style: AppText.body(12, color: Colors.white)),
            ),
          ]),
        ),
      ]),
    );
  }
}
