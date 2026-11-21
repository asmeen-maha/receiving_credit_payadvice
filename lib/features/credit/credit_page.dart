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
import '../../data/models/transaction_all.dart';
import '../../data/services/api_service.dart';
import '../../reports/agent_credit_report.dart';
import '../../reports/credit_by_staff_report.dart';
import '../../reports/credit_range_report.dart';
import '../../reports/income/income_report.dart';
import '../../reports/receiving_voucher_report.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/inputs.dart';
import '../../shared/widgets/states.dart';
import 'widgets/agent_report_tile.dart';
import 'widgets/credit_overview.dart';
import 'widgets/credit_table.dart';
import 'widgets/income_preview_dialog.dart';

enum _StatusFilter { all, pending, verified }

/// Credit tab: verify credit rows, print receiving vouchers and reports.
class CreditPage extends StatefulWidget {
  const CreditPage({super.key, this.onPendingCount});

  /// Reports the number of rows still waiting for verification (for the nav badge).
  final ValueChanged<int>? onPendingCount;

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> with AutomaticKeepAliveClientMixin {
  static const _creditReportTitle = 'รายงานเงินรับล่วงหน้าเงินเชื่อ';
  static const _creditReportTitleEng = 'Advance Payment and Credit Report';

  final _api = ApiService.instance;
  final _searchController = TextEditingController();

  DateTime _startDate = DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 7));
  DateTime _endDate = DateUtils.dateOnly(DateTime.now());

  List<PayType> _payTypes = [];
  PayTypeNames _payTypeNames = PayTypeNames(const []);

  /// Cashier summaries for [_startDate] (income report).
  List<TransactionAll> _transactions = [];
  bool _transactionsLoaded = false;

  /// Credit rows not yet printed.
  List<CashAdvance> _credits = [];

  /// Pay-advance rows for the income report.
  List<CashAdvance> _payAdvances = [];

  bool _isLoading = true;
  bool _loadFailed = false;

  _StatusFilter _status = _StatusFilter.all;
  String? _payFilter;

  /// Row ids with a request in flight.
  final Set<String> _busyIds = {};
  bool _verifyingAll = false;

  /// Progress of a running "verify all" (done / total).
  (int, int)? _verifyProgress;

  /// Blocks a second dialog from a double click while one is opening.
  bool _dialogOpen = false;

  bool get _isSingleDay => _startDate == _endDate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPayTypes();
    _reload();
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

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    if (_payTypes.isEmpty) _loadPayTypes(); // the first attempt may have failed
    final range = _range;
    await Future.wait([_loadTransactions(), _loadCredits()]);
    if (mounted && range == _range) setState(() => _isLoading = false);
  }

  /// Responses for a range other than the current one are dropped, so a slow
  /// request for a previous date range cannot overwrite the newer data.
  (DateTime, DateTime) get _range => (_startDate, _endDate);

  Future<void> _loadTransactions() async {
    final range = _range;
    final result = await _api.fetchTransactions(showDate: DateFmt.api(_startDate));
    if (!mounted || range != _range) return;
    setState(() {
      _transactions = (result ?? [])..sort((a, b) => a.userIdValue.compareTo(b.userIdValue));
      _transactionsLoaded = result != null;
    });
  }

  Future<void> _loadCredits() async {
    final range = _range;
    final result = await _api.fetchCreditRange(startDate: DateFmt.api(_startDate), endDate: DateFmt.api(_endDate));
    if (!mounted || range != _range) return;
    final rows = result ?? const <CashAdvance>[];
    setState(() {
      _credits = rows.where((r) => r.isCredit && r.amountValue > 0 && !r.isPrinted).toList();
      _payAdvances = rows.where((r) => r.isPayAdvance && r.amountValue > 0).toList();
      _loadFailed = result == null;
      if (_payFilter != null && !_credits.any((r) => r.accode == _payFilter)) _payFilter = null;
    });
    if (result != null) widget.onPendingCount?.call(_credits.where((r) => !r.isVerified).length);
  }

  List<CashAdvance> get _visible {
    final query = _searchController.text;
    return _credits.where((r) {
      if (query.isNotEmpty && !r.matchesAgent(query)) return false;
      if (_payFilter != null && r.accode != _payFilter) return false;
      return switch (_status) {
        _StatusFilter.all => true,
        _StatusFilter.pending => !r.isVerified,
        _StatusFilter.verified => r.isVerified,
      };
    }).toList();
  }

  Future<void> _setRange(DateTime start, DateTime end) async {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    await _reload();
  }

  Future<void> _pickDateRange() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'เลือกช่วงวันที่',
    );
    _dialogOpen = false;
    if (picked != null && mounted) await _setRange(picked.start, picked.end);
  }

  void _useToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    _setRange(today, today);
  }

  // --------------------------------------------------------------- actions

  /// [date] is captured when the action starts, so changing the date range
  /// while requests are in flight cannot post rows with the wrong doc date.
  Future<void> _setFlag(CashAdvance item, String flag, DateTime date) => _api.updateActiveFlag(
        item: item,
        flag: flag,
        docDate: DateFmt.short(date),
        refNo: DateFmt.short(date),
      );

  /// Runs [task] for one row with its busy spinner, showing errors as a toast.
  /// A second tap on a row that is already busy is ignored.
  Future<void> _rowTask(CashAdvance item, Future<void> Function() task) async {
    final id = item.id ?? '';
    if (_busyIds.contains(id) || _verifyingAll) return;
    setState(() => _busyIds.add(id));
    try {
      await task();
    } catch (e) {
      if (mounted) showToast(context, 'ทำรายการไม่สำเร็จ ลองอีกครั้ง', error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _verify(CashAdvance item) => _rowTask(item, () async {
        await _setFlag(item, ActiveFlag.verified, _startDate);
        await _loadCredits();
        if (mounted) showToast(context, 'ตรวจสอบ ${item.rsvn ?? ''} แล้ว · ${formatMoney(item.amountValue)} THB');
      });

  Future<void> _verifyAll() async {
    if (_dialogOpen || _verifyingAll) return;
    // Rows with their own request in flight are left out to avoid posting twice.
    final items =
        _visible.where((r) => !r.isVerified && r.hasAccountCode && !_busyIds.contains(r.id ?? '')).toList();
    if (items.isEmpty) return;
    final date = _startDate;
    _dialogOpen = true;
    final ok = await confirmVerify(
      context,
      items: items,
      payTypeNames: _payTypeNames,
      subtitle: 'เงินเชื่อ ${DateFmt.thaiRange(_startDate, _endDate)}',
    );
    _dialogOpen = false;
    if (!ok || !mounted) return;

    setState(() {
      _verifyingAll = true;
      _verifyProgress = (0, items.length);
    });
    var failed = 0;
    try {
      // Sequential on purpose: each call posts to accounting, and the backend
      // has not been checked for safe concurrent writes.
      for (final (i, item) in items.indexed) {
        try {
          await _setFlag(item, ActiveFlag.verified, date);
        } catch (e) {
          debugPrint('Verify ${item.id} failed: $e');
          failed++;
        }
        if (mounted) setState(() => _verifyProgress = (i + 1, items.length));
      }
      await _loadCredits();
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

  Future<void> _printVoucher(CashAdvance item) => _rowTask(item, () async {
        final date = _startDate;
        final pdf = await ReceivingVoucherReport.generate(date: date, item: item);
        await _setFlag(item, ActiveFlag.printed, date);
        await _loadCredits();
        printPdf(pdf);
      });

  Future<void> _openIncomeReport() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    try {
      await _showIncomeReport();
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _showIncomeReport() => showIncomePreviewDialog(
        context,
        date: _startDate,
        cashiers: _transactions,
        creditRows: _credits,
        generate: (selected) => IncomeReport.generate(
          date: _startDate,
          cashiers: selected,
          payAdvances: _payAdvances,
          credits: _credits,
          payTypes: _payTypes,
        ),
      );

  Future<void> _printCreditReport() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final Uint8List pdf;
    try {
      pdf = await runWithProgress(
      context,
      () => _isSingleDay
          ? CreditByStaffReport.generate(
              date: _startDate,
              groups: StaffGroup.groupByStaff(_credits),
              payTypes: _payTypes,
              title: _creditReportTitle,
              titleEng: _creditReportTitleEng,
            )
          : CreditRangeReport.generate(
              startDate: _startDate,
              endDate: _endDate,
              items: _credits,
              payTypes: _payTypes,
              title: _creditReportTitle,
              titleEng: _creditReportTitleEng,
            ),
      );
    } catch (e) {
      debugPrint('Credit report failed: $e');
      if (mounted) showToast(context, 'สร้างรายงานไม่สำเร็จ', error: true);
      return;
    } finally {
      _dialogOpen = false;
    }
    printPdf(pdf);
  }

  Future<void> _printAgentItems(List<CashAdvance> selected) async => printPdf(await AgentCreditReport.generate(
        startDate: _startDate,
        endDate: _endDate,
        items: selected,
        payTypes: _payTypes,
      ));

  Future<void> _printAgentByStaff(List<CashAdvance> selected) async => printPdf(await AgentCreditReport.generateByStaff(
        startDate: _startDate,
        endDate: _endDate,
        groups: StaffGroup.groupByStaff(selected),
        payTypes: _payTypes,
      ));

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final visible = _visible;
    final pending = _credits.where((r) => !r.isVerified).toList();
    final verified = _credits.where((r) => r.isVerified).toList();
    final days = DateUtils.dateOnly(_endDate).difference(DateUtils.dateOnly(_startDate)).inDays + 1;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverList.list(children: [
              _Greeting(
                pendingCount: pending.length,
                dateLabel: _isSingleDay ? DateFmt.thaiShort(_startDate) : DateFmt.thaiRange(_startDate, _endDate),
                dateBadge: _isSingleDay ? null : '$days วัน',
                onPickDate: _isLoading || _verifyingAll ? null : _pickDateRange,
              ),
              const SizedBox(height: 18),
              _overview(width, pending, verified),
              const SizedBox(height: 22),
              _tableToolbar(visible, pending.length, verified.length),
              const SizedBox(height: 12),
            ]),
          ),
          ..._tableBody(visible),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      );
    });
  }

  Widget _overview(double width, List<CashAdvance> pending, List<CashAdvance> verified) {
    const gap = SizedBox(width: 16, height: 16);
    final hero = HeroTotalTile(rows: _credits, payTypeNames: _payTypeNames, startDate: _startDate, endDate: _endDate);
    final pendingTile = KpiTile(
      label: 'รอตรวจสอบ',
      count: pending.length,
      amount: pending.totalAmount,
      color: AppColors.pending,
      icon: Icons.schedule_rounded,
      iconBackground: AppColors.pendingSoft,
    );
    final verifiedTile = KpiTile(
      label: 'ตรวจสอบแล้ว',
      count: verified.length,
      amount: verified.totalAmount,
      color: AppColors.verified,
      icon: Icons.check_circle_outline_rounded,
      iconBackground: const Color(0xFFD6F0E3),
      progress: _credits.isEmpty ? 0 : verified.length / _credits.length,
    );
    final reports = ReportsTile(
      cashierCount: _transactionsLoaded ? _transactions.length : 0,
      canOpenIncome: _transactionsLoaded && _transactions.isNotEmpty && _isSingleDay,
      isSingleDay: _isSingleDay,
      onIncome: _openIncomeReport,
      onCreditReport: _printCreditReport,
      onUseToday: _useToday,
    );
    final agent = AgentReportTile(rows: _credits, onPrintItems: _printAgentItems, onPrintByStaff: _printAgentByStaff);

    if (width >= 1200) {
      return SizedBox(
        height: 360,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 5, child: hero),
          gap,
          Expanded(
            flex: 4,
            child: Column(children: [
              Expanded(child: Row(children: [Expanded(child: pendingTile), gap, Expanded(child: verifiedTile)])),
              gap,
              Expanded(child: agent),
            ]),
          ),
          gap,
          Expanded(flex: 3, child: reports),
        ]),
      );
    }
    return Column(children: [
      SizedBox(height: 320, child: hero),
      gap,
      SizedBox(height: 160, child: Row(children: [Expanded(child: pendingTile), gap, Expanded(child: verifiedTile)])),
      gap,
      SizedBox(height: 280, child: Row(children: [Expanded(child: reports), gap, Expanded(child: agent)])),
    ]);
  }

  Widget _tableToolbar(List<CashAdvance> visible, int pendingCount, int verifiedCount) {
    final payCodes = _credits.map((r) => r.accode).toSet().toList();
    final canVerifyAll = visible.any((r) => !r.isVerified && r.hasAccountCode);
    final progress = _verifyProgress;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'รายการเงินเชื่อ', style: AppText.display(19)),
          TextSpan(text: '  Credit items', style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w500)),
        ])),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (filter, label, count) in [
            (_StatusFilter.all, 'ทั้งหมด', _credits.length),
            (_StatusFilter.pending, 'รอตรวจ', pendingCount),
            (_StatusFilter.verified, 'ตรวจแล้ว', verifiedCount),
          ])
            FilterPill(
                label: label, count: count, selected: _status == filter, onTap: () => setState(() => _status = filter)),
          if (payCodes.length > 1) ...[
            const SizedBox(width: 6),
            for (final code in payCodes)
              FilterPill(
                label: _payTypeNames.label(code),
                dot: PayTypeStyle.of(code).dot,
                selected: _payFilter == code,
                onTap: () => setState(() => _payFilter = _payFilter == code ? null : code),
              ),
          ],
        ]),
        SearchPill(controller: _searchController, onChanged: (_) => setState(() {}), width: 260),
        PillButton(
          label: progress == null ? 'ตรวจสอบทั้งหมดที่แสดง' : 'กำลังตรวจสอบ ${progress.$1}/${progress.$2}',
          icon: Icons.done_all_rounded,
          style: PillStyle.lagoon,
          busy: _verifyingAll,
          onPressed: canVerifyAll ? _verifyAll : null,
          disabledReason: 'ไม่มีรายการรอตรวจสอบในตัวกรองนี้',
        ),
      ],
    );
  }

  List<Widget> _tableBody(List<CashAdvance> visible) {
    Widget boxed(Widget child) =>
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: SliverToBoxAdapter(child: child));

    if (_isLoading && _credits.isEmpty) return [boxed(const StateView.loading())];
    if (_loadFailed) return [boxed(StateView.error(onAction: _reload))];
    if (_credits.isEmpty) {
      return [boxed(StateView.empty(actionLabel: 'เลือกช่วงวันที่อื่น', onAction: _pickDateRange))];
    }
    if (visible.isEmpty) {
      return [
        boxed(StateView.empty(
          message: 'ไม่มีรายการที่ตรงกับตัวกรองหรือคำค้นหา',
          actionLabel: 'ล้างตัวกรอง',
          onAction: () => setState(() {
            _searchController.clear();
            _status = _StatusFilter.all;
            _payFilter = null;
          }),
        )),
      ];
    }

    return [
      boxed(const CreditTableHeader()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
        sliver: SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, i) {
            final item = visible[i];
            return CreditRow(
              item: item,
              payTypeNames: _payTypeNames,
              busy: _busyIds.contains(item.id ?? '') || _verifyingAll,
              onVerify: item.hasAccountCode ? () => _verify(item) : null,
              onPrintVoucher: () => _printVoucher(item),
            );
          },
        ),
      ),
      boxed(CreditTableFooter(
        rows: visible,
        payTypeNames: _payTypeNames,
        filtered: visible.length != _credits.length,
      )),
    ];
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.pendingCount,
    required this.dateLabel,
    required this.dateBadge,
    required this.onPickDate,
  });

  final int pendingCount;
  final String dateLabel;
  final String? dateBadge;
  final VoidCallback? onPickDate;

  String get _hello {
    final h = DateTime.now().hour;
    return h < 12 ? 'สวัสดีตอนเช้า' : (h < 17 ? 'สวัสดีตอนบ่าย' : 'สวัสดีตอนเย็น');
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$_hello · เงินเชื่อ', style: AppText.display(30)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(style: AppText.body(14.5, color: AppColors.muted), children: [
            TextSpan(text: '${DateFmt.thaiLong(DateTime.now())} · รอตรวจสอบ '),
            TextSpan(
                text: '$pendingCount รายการ',
                style: const TextStyle(color: AppColors.magentaDark, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
      DatePill(label: dateLabel, badge: dateBadge, onTap: onPickDate),
    ]);
  }
}
