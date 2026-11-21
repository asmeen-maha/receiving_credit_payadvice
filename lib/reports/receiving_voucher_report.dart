import 'dart:typed_data';

import 'package:number_to_thai_words/number_to_thai_words.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/models/cash_advance.dart';
import 'common/report_assets.dart';

/// ใบสำคัญรับ (Receiving Voucher) — A5 landscape, one credit row.
class ReceivingVoucherReport {
  ReceivingVoucherReport._(this.assets, this.item, this.printDate);

  final ReportAssets assets;
  final CashAdvance item;

  /// Date written in the "received by" signature box.
  final DateTime printDate;

  static Future<Uint8List> generate({required DateTime date, required CashAdvance item}) async {
    final assets = await ReportAssets.load();
    final report = ReceivingVoucherReport._(assets, item, date);

    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true)
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a5.portrait.landscape,
          margin: const pw.EdgeInsets.only(
            top: .5 * PdfPageFormat.cm,
            left: .6 * PdfPageFormat.cm,
            right: .6 * PdfPageFormat.cm,
            bottom: .5 * PdfPageFormat.cm,
          ),
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          header: (context) => report._header(),
          build: (context) => [report._accountTable()],
          footer: (context) => pw.Column(children: [report._footer()]),
        ),
      );
    return pdf.save();
  }

  /// Chart of accounts printed on the voucher: (10-digit code, name).
  /// `null` entries are blank rows.
  static const List<(String, String)?> _accounts = [
    ('1000000201', 'เงินสดรับ-รายได้'),
    ('1220000000', 'บัตรเครดิต'),
    ('1230000000', 'เช็ครับลงวันที่ล่วงหน้า'),
    ('1010004022', 'เงินฝากธนาคาร - Kbank (เชิงทะเล)'),
    ('1480000100', 'ถาษีหัก ณ ที่จ่าย - ปีนี้'),
    ('2150000100', 'รายได้รับล่วงหน้า (Non-Vat)'),
    ('2160000100', 'รายได้บัตร - รับล่วงหน้า (Non-Vat)'),
    ('2390000200', 'ภาษีขายที่ยังไม่ครบกำหนดชำระ'),
    null,
    null,
    ('1200000101', 'ลูกหนี้การค้า'),
    ('2390000100', 'ภาษีขาย'),
  ];

  static const _line = pw.BorderSide(width: .5, color: PdfColors.black);

  pw.TextStyle get _thai7 => pw.TextStyle(font: assets.pgVim, fontSize: 7);
  pw.TextStyle get _latin7 => pw.TextStyle(font: assets.trajan, fontSize: 7);
  pw.TextStyle get _latin8 => pw.TextStyle(font: assets.trajan, fontSize: 8);

  bool get _isCash => item.accode == AccountCode.cash;
  bool get _isCreditCard => item.accode == AccountCode.creditCard;
  String get _amountText => formatMoney(item.amountValue);

  // ---------------------------------------------------------------- header

  pw.Widget _header() {
    final date = DateTime.tryParse(item.trdate ?? '');
    final digits = (date == null ? '' : DateFmt.compact(date)).padRight(6).split('');
    const labels = ['D', 'D', 'M', 'M', 'Y', 'Y'];

    pw.Widget labelBox(double width, double height, String text, {bool bottom = false}) => pw.Container(
          width: width,
          height: height,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border(top: _line, left: _line, right: _line, bottom: bottom ? _line : pw.BorderSide.none),
          ),
          child: pw.Text(text, style: _thai7),
        );

    pw.Widget dateRow(List<String> values, {required bool top}) => pw.Row(
          children: [
            for (final v in values)
              pw.Container(
                width: 10,
                height: 12.5,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border(right: _line, bottom: _line, top: top ? _line : pw.BorderSide.none),
                ),
                child: pw.Text(v, style: _latin7),
              ),
          ],
        );

    final title = pw.TextStyle(font: assets.pgVim, fontSize: 15, fontWeight: pw.FontWeight.bold);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(assets.logo, width: 100),
            pw.SizedBox(width: 84),
            pw.Column(children: [pw.Text('ใบสำคัญรับ', style: title), pw.Text('Receving Voucher', style: title)]),
            pw.SizedBox(width: 84),
            pw.Column(children: [
              pw.Row(children: [labelBox(60, 25, 'เลขที่ /No.'), labelBox(60, 25, '')]),
              pw.Row(children: [labelBox(60, 6, ''), labelBox(60, 6, '')]),
              pw.Row(children: [
                labelBox(60, 25, 'วันที่ /DATE.', bottom: true),
                pw.Column(children: [dateRow(labels, top: true), dateRow(digits, top: false)]),
              ]),
            ]),
          ],
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 5, left: 20, bottom: 4),
          child: pw.Row(children: [
            pw.Text('รับเงินจาก /Received From     ', style: pw.TextStyle(font: assets.pgVim, fontSize: 8)),
            pw.Text('${item.agentname}', style: pw.TextStyle(font: assets.trajan, fontSize: 9)),
          ]),
        ),
      ],
    );
  }

  // ---------------------------------------------------------- account table

  pw.Widget _digitBox(String? digit) => pw.Container(
        width: 14,
        height: 12.5,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: .5, color: PdfColors.black)),
        child: digit == null ? null : pw.Text(digit, style: _thai7),
      );

  /// The 20 empty debit/credit digit cells at the end of each row.
  List<pw.Widget> _amountCells({double height = 12.5, bool bottom = true}) => List.generate(
        20,
        (_) => pw.Container(
          width: 14,
          height: height,
          decoration: pw.BoxDecoration(border: pw.Border(bottom: bottom ? _line : pw.BorderSide.none, right: _line)),
        ),
      );

  pw.Widget _accountRow((String, String)? account) {
    final List<String?> digits = account?.$1.split('') ?? List.filled(10, null);
    return pw.Row(children: [
      for (final d in digits) _digitBox(d),
      pw.Container(
        width: 140,
        height: 12.5,
        padding: account == null ? null : const pw.EdgeInsets.only(left: 10),
        alignment: account == null ? pw.Alignment.center : pw.Alignment.centerLeft,
        decoration: pw.BoxDecoration(
          border: pw.Border(top: account == null ? _line : pw.BorderSide.none, bottom: _line, right: _line),
        ),
        child: account == null ? null : pw.Text(account.$2, style: _thai7),
      ),
      ..._amountCells(),
    ]);
  }

  pw.Widget _accountTable() {
    const titles = [
      ('รหัสบัญชี', 'Accounr Code'),
      ('ชื่อบัญชี่', 'Account Name'),
      ('เดบิต', 'Debit'),
      ('เครดิต', 'Credit'),
    ];

    return pw.Column(children: [
      pw.Row(children: [
        for (var i = 0; i < titles.length; i++)
          pw.Container(
            width: 140,
            height: 20,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border(left: i == 0 ? _line : pw.BorderSide.none, top: _line, bottom: _line, right: _line),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [pw.Text(titles[i].$1, style: _thai7), pw.Text(titles[i].$2, style: _thai7)],
            ),
          ),
      ]),
      for (final account in _accounts) _accountRow(account),
      pw.Row(children: [
        pw.Container(
          width: 280,
          height: 13,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(border: pw.Border(right: _line, left: _line)),
          child: pw.Text('รวม /Total', style: _thai7),
        ),
        ..._amountCells(height: 13, bottom: false),
      ]),
    ]);
  }

  // ----------------------------------------------------------------- footer

  pw.Widget _choice(String title, bool checked) => pw.Row(children: [
        pw.Container(
          width: 10,
          height: 10,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.black, width: .5),
          ),
          child: pw.Padding(padding: const pw.EdgeInsets.only(bottom: 13), child: pw.Text(checked ? '/' : '')),
        ),
        pw.SizedBox(width: 2.5),
        pw.Text(title, style: _thai7),
      ]);

  pw.Widget _footer() {
    final amountInWords = NumberToThaiWords.convert(item.amountValue);
    const signers = [
      'จัดทำโดย /Prepared By',
      'รับเงินโดย /Received By',
      'ตรวจสอบโดย /Checked By',
      'ผ่านรายการโดย /Posted By'
    ];
    const receiverIndex = 1;

    return pw.Container(
      width: 560,
      height: 119,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: .5, color: PdfColors.black)),
      child: pw.Column(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Row(children: [
            pw.Text('รับชำระโดย', style: _thai7),
            pw.SizedBox(width: 10),
            _choice('เงินสด', _isCash),
            _isCash
                ? pw.Text('          $_amountText          ', style: _latin8)
                : pw.Text(' ________________________ ', style: _thai7),
            pw.Text(
              'บาท     ${_isCash ? '(           $amountInWords           )' : '_______________________________________'}',
              style: _thai7,
            ),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(right: 5, left: 5, bottom: 5),
          child: pw.Row(children: [
            _choice('บัตรเครดิต', _isCreditCard),
            pw.SizedBox(width: 5),
            _choice('เงินโอน', item.accode == AccountCode.transfer),
            pw.SizedBox(width: 5),
            _choice('เช็คเลขที่ _______________________ ธนาคาร _______________________ ลงวันที่ ____________ จำนวนเงิน',
                false),
            _isCreditCard
                ? pw.Text('     $_amountText     ', style: _latin8)
                : pw.Text(' ________________ ', style: _thai7),
            pw.Text('บาท', style: _thai7),
          ]),
        ),
        pw.Container(
          width: 560,
          height: 20,
          padding: const pw.EdgeInsets.only(left: 5),
          alignment: pw.Alignment.centerLeft,
          decoration: const pw.BoxDecoration(border: pw.Border(top: _line, bottom: _line)),
          child: pw.Text('หมายเหตุ /Remarks      ________________________________________________________________',
              style: _thai7),
        ),
        pw.Row(children: [
          for (var i = 0; i < signers.length; i++)
            pw.Container(
              width: 140,
              height: 20,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: _line, right: i == signers.length - 1 ? pw.BorderSide.none : _line),
              ),
              child: pw.Text(signers[i], style: _thai7),
            ),
        ]),
        pw.Row(children: [
          for (var i = 0; i < signers.length; i++)
            pw.Container(
              width: 140,
              height: 40,
              decoration: i == signers.length - 1 ? null : const pw.BoxDecoration(border: pw.Border(right: _line)),
              child: pw.Column(children: [
                pw.SizedBox(height: 10),
                pw.Text(i == receiverIndex ? '${item.name?.split(' ').first}' : '________________________',
                    style: _thai7),
                pw.SizedBox(height: 4),
                pw.Text(i == receiverIndex ? '(     ${item.name}     )' : '(                                        )',
                    style: _thai7),
                pw.SizedBox(height: 4),
                pw.Text(
                  i == receiverIndex ? 'วันที่ /Date   ${DateFmt.display(printDate)}' : 'วันที่ /Date _______________',
                  style: _thai7,
                ),
              ]),
            ),
        ]),
      ]),
    );
  }
}
