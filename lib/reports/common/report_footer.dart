import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import 'report_assets.dart';

abstract final class CompanyInfo {
  static const addressThai = 'บริษัท คาร์นิวัลเมจิก จำกัด 999 หมู่ 3 ตำบลกมลา อำเภอกะทู้ จังหวัดภูเก็ต 83150';
  static const addressEng = 'Carnival Magic Co., Ltd. 999 Moo 3 Kamala Kathu phuket 83150 Thailand';
  static const contactCredit = 'Tel: 076 385222  Email: credit@carnivalmagic.fun';
  static const contactTicketing = 'Tel: 076 385222  Email: ticketing@carnivalmagic.fun';
}

/// Thin vertical divider used in page footers.
pw.Widget footerDivider() => pw.Container(
      height: 25,
      width: 0.7,
      color: PdfColors.black,
      margin: const pw.EdgeInsets.only(top: 0.3 * PdfPageFormat.cm),
    );

/// Company address block used in page footers.
pw.Widget companyAddress(
  ReportAssets assets, {
  required String contact,
  required pw.Font contactFont,
  double fontSize = 5.5,
}) {
  return pw.Container(
    width: 230,
    alignment: pw.Alignment.center,
    margin: const pw.EdgeInsets.only(top: 0.3 * PdfPageFormat.cm),
    child: pw.Column(
      children: [
        pw.Text(CompanyInfo.addressThai, style: pw.TextStyle(font: assets.pgVim, fontSize: fontSize)),
        pw.SizedBox(height: 3),
        pw.Text(CompanyInfo.addressEng, style: pw.TextStyle(font: assets.pgVim, fontSize: fontSize)),
        pw.SizedBox(height: 3),
        pw.Text(contact, style: pw.TextStyle(font: contactFont, fontSize: fontSize)),
      ],
    ),
  );
}

/// Standard A4 footer: report name | company address | print date | page x / y.
pw.Widget buildReportFooter(pw.Context context, ReportAssets assets, String reportName) {
  final smallText = pw.TextStyle(font: assets.pgVim, fontSize: 5);

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.SizedBox(width: 50),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(reportName, style: smallText),
      ),
      pw.SizedBox(width: 25),
      footerDivider(),
      companyAddress(assets, contact: CompanyInfo.contactCredit, contactFont: assets.trajanBold),
      footerDivider(),
      pw.SizedBox(width: 25),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(DateFmt.display(DateTime.now()), style: smallText),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 80),
        child: pw.Text(
          context.pagesCount == 1 ? '' : '${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: assets.trajanBold, fontSize: 6),
        ),
      ),
    ],
  );
}
