import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_printer.dart';
import '../../data/models/cash_advance.dart';
import '../../data/models/pay_type.dart';
import '../../data/models/staff_group.dart';
import '../../data/services/api_service.dart';
import '../../reports/credit_by_staff_report.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/inputs.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/surfaces.dart';
import 'widgets/ticket_card.dart';

enum _Status { all, pending, verified }

/// Pay Advance tab: verify one day's pay-advance rows and print the report.
/// Verified tickets stay on the page with a "ตรวจแล้ว" stamp.
class PayAdvancePage extends StatefulWidget {
  const PayAdvancePage({super.key, this.onPendingCount});

  /// Reports the number of rows still waiting for verification (for the nav badge).
  final ValueChanged<int>? onPendingCount;

  @override
  State<PayAdvancePage> createState() => _PayAdvancePageState();
}

class _PayAdvancePageState extends State<PayAdvancePage> with AutomaticKeepAliveClientMixin {
  /// Earliest date the pay-advance data is available.
  static final _firstDate = DateTime(2025, DateTime.september, 10);

  final _api = ApiService.instance;
  final _searchController = TextEditingController();

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  List<PayType> _payTypes = [];
  PayTypeNames _payTypeNames = PayTypeNames(const []);

  /// All of the day's rows: pending first, then verified, each by staff id.
  List<CashAdvance> _rows = [];
  _Status _status = _Status.all;

  static bool _isDone(CashAdvance r) => r.isVerified || r.isPrinted;
  List<CashAdvance> get _pending => _rows.where((r) => !_isDone(r)).toList();

  /// All of the day's pay-advance rows, grouped by staff, for the report.
  List<StaffGroup> _reportGroups = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  final Set<String> _busyIds = {};
  bool _verifyingAll = false;

  /// Progress of a running "verify all" (done / total).
  (int, int)? _verifyProgress;

  /// Blocks a second dialog from a double click while one is opening.
  bool _dialogOpen = false;

  bool get _isToday => DateUtils.isSameDay(_date, DateTime.now());

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPayTypes();
    _loadPayAdvance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ data

  Future<void> _loadPayTypes() async {
    final result = await _api.fetchPayTypes();
    if (result == null || !mounted) return;
    setState(() {
      _payTypes = result;
      _payTypeNames = PayTypeNames(result);
    });
  }

  Future<void> _loadPayAdvance() async {
    if (_payTypes.isEmpty) _loadPayTypes(); // the first attempt may have failed
    final date = _date;
    final result = await _api.fetchPayAdvance(bookDate: DateFmt.api(date));
    // Drop responses for a date the user has already moved away from.
    if (!mounted || date != _date) return;
    final dayRows = (result ?? const <CashAdvance>[]).where((r) => r.isPayAdvance && r.amountValue > 0).toList();

    setState(() {
      _rows = [...dayRows]..sort((a, b) {
          final byStatus = (_isDone(a) ? 1 : 0) - (_isDone(b) ? 1 : 0);
          return byStatus != 0 ? byStatus : a.userIdValue.compareTo(b.userIdValue);
        });
      _reportGroups = StaffGroup.groupByStaff(dayRows, sortByUserId: true);
      _loadFailed = result == null;
      _isLoading = false;
    });
    if (result != null) widget.onPendingCount?.call(_rows.where((r) => !_isDone(r)).length);
  }

  List<CashAdvance> get _visible {
    final query = _searchController.text;
    return _rows.where((r) {
      if (query.isNotEmpty && !r.matchesAgent(query)) return false;
      return switch (_status) {
        _Status.all => true,
        _Status.pending => !_isDone(r),
        _Status.verified => _isDone(r),
      };
    }).toList();
  }

  /// Rows "verify all" would send: pending, with an account code, not busy.
  List<CashAdvance> _verifiable(List<CashAdvance> rows) =>
      rows.where((r) => !_isDone(r) && r.hasAccountCode && !_busyIds.contains(r.id ?? '')).toList();

  Future<void> _setDate(DateTime date) async {
    setState(() {
      _date = date;
      _isLoading = true;
    });
    await _loadPayAdvance();
  }

  Future<void> _pickDate() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _firstDate,
      lastDate: DateTime.now(),
      helpText: 'เลือกวันที่',
    );
    _dialogOpen = false;
    if (picked != null && picked != _date && mounted) await _setDate(picked);
  }

  // --------------------------------------------------------------- actions

  /// Posts [items] one by one (each call posts to accounting, so they are not
  /// sent in parallel). [date] is captured before the confirm dialog so the
  /// doc date cannot change mid-way. Returns the number of failures.
  Future<int> _verify(List<CashAdvance> items, DateTime date, {ValueChanged<int>? onProgress}) async {
    var failed = 0;
    var done = 0;
    for (final item in items.where((i) => i.hasAccountCode)) {
      try {
        await _api.updateActiveFlag(
          item: item,
          flag: ActiveFlag.verified,
          docDate: DateFmt.api(date),
          refNo: DateFmt.short(date),
        );
      } catch (e) {
        debugPrint('Verify ${item.id} failed: $e');
        failed++;
      }
      onProgress?.call(++done);
    }
    await _loadPayAdvance();
    return failed;
  }

  Future<void> _verifyOne(CashAdvance item) async {
    final id = item.id ?? '';
    if (_dialogOpen || _verifyingAll || _busyIds.contains(id)) return;
    final date = _date;
    _dialogOpen = true;
    final ok = await confirmVerify(context,
        items: [item], payTypeNames: _payTypeNames, subtitle: 'เงินรับล่วงหน้า ${DateFmt.thaiLong(date)}');
    _dialogOpen = false;
    if (!ok || !mounted) return;

    setState(() => _busyIds.add(id));
    final int failed;
    try {
      failed = await _verify([item], date);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
    if (!mounted) return;
    showToast(
      context,
      failed == 0
          ? 'ตรวจสอบ ${item.rsvn ?? ''} แล้ว · ${formatMoney(item.amountValue)} THB'
          : 'ตรวจสอบไม่สำเร็จ ลองอีกครั้ง',
      error: failed > 0,
    );
  }

  Future<void> _verifyAll() async {
    if (_dialogOpen || _verifyingAll) return;
    // Rows with their own request in flight are left out to avoid posting twice.
    final items = _verifiable(_visible);
    if (items.isEmpty) return;
    final date = _date;
    _dialogOpen = true;
    final ok = await confirmVerify(context,
        items: items, payTypeNames: _payTypeNames, subtitle: 'เงินรับล่วงหน้า ${DateFmt.thaiLong(date)}');
    _dialogOpen = false;
    if (!ok || !mounted) return;

    setState(() {
      _verifyingAll = true;
      _verifyProgress = (0, items.length);
    });
    final int failed;
    try {
      failed = await _verify(items, date, onProgress: (done) {
        if (mounted) setState(() => _verifyProgress = (done, items.length));
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifyingAll = false;
          _verifyProgress = null;
        });
      }
    }
    if (!mounted) return;
    showToast(
      context,
      failed == 0
          ? 'ตรวจสอบแล้ว ${items.length} รายการ · ${formatMoney(items.totalAmount)} THB'
          : 'ตรวจสอบสำเร็จ ${items.length - failed} จาก ${items.length} รายการ',
      error: failed > 0,
    );
  }

  Future<void> _printReport() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final Uint8List pdf;
    try {
      pdf = await runWithProgress(
        context,
        () => CreditByStaffReport.generate(
          date: _date,
          groups: _reportGroups,
          payTypes: _payTypes,
          title: 'รายงานเงินรับล่วงหน้า',
          titleEng: 'Pay Advance Report',
        ),
      );
    } catch (e) {
      debugPrint('Pay advance report failed: $e');
      if (mounted) showToast(context, 'สร้างรายงานไม่สำเร็จ', error: true);
      return;
    } finally {
      _dialogOpen = false;
    }
    printPdf(pdf);
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final visible = _visible;
    final verifiable = _verifiable(visible);
    final canVerifyAll = verifiable.isNotEmpty;
    final pending = _pending;
    final progress = _verifyProgress;

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        sliver: SliverList.list(children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'เงินรับล่วงหน้า', style: AppText.display(30)),
                  TextSpan(
                      text: '  Pay Advance', style: AppText.body(15, color: AppColors.muted, weight: FontWeight.w500)),
                ])),
                const SizedBox(height: 4),
                Text('ตรวจสอบรายการรับเงินล่วงหน้าทีละวัน · รายการที่ตรวจแล้วจะประทับตราและรวมในรายงาน',
                    style: AppText.body(14, color: AppColors.muted)),
              ]),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                DatePill(
                  label: DateFmt.thaiShort(_date),
                  badge: _isToday ? 'วันนี้' : null,
                  hint: 'เลือกได้ ${DateFmt.thaiShort(_firstDate)} – วันนี้',
                  onTap: _isLoading || _verifyingAll ? null : _pickDate,
                ),
                SearchPill(controller: _searchController, onChanged: (_) => setState(() {}), width: 240),
                PillButton(
                  label: 'รายงานเงินรับล่วงหน้า',
                  icon: Icons.print_outlined,
                  style: PillStyle.white,
                  height: 46,
                  onPressed: !_isLoading && _reportGroups.isNotEmpty ? _printReport : null,
                  disabledReason: 'ไม่มีรายการในวันที่เลือก',
                ),
                PillButton(
                  label: progress == null
                      ? 'ตรวจสอบทั้งหมด ${verifiable.length}'
                      : 'กำลังตรวจสอบ ${progress.$1}/${progress.$2}',
                  icon: Icons.done_all_rounded,
                  style: PillStyle.lagoon,
                  height: 46,
                  busy: _verifyingAll,
                  onPressed: canVerifyAll ? _verifyAll : null,
                  disabledReason: 'ไม่มีรายการรอตรวจสอบ',
                ),
              ]),
            ],
          ),
          const SizedBox(height: 18),
          _Stats(rows: pending, verifiedCount: _rows.length - pending.length, payTypeNames: _payTypeNames),
          const SizedBox(height: 18),
          if (_rows.isNotEmpty && !_isLoading && !_loadFailed) ...[
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final (status, label, count) in [
                (_Status.all, 'ทั้งหมด', _rows.length),
                (_Status.pending, 'รอตรวจ', pending.length),
                (_Status.verified, 'ตรวจแล้ว', _rows.length - pending.length),
              ])
                FilterPill(
                    label: label,
                    count: count,
                    selected: _status == status,
                    onTap: () => setState(() => _status = status)),
            ]),
            const SizedBox(height: 14),
          ],
        ]),
      ),
      ..._body(visible),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ]);
  }

  List<Widget> _body(List<CashAdvance> visible) {
    Widget boxed(Widget child) =>
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: SliverToBoxAdapter(child: child));

    if (_isLoading) return [boxed(StateView.loading(message: 'ดึงข้อมูลวันที่ ${DateFmt.thaiLong(_date)}'))];
    if (_loadFailed) return [boxed(StateView.error(onAction: () => _setDate(_date)))];
    if (_rows.isEmpty) {
      return [
        boxed(StateView.empty(
          message: 'วันนี้ยังไม่มีเงินรับล่วงหน้าเข้ามา ลองเลือกวันอื่น หรือกลับมาดูอีกครั้งภายหลัง',
          actionLabel: 'เลือกวันอื่น',
          onAction: _pickDate,
        )),
      ];
    }
    if (visible.isEmpty) {
      final allDone = _status == _Status.pending && _searchController.text.isEmpty;
      return [
        boxed(StateView.empty(
          message: allDone
              ? 'ตรวจสอบครบทุกรายการแล้ว พิมพ์รายงานเงินรับล่วงหน้าได้เลย'
              : 'ไม่มีรายการที่ตรงกับตัวกรองหรือคำค้นหา',
          actionLabel: allDone ? 'ดูรายการที่ตรวจแล้ว' : 'ล้างตัวกรอง',
          onAction: () => setState(() {
            _searchController.clear();
            _status = allDone ? _Status.verified : _Status.all;
          }),
        )),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 540,
            mainAxisExtent: 138,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: visible.length,
          itemBuilder: (context, i) {
            final item = visible[i];
            final done = _isDone(item);
            return TicketCard(
              item: item,
              payTypeNames: _payTypeNames,
              verified: done,
              busy: !done && (_busyIds.contains(item.id ?? '') || _verifyingAll),
              onVerify: !done && item.hasAccountCode ? () => _verifyOne(item) : null,
            );
          },
        ),
      ),
    ];
  }
}

/// Pending total (magenta) plus one tile per pay type.
class _Stats extends StatelessWidget {
  const _Stats({required this.rows, required this.verifiedCount, required this.payTypeNames});

  /// Pending rows.
  final List<CashAdvance> rows;
  final int verifiedCount;
  final PayTypeNames payTypeNames;

  @override
  Widget build(BuildContext context) {
    // Transfer, cash and card always have a tile (showing 0 when nothing is
    // pending), as in the design; other codes appear only when present.
    final byType = <String?, List<CashAdvance>>{for (final code in PayTypeStyle.mainCodes) code: []};
    for (final r in rows) {
      byType.putIfAbsent(r.accode, () => []).add(r);
    }

    final total = GlassCard(
      gradient: const LinearGradient(colors: [AppColors.magentaLight, AppColors.magentaDark]),
      shadow: AppColors.glow(AppColors.magentaDark, opacity: .8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      radius: 20,
      child: Row(children: [
        IconBadge(
          icon: Icons.account_balance_wallet_outlined,
          background: Colors.white.withOpacity(.18),
          foreground: Colors.white,
          size: 44,
          radius: 15,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'ยอดรอตรวจสอบ · ${rows.length} รายการ'
              '${verifiedCount > 0 ? ' · ตรวจแล้ว $verifiedCount จาก ${rows.length + verifiedCount}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12.5, color: Colors.white70),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: formatMoney(rows.totalAmount), style: AppText.display(28, color: Colors.white)),
                TextSpan(text: '  THB', style: AppText.body(12.5, color: Colors.white70)),
              ])),
            ),
          ]),
        ),
      ]),
    );

    Widget typeTile(MapEntry<String?, List<CashAdvance>> e) {
      final style = PayTypeStyle.of(e.key);
      final apiName = payTypeNames.of(e.key);
      final name = apiName != '-' ? apiName : (style.thai.isNotEmpty ? style.thai : payTypeNames.label(e.key));
      final empty = e.value.isEmpty;
      return GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          IconBadge(
            icon: PayTypeStyle.of(e.key).icon,
            background: PayTypeStyle.of(e.key).background,
            foreground: PayTypeStyle.of(e.key).foreground,
            size: 44,
            radius: 15,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: name),
                  if (style.english.isNotEmpty && !apiName.contains(style.english)) TextSpan(text: ' ${style.english}'),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(12.5, color: AppColors.muted),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: formatMoney(e.value.totalAmount),
                      style: AppText.display(22, color: empty ? AppColors.faint : AppColors.ink)),
                  TextSpan(text: '  ${e.value.length} รายการ', style: AppText.body(12.5, color: AppColors.muted)),
                ])),
              ),
            ]),
          ),
        ]),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final entries = byType.entries.toList();
      if (c.maxWidth >= 1100) {
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 14, child: total),
            for (final e in entries) ...[const SizedBox(width: 16), Expanded(flex: 10, child: typeTile(e))],
            if (entries.length < 3) Spacer(flex: 10 * (3 - entries.length)),
          ]),
        );
      }
      return Column(children: [
        total,
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          for (final e in entries) SizedBox(width: (c.maxWidth - 16) / 2, child: typeTile(e)),
        ]),
      ]);
    });
  }
}
