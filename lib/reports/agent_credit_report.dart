import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/cash_advance.dart';
import '../data/models/pay_type.dart';
import '../data/models/staff_group.dart';
import 'common/report_assets.dart';
import 'common/report_footer.dart';
import 'common/report_header.dart';
import 'common/report_widgets.dart';

/// Advance-payment report for the agents selected in "agent report mode".
///
/// * [AgentCreditReport.generate] — flat list of the selected rows.
/// * [AgentCreditReport.generateByStaff] — the same rows grouped by staff name.
abstract final class AgentCreditReport {
  static const title = 'รายงานเงินรับล่วงหน้า';
  static const titleEng = 'Advance Payment';

  static const _columns = [
    ReportColumn('Doc date', 80),
    ReportColumn('rsvn', 87.5),
    ReportColumn('Voucher', 126.5),
    ReportColumn('Paytype', 116.5),
    ReportColumn('Amount', 111.5),
  ];

  static Future<Uint8List> generate({
    required DateTime startDate,
    required DateTime endDate,
    required List<CashAdvance> items,
    required List<PayType> payTypes,
  }) {
    final agent = items.isNotEmpty ? items.first.agentLabel : '';
    return _build(
      startDate: startDate,
      endDate: endDate,
      agent: agent,
      payTypes: payTypes,
      total: items.totalAmount,
      hasRows: items.isNotEmpty,
      body: (assets, names) => [for (final item in items) _row(assets, names, item)],
    );
  }

  static Future<Uint8List> generateByStaff({
    required DateTime startDate,
    required DateTime endDate,
    required List<StaffGroup> groups,
    required List<PayType> payTypes,
  }) {
    final agent = groups.isNotEmpty ? groups.first.items.first.agentLabel : '';
    return _build(
      startDate: startDate,
      endDate: endDate,
      agent: agent,
      payTypes: payTypes,
      total: groups.fold(0.0, (sum, g) => sum + g.total),
      hasRows: groups.isNotEmpty,
      body: (assets, names) => [
        for (final group in groups)
          pw.Column(
            children: [
              staffNameChip(assets, group.name),
              for (final item in group.items) _row(assets, names, item),
            ],
          ),
      ],
    );
  }

  static pw.Widget _row(ReportAssets assets, PayTypeNames names, CashAdvance item) {
    return pw.Row(
      children: [
        reportCell(assets, item.displayDate, 80),
        reportCell(assets, item.rsvn ?? '', 87.5),
        reportCell(assets, item.voucher ?? '', 127.5),
        reportCell(assets, names.of(item.accode), 117.5),
        reportAmountCell(assets, item.amountValue, 112.5),
      ],
    );
  }

  static Future<Uint8List> _build({
    required DateTime startDate,
    required DateTime endDate,
    required String agent,
    required List<PayType> payTypes,
    required double total,
    required bool hasRows,
    required List<pw.Widget> Function(ReportAssets, PayTypeNames) body,
  }) async {
    final assets = await ReportAssets.load();
    final payTypeNames = PayTypeNames(payTypes);

    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true)
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: a4ReportMargin,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              ...buildReportHeader(
                assets: assets,
                title: title,
                subtitle: titleEng,
                startDate: startDate,
                endDate: endDate,
                agent: agent,
              ),
              filledHeaderRow(assets, _columns),
              pw.SizedBox(height: 5),
            ],
          ),
          build: (context) => [
            pw.Column(children: body(assets, payTypeNames)),
            pw.SizedBox(height: 3),
            if (hasRows) ...grandTotalBlock(assets, total),
          ],
          footer: (context) => pw.Column(children: [buildReportFooter(context, assets, 'Credit Report')]),
        ),
      );

    return pdf.save();
  }
}
