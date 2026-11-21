import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/pay_type.dart';
import '../data/models/staff_group.dart';
import 'common/report_assets.dart';
import 'common/report_footer.dart';
import 'common/report_header.dart';
import 'common/report_widgets.dart';

/// Single-day report with rows grouped under each staff member.
/// Used for both "รายงานเงินรับล่วงหน้าเงินเชื่อ" (credit) and "รายงานเงินรับล่วงหน้า" (pay advance).
abstract final class CreditByStaffReport {
  static const _columns = [
    ReportColumn('rsvn', 55),
    ReportColumn('', 40),
    ReportColumn('Agent', 210),
    ReportColumn('Voucher', 85),
    ReportColumn('Paytype', 75),
    ReportColumn('Amount', 60),
  ];

  static Future<Uint8List> generate({
    required DateTime date,
    required List<StaffGroup> groups,
    required List<PayType> payTypes,
    required String title,
    required String titleEng,
  }) async {
    final assets = await ReportAssets.load();
    final payTypeNames = PayTypeNames(payTypes);
    final grandTotal = groups.fold(0.0, (sum, g) => sum + g.total);

    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true)
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: a4ReportMargin,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              ...buildReportHeader(assets: assets, title: title, subtitle: titleEng, startDate: date),
              borderedHeaderRow(assets, _columns, height: 30, fontSize: 11, bold: true, noLeftBorder: {0, 2}),
              pw.SizedBox(height: 5),
            ],
          ),
          build: (context) => [
            pw.Column(
              children: [
                for (final group in groups)
                  pw.Column(
                    children: [
                      staffNameChip(assets, group.name),
                      for (final item in group.items)
                        pw.Row(
                          children: [
                            reportCell(assets, item.rsvn ?? '', 55),
                            reportCell(assets, item.agentcode ?? '', 40),
                            reportCell(assets, item.agentname ?? '', 210),
                            reportCell(assets, item.voucher ?? '', 85),
                            reportCell(assets, payTypeNames.of(item.accode), 75),
                            reportAmountCell(assets, item.amountValue, 60),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 3),
            ...grandTotalBlock(assets, grandTotal),
          ],
          footer: (context) => pw.Column(children: [buildReportFooter(context, assets, 'Credit Report')]),
        ),
      );

    return pdf.save();
  }
}
