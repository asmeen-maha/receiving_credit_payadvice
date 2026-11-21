import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import 'report_assets.dart';

/// Standard A4 portrait page margins for the credit reports.
const pw.EdgeInsets a4ReportMargin = pw.EdgeInsets.only(
  left: 1.5 * PdfPageFormat.cm,
  right: 1 * PdfPageFormat.cm,
  bottom: 1 * PdfPageFormat.cm,
  top: 1 * PdfPageFormat.cm,
);

/// A table column: header label + fixed width (points).
class ReportColumn {
  final String title;
  final double width;
  const ReportColumn(this.title, this.width);
}

/// One body cell: 9pt Thai font with 3pt spacing below.
pw.Widget reportCell(
  ReportAssets assets,
  String text,
  double width, {
  pw.Alignment alignment = pw.Alignment.centerLeft,
  pw.EdgeInsets padding = const pw.EdgeInsets.only(left: 5),
}) {
  return pw.Column(
    children: [
      pw.Container(
        width: width,
        alignment: alignment,
        padding: padding,
        child: pw.Text(text, style: pw.TextStyle(font: assets.pgVim, fontSize: 9)),
      ),
      pw.SizedBox(height: 3),
    ],
  );
}

/// Right-aligned amount cell.
pw.Widget reportAmountCell(ReportAssets assets, double amount, double width) => reportCell(
      assets,
      formatMoney(amount),
      width,
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(right: 5),
    );

/// Grey rounded label with a staff member's name, shown above their rows.
pw.Widget staffNameChip(ReportAssets assets, String name) {
  return pw.Row(
    children: [
      pw.Container(
        margin: const pw.EdgeInsets.all(3),
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(8), color: PdfColors.grey300),
        child: pw.Text(name, style: pw.TextStyle(font: assets.pgVim, fontSize: 9, color: PdfColors.black)),
      ),
    ],
  );
}

pw.Widget _underline() => pw.Column(
      children: [
        pw.SizedBox(height: 3),
        pw.Divider(color: PdfColors.grey400, height: 1),
        pw.SizedBox(height: 3),
      ],
    );

/// `Grand Total  1,234.00` between two divider lines.
List<pw.Widget> grandTotalBlock(ReportAssets assets, double total) => [
      _underline(),
      pw.Padding(
        padding: const pw.EdgeInsets.only(right: 2, top: 3, bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Grand Total  ${formatMoney(total)}',
              style: pw.TextStyle(font: assets.trajanBold, fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
      _underline(),
    ];

/// Column header with top/bottom borders and a left border on every column
/// except those listed in [noLeftBorder].
pw.Widget borderedHeaderRow(
  ReportAssets assets,
  List<ReportColumn> columns, {
  required double height,
  required double fontSize,
  bool bold = false,
  Set<int> noLeftBorder = const {0},
}) {
  const side = pw.BorderSide(width: 0.5);
  return pw.Row(
    children: [
      for (var i = 0; i < columns.length; i++)
        pw.Container(
          height: height,
          width: columns[i].width,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border(top: side, bottom: side, left: noLeftBorder.contains(i) ? pw.BorderSide.none : side),
          ),
          child: pw.Text(
            columns[i].title,
            style: pw.TextStyle(
              font: assets.trajanBold,
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : null,
            ),
          ),
        ),
    ],
  );
}

/// Column header with grey filled cells.
pw.Widget filledHeaderRow(ReportAssets assets, List<ReportColumn> columns) {
  return pw.Row(
    children: [
      for (final column in columns)
        pw.Container(
          height: 25,
          width: column.width,
          margin: const pw.EdgeInsets.only(left: 1),
          alignment: pw.Alignment.center,
          color: PdfColors.grey400,
          child: pw.Text(
            column.title,
            style: pw.TextStyle(
              font: assets.trajanBold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
    ],
  );
}
