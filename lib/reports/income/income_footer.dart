import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import '../common/report_assets.dart';
import '../common/report_footer.dart';

/// Income report footer: "reported by / received by" signature boxes,
/// then the company address line.
pw.Widget buildIncomeFooter(pw.Context context, ReportAssets assets, String cashierName) {
  const fontSize = 5.5;
  const gap = 18.0;

  pw.Widget signatureBox(String title, String label, {String name = ''}) {
    final text = pw.TextStyle(font: assets.pgVim, fontSize: 7);
    const blank = '(________________________________)';
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: 195,
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            width: 40,
            alignment: pw.Alignment.center,
            child: pw.Column(children: [
              pw.Text(title, style: pw.TextStyle(font: assets.pgVim, fontSize: 6, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(label, style: pw.TextStyle(font: assets.pgVim, fontSize: 5)),
            ]),
          ),
          pw.SizedBox(height: 5),
          pw.Text(name.isNotEmpty ? '(              ${name.split(' ').first}              )' : blank, style: text),
          pw.SizedBox(height: 8),
          pw.Text(name.isNotEmpty ? '(              $name              )' : blank, style: text),
          pw.SizedBox(height: 8),
          pw.Text(
            name.isNotEmpty ? DateFmt.display(DateTime.now()) : '______/______/______',
            style: pw.TextStyle(font: assets.trajan, fontSize: 7),
          ),
        ],
      ),
    );
  }

  final small = pw.TextStyle(font: assets.pgVim, fontSize: fontSize);

  return pw.Column(
    children: [
      pw.SizedBox(height: 10),
      pw.Row(children: [
        signatureBox('ผู้นำส่ง', 'Reported by', name: cashierName),
        signatureBox('ผู้รับเงิน', 'Received by'),
      ]),
      pw.Row(
        children: [
          pw.SizedBox(width: gap),
          pw.Padding(padding: const pw.EdgeInsets.only(top: 10), child: pw.Text('Income Report', style: small)),
          pw.SizedBox(width: gap),
          footerDivider(),
          companyAddress(assets, contact: CompanyInfo.contactTicketing, contactFont: assets.trajan, fontSize: fontSize),
          footerDivider(),
          pw.SizedBox(width: gap),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(DateFmt.display(DateTime.now()), style: small),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, top: 10),
            child: pw.Text(
              context.pagesCount == 1 ? '' : '${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: assets.trajan, fontSize: 4),
            ),
          ),
        ],
      ),
    ],
  );
}
