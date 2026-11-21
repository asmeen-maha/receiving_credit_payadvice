import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import '../common/report_assets.dart';

/// Page header for the income report: logo/title, cashier name & ID, date,
/// and (when there are credit or pay-advance rows) the right-hand table header.
List<pw.Widget> buildIncomeHeader({
  required ReportAssets assets,
  required DateTime date,
  required String name,
  required String code,
  required bool showCreditTable,
}) {
  const thaiSize = 9.0;
  const engSize = 7.0;
  final thai = pw.TextStyle(font: assets.pgVim, fontSize: thaiSize);
  final eng = pw.TextStyle(font: assets.pgVim, fontSize: engSize);

  pw.Widget field(String label, String value, pw.Font valueFont, String labelEng) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text(label, style: thai),
            pw.SizedBox(width: 10),
            pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: thaiSize)),
          ]),
          pw.SizedBox(height: 2),
          pw.Text(labelEng, style: eng),
        ],
      );

  pw.Widget columnTitle(String text, pw.Font font, double width) => pw.Container(
        padding: const pw.EdgeInsets.all(2),
        height: 15,
        width: width,
        alignment: pw.Alignment.center,
        child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold)),
      );

  return [
    pw.Row(
      children: [
        pw.Container(
          width: 395,
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Image(assets.logo, width: 100),
                  pw.SizedBox(width: 20),
                  pw.Container(height: 65, width: 0.8, color: PdfColors.black),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ใบนำส่งรายได้ฝ่ายบัตร',
                          style: pw.TextStyle(font: assets.pgVim, fontSize: 15, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('Income Report',
                          style: pw.TextStyle(font: assets.trajan, fontSize: 15, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    field('ชื่อ - สกุล', name, name.isNotEmpty ? assets.pgVim : assets.trajan, 'Name - surname'),
                    pw.SizedBox(width: 40),
                    field('เลขประจำตัว', code, assets.trajan, 'Staff ID NO.'),
                  ]),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.Text('วันที่', style: thai),
                        pw.Text('  ${DateFmt.short(date)} ', style: thai),
                      ]),
                      pw.SizedBox(height: 2),
                      pw.Text(' Date', style: eng),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 17),
        if (showCreditTable)
          pw.Container(
            width: 400,
            height: 100,
            alignment: pw.Alignment.bottomCenter,
            child: pw.Column(
              children: [
                pw.Spacer(),
                pw.Text('นำส่งสินเชื่อ',
                    style: pw.TextStyle(font: assets.pgVim, fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    columnTitle('rsvn', assets.pgVim, 40),
                    columnTitle('Agent', assets.pgVim, 250),
                    columnTitle('PayType', assets.pgVim, 55),
                    columnTitle('Amount', assets.trajan, 55),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
    pw.SizedBox(height: 10),
  ];
}
