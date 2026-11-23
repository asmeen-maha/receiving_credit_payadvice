import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_printer.dart';
import '../../../data/models/cash_advance.dart';
import '../../../data/models/transaction_all.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import '../../../shared/widgets/surfaces.dart';

/// Preview of ใบนำส่งรายได้ฝ่ายบัตร: one page per cashier. Cashiers can be
/// unticked to leave their page out before printing or saving.
Future<void> showIncomePreviewDialog(
  BuildContext context, {
  required DateTime date,
  required List<TransactionAll> cashiers,
  required List<CashAdvance> creditRows,
  required Future<Uint8List> Function(List<TransactionAll> selected) generate,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x38491630),
    builder: (_) => _IncomePreviewDialog(date: date, cashiers: cashiers, creditRows: creditRows, generate: generate),
  );
}

class _IncomePreviewDialog extends StatefulWidget {
  const _IncomePreviewDialog({
    required this.date,
    required this.cashiers,
    required this.creditRows,
    required this.generate,
  });

  final DateTime date;
  final List<TransactionAll> cashiers;
  final List<CashAdvance> creditRows;
  final Future<Uint8List> Function(List<TransactionAll> selected) generate;

  @override
  State<_IncomePreviewDialog> createState() => _IncomePreviewDialogState();
}

class _IncomePreviewDialogState extends State<_IncomePreviewDialog> {
  late final Set<String?> _selected = widget.cashiers.map((c) => c.userid).toSet();
  late Future<Uint8List> _pdf;
  int _version = 0;

  /// Ticking several cashiers in a row rebuilds the PDF once, not per click.
  Timer? _debounce;
  bool _exporting = false;

  /// Credit total per cashier, computed once instead of on every rebuild.
  late final Map<String?, double> _creditTotals = () {
    final totals = <String?, double>{};
    for (final r in widget.creditRows) {
      totals[r.userid] = (totals[r.userid] ?? 0) + r.amountValue;
    }
    return totals;
  }();

  List<TransactionAll> get _selectedCashiers => widget.cashiers.where((c) => _selected.contains(c.userid)).toList();

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _regenerate() {
    _debounce?.cancel();
    _debounce = null;
    _version++;
    _pdf = widget.generate(_selectedCashiers);
  }

  void _toggle(TransactionAll cashier) {
    setState(() {
      if (!_selected.remove(cashier.userid)) _selected.add(cashier.userid);
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(_regenerate);
    });
  }

  /// The PDF for the current selection (flushes a pending regenerate).
  Future<Uint8List> _currentPdf() {
    if (_debounce != null) setState(_regenerate);
    return _pdf;
  }

  Future<void> _export(Future<void> Function(Uint8List pdf) action) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await action(await _currentPdf());
    } catch (e) {
      debugPrint('Income report export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _print() => _export((pdf) async => printPdf(pdf));

  Future<void> _save() =>
      _export((pdf) => Printing.sharePdf(bytes: pdf, filename: 'income-report-${DateFmt.api(widget.date)}.pdf'));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final count = _selected.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: SizedBox(
        width: size.width.clamp(0, 1280).toDouble(),
        height: size.height * .9,
        child: GlassCard(
          color: const Color(0xEBFFFFFF),
          radius: 28,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
                child: Row(children: [
                  const IconBadge(
                      icon: Icons.description_outlined,
                      background: AppColors.magentaSoft,
                      foreground: AppColors.magenta),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ใบนำส่งรายได้ฝ่ายบัตร', style: AppText.display(18)),
                      Text(
                        'Income remittance · ${DateFmt.thaiLong(widget.date)} · ${widget.cashiers.length} พนักงาน · $count หน้า',
                        style: AppText.body(13, color: AppColors.muted),
                      ),
                    ]),
                  ),
                  RoundIconButton(
                      icon: Icons.close_rounded, tooltip: 'ปิด (Esc)', onPressed: () => Navigator.pop(context)),
                ]),
              ),
              const Divider(height: 1, color: Color(0x12000000)),
              // Body
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Text('พนักงานที่มีรายการ',
                              style: AppText.body(12.5, color: AppColors.muted, weight: FontWeight.w600)),
                          const Spacer(),
                          Text('$count/${widget.cashiers.length}',
                              style: AppText.display(12.5, color: AppColors.muted)),
                        ]),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            itemCount: widget.cashiers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final cashier = widget.cashiers[i];
                              final on = _selected.contains(cashier.userid);
                              return _CashierTile(
                                name: cashier.name ?? '-',
                                code: cashier.code ?? '',
                                creditTotal: _creditTotals[cashier.userid] ?? 0,
                                selected: on,
                                onTap: () => _toggle(cashier),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('หนึ่งหน้าต่อหนึ่งพนักงาน · เอาเครื่องหมายออกเพื่อไม่พิมพ์หน้านั้น',
                            style: AppText.body(12, color: AppColors.muted)),
                      ]),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0x12000000)),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF3E9EF), Color(0xFFEEE4EA)],
                        ),
                      ),
                      child: count == 0
                          ? const Center(child: StateView.empty(message: 'เลือกพนักงานอย่างน้อย 1 คนเพื่อดูตัวอย่าง'))
                          : PdfPreview(
                              key: ValueKey(_version),
                              build: (_) => _pdf,
                              useActions: false,
                              canDebug: false,
                              maxPageWidth: 900,
                              scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
                              loadingWidget: const FerrisLoader(),
                              onError: (context, error) =>
                                  const Center(child: StateView.empty(message: 'สร้างรายงานไม่สำเร็จ')),
                            ),
                    ),
                  ),
                ]),
              ),
              const Divider(height: 1, color: Color(0x12000000)),
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(children: [
                  const Spacer(),
                  PillButton(label: 'ปิด', style: PillStyle.white, onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  PillButton(
                    label: 'บันทึก PDF',
                    icon: Icons.download_rounded,
                    style: PillStyle.soft,
                    busy: _exporting,
                    onPressed: count == 0 ? null : _save,
                  ),
                  const SizedBox(width: 10),
                  PillButton(
                    label: 'พิมพ์ $count หน้า',
                    icon: Icons.print_rounded,
                    busy: _exporting,
                    onPressed: count == 0 ? null : _print,
                    disabledReason: 'เลือกพนักงานอย่างน้อย 1 คน',
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierTile extends StatelessWidget {
  const _CashierTile({
    required this.name,
    required this.code,
    required this.creditTotal,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String code;
  final double creditTotal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.magenta : Colors.transparent, width: 2),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.magenta : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: selected ? AppColors.magenta : AppColors.chipBorder, width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, overflow: TextOverflow.ellipsis, style: AppText.body(13, weight: FontWeight.w600)),
                Text(code, style: AppText.body(11.5, color: AppColors.muted)),
              ]),
            ),
            if (creditTotal > 0) Text(formatMoney(creditTotal), style: AppText.display(12.5, weight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
