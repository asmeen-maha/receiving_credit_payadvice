import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/cash_advance.dart';
import '../data/models/pay_type.dart';
import 'common/report_assets.dart';
import 'common/report_footer.dart';
import 'common/report_header.dart';
import 'common/report_widgets.dart';

/// Flat list of credit rows for a date range (one row per item, with doc date).
abstract final class CreditRangeReport {
  static const _columns = [
    ReportColumn('Doc date', 55),
    ReportColumn('Agent', 245),
    ReportColumn('rsvn', 35),
    ReportColumn('Voucher', 80),
    ReportColumn('Paytype', 55),
    ReportColumn('Amount', 50),
  ];

  static Future<Uint8List> generate({
    required DateTime startDate,
    required DateTime endDate,
    required List<CashAdvance> items,
    required List<PayType> payTypes,
    required String title,
    required String titleEng,
  }) async {
    final assets = await ReportAssets.load();
    final payTypeNames = PayTypeNames(payTypes);
    const cellPadding = pw.EdgeInsets.only(left: 2);

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
              ),
              borderedHeaderRow(assets, _columns, height: 25, fontSize: 9),
              pw.SizedBox(height: 5),
            ],
          ),
          build: (context) => [
            pw.Column(
              children: [
                for (final item in items)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      reportCell(assets, item.displayDate, 55, padding: cellPadding),
                      reportCell(assets, item.agentLabel, 245, padding: cellPadding),
                      reportCell(assets, item.rsvn ?? '', 35, padding: cellPadding),
                      reportCell(assets, item.voucher ?? '', 80, padding: cellPadding),
                      reportCell(assets, payTypeNames.of(item.accode), 55, padding: cellPadding),
                      reportAmountCell(assets, item.amountValue, 50),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 3),
            if (items.isNotEmpty) ...grandTotalBlock(assets, items.totalAmount),
          ],
          footer: (context) => pw.Column(children: [buildReportFooter(context, assets, 'Credit Report')]),
        ),
      );

    return pdf.save();
  }
}
