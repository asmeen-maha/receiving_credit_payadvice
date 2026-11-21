import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import 'report_assets.dart';

/// Logo + title block and the report date line, used by the A4 credit reports.
///
/// Shows `ประจำวันที่ <start>` or `ประจำวันที่ <start> - <end>` when [endDate]
/// is given. When [agent] is given an `Agent: ...` line is added below.
List<pw.Widget> buildReportHeader({
  required ReportAssets assets,
  required String title,
  required String subtitle,
  required DateTime startDate,
  DateTime? endDate,
  String? agent,
}) {
  final dateText = endDate == null
      ? 'ประจำวันที่ ${DateFmt.thaiLong(startDate)}'
      : 'ประจำวันที่ ${DateFmt.thaiLong(startDate)} - ${DateFmt.thaiLong(endDate)}';
  final dateLine = pw.Text(
    dateText,
    style: pw.TextStyle(font: assets.pgVim, fontSize: 10, fontWeight: pw.FontWeight.bold),
  );

  return [
    pw.Container(
      width: 5,
      child: pw.Column(children: [
        pw.Row(
          children: [
            pw.Image(assets.logo, width: 120),
            pw.SizedBox(height: 90),
            pw.SizedBox(width: 15),
            pw.Container(height: 75, width: 1, color: PdfColors.black),
            pw.SizedBox(width: 15),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              width: 400,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(font: assets.pgVim, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text(subtitle,
                      style: pw.TextStyle(font: assets.trajanBold, fontSize: 15, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ]),
    ),
    pw.SizedBox(height: 10),
    if (agent == null) ...[
      dateLine,
      pw.SizedBox(height: 5),
    ] else ...[
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          dateLine,
          pw.SizedBox(height: 10),
          pw.Text('Agent: $agent',
              style: pw.TextStyle(font: assets.pgVim, fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
      pw.SizedBox(height: 3),
    ],
  ];
}
