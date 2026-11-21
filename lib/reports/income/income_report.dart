import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cash_advance.dart';
import '../../data/models/pay_type.dart';
import '../../data/models/transaction_all.dart';
import '../common/report_assets.dart';
import '../common/report_widgets.dart';
import 'income_footer.dart';
import 'income_header.dart';

/// ใบนำส่งรายได้ฝ่ายบัตร — one A4 landscape page per cashier for a single day.
///
/// Left half: card / other / foreign currency / notes & coins totals.
/// Right half: that cashier's pay-advance and credit rows.
abstract final class IncomeReport {
  /// Foreign currency rows: (label, currency_code).
  static const _currencies = [
    ('USD', '1'),
    ('SGD', '5'),
    ('TWD', '9'),
    ('JPY', '4'),
    ('HKD', '6'),
    ('GBP', '3'),
    ('CNY', '8'),
    ('AUD', '7'),
    ('EUR', '2'),
  ];

  /// Thai notes & coins shown next to each currency row (same order).
  static const _notes = ['1000', '500', '100', '50', '20', '10', '5', '2', '1'];

  static Future<Uint8List> generate({
    required DateTime date,
    required List<TransactionAll> cashiers,
    required List<CashAdvance> payAdvances,
    required List<CashAdvance> credits,
    required List<PayType> payTypes,
  }) async {
    final assets = await ReportAssets.load(logo: ReportLogo.ticketing);
    final payTypeNames = PayTypeNames(payTypes);
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    for (final cashier in cashiers) {
      final adv = payAdvances.where((item) => item.userid == cashier.userid).toList();
      final credit = credits.where((item) => item.userid == cashier.userid).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.only(
            top: .5 * PdfPageFormat.cm,
            left: .45 * PdfPageFormat.cm,
            right: .5 * PdfPageFormat.cm,
            bottom: .5 * PdfPageFormat.cm,
          ),
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: buildIncomeHeader(
              assets: assets,
              date: date,
              name: cashier.name ?? '',
              code: cashier.code ?? '',
              showCreditTable: adv.isNotEmpty || credit.isNotEmpty,
            ),
          ),
          build: (context) => [
            pw.Row(
              children: [
                _IncomeSummary(assets, cashier).build(),
                pw.Container(
                  width: 400,
                  height: 335,
                  margin: const pw.EdgeInsets.only(left: 17),
                  child: pw.Column(
                    children: [
                      ..._creditSection(assets, payTypeNames, 'Pay advance', adv),
                      ..._creditSection(assets, payTypeNames, 'Credit', credit),
                    ],
                  ),
                ),
              ],
            ),
          ],
          footer: (context) => pw.Column(children: [buildIncomeFooter(context, assets, cashier.name ?? '')]),
        ),
      );
    }

    return pdf.save();
  }

  /// Chip title, item rows, then Cash / Credit / Grand total.
  static List<pw.Widget> _creditSection(
    ReportAssets assets,
    PayTypeNames payTypeNames,
    String title,
    List<CashAdvance> items,
  ) {
    final cash = items.where((i) => i.accode == AccountCode.cash);
    final card = items.where((i) => i.accode == AccountCode.creditCard);
    final cashAmt = cash.totalAmount;
    final cardAmt = card.totalAmount;
    final total = pw.TextStyle(font: assets.trajan, fontSize: 10, fontWeight: pw.FontWeight.bold);

    pw.Widget totalRow(String label, double amount, {bool grand = false}) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: grand
                    ? pw.TextStyle(font: assets.trajanBold, fontSize: 11, fontWeight: pw.FontWeight.bold)
                    : total),
            pw.Text(formatMoney(amount),
                style: grand
                    ? pw.TextStyle(font: assets.trajanBold, fontSize: 10, fontWeight: pw.FontWeight.bold)
                    : total),
          ],
        );

    const noPadding = pw.EdgeInsets.zero;

    return [
      if (items.isNotEmpty)
        pw.Row(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: const pw.BoxDecoration(
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              color: PdfColors.grey400,
            ),
            child: pw.Text(title, style: pw.TextStyle(font: assets.pgVim, fontSize: 10)),
          ),
        ]),
      pw.SizedBox(height: 5),
      for (final item in items)
        pw.Row(children: [
          reportCell(assets, item.rsvn ?? '', 40, padding: noPadding),
          reportCell(assets, '${item.agentcode} ${item.agentname ?? ''}', 250, padding: noPadding),
          reportCell(assets, payTypeNames.of(item.accode), 55, padding: noPadding),
          reportCell(assets, formatMoney(item.amountValue), 55,
              alignment: pw.Alignment.centerRight, padding: noPadding),
        ]),
      if (items.isNotEmpty) ...[
        pw.Divider(thickness: .5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 150,
              child: pw.Column(children: [
                if (cash.isNotEmpty) totalRow('Total Cash', cashAmt),
                pw.SizedBox(height: 3),
                if (card.isNotEmpty) totalRow('Total Credit', cardAmt),
                pw.SizedBox(height: 3),
                totalRow('Grand Total', cashAmt + cardAmt, grand: true),
              ]),
            ),
          ],
        ),
      ],
    ];
  }
}

/// Left half of an income page: payment-method boxes for one cashier.
class _IncomeSummary {
  _IncomeSummary(this.assets, this.data);

  final ReportAssets assets;
  final TransactionAll data;

  pw.TextStyle get _label => pw.TextStyle(font: assets.pgVim, fontSize: 7, fontWeight: pw.FontWeight.bold);
  pw.TextStyle get _sublabel => pw.TextStyle(font: assets.pgVim, fontSize: 6);
  pw.TextStyle get _amountBold => pw.TextStyle(font: assets.trajanBold, fontSize: 8, fontWeight: pw.FontWeight.bold);

  // ---- data ----

  double get _creditCardAmount => data.creditcard.isNotEmpty ? parseAmount(data.creditcard.first.amount) : 0.0;
  double get _eShopAmount => data.payeshop.fold(0.0, (s, p) => s + parseAmount(p.amount));
  double get _notesAmount => data.notesandcoins.fold(0.0, (s, n) => s + parseAmount(n.amount));
  double get _currencyAmount => data.notesandcoinsDetail.fold(0.0, (s, c) => s + parseAmount(c.amount));

  ({String qty, double amount}) _note(String type) {
    for (final n in data.notesandcoins) {
      if (n.ntype == type) return (qty: n.qty ?? '0', amount: parseAmount(n.amount));
    }
    return (qty: '0', amount: 0.0);
  }

  ({String qty, String rate, double amount}) _currency(String code) {
    for (final c in data.notesandcoinsDetail) {
      if (c.currencyCode == code) {
        return (qty: c.qty ?? '0', rate: c.rate ?? '0.00', amount: parseAmount(c.amount));
      }
    }
    return (qty: '0', rate: '0.00', amount: 0.0);
  }

  // ---- boxes ----

  pw.Widget _box(String text, double width, double padding, pw.Alignment alignment,
      {double? height, pw.TextStyle? style}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      height: height,
      width: width,
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      alignment: alignment,
      child: pw.Text(text, style: style ?? _label),
    );
  }

  /// Two-line (Thai / English) header box.
  pw.Widget _titleBox(String title, String label, double width, double padding, {bool showLabel = true}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      width: width,
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      alignment: pw.Alignment.center,
      child: pw.Column(children: [
        pw.Text(title, style: _label),
        if (showLabel) ...[pw.SizedBox(height: 2), pw.Text(label, style: _sublabel)],
      ]),
    );
  }

  /// Title box + amount box on one row.
  pw.Widget _amountRow(
    String title,
    String label,
    String amount, {
    required double titleWidth,
    required double amountWidth,
    required double height,
    required double padding,
    bool showLabel = true,
    bool boldAmount = true,
  }) {
    return pw.Row(children: [
      _titleBox(title, label, titleWidth, padding, showLabel: showLabel),
      _box(amount, amountWidth, 2, pw.Alignment.centerRight, height: height, style: boldAmount ? _amountBold : _label),
    ]);
  }

  /// Small "other" payment row (E-SHOP, VOUCHER, ...).
  pw.Widget _otherRow(String title, double amount) => _amountRow(title, '', formatMoney(amount),
      titleWidth: 70, amountWidth: 50, height: 15, padding: 4, showLabel: false, boldAmount: false);

  pw.Widget _currencyRow(String currency, String currencyCode, String noteType) {
    final c = _currency(currencyCode);
    final n = _note(noteType);
    final style = pw.TextStyle(font: assets.pgVim, fontSize: 7);
    pw.Widget cell(String text, double width, double padding, pw.Alignment align, {double? height}) =>
        _box(text, width, padding, align, height: height, style: style);

    return pw.Row(children: [
      cell(currency, 30, 4.5, pw.Alignment.center),
      cell(c.rate, 30, 2, pw.Alignment.centerRight, height: 16),
      cell(c.qty, 30, 2, pw.Alignment.centerRight, height: 16),
      cell(formatMoney(c.amount), 45, 2, pw.Alignment.centerRight, height: 16),
      cell(noteType, 40, 4.5, pw.Alignment.center),
      cell(n.qty, 35, 2, pw.Alignment.centerRight, height: 16),
      cell(formatMoney(n.amount), 60, 2, pw.Alignment.centerRight, height: 16),
    ]);
  }

  pw.Widget _grandTotalRow(String title, String label, double amount) {
    final isRefund = label == 'Refund';
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          width: 96,
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [pw.Text(title, style: _label), pw.SizedBox(height: 2), pw.Text(label, style: _sublabel)],
          ),
        ),
        _box(formatMoney(amount), 60, 2, pw.Alignment.centerRight,
            height: 23, style: isRefund ? pw.TextStyle(font: assets.pgVim, fontSize: 7) : _amountBold),
      ],
    );
  }

  pw.Widget _remarkLine() => pw.Text(
        '             _________________________________________________________________________',
        style: pw.TextStyle(font: assets.trajan, fontSize: 6),
      );

  pw.Widget build() {
    final payIn = data.payInAmount;
    final eShop = _eShopAmount;
    final notes = _notesAmount;
    final grandTotal = notes + _creditCardAmount + eShop;
    const refund = 0.0;

    final leftColumn = pw.Column(children: [
      _titleBox('บัตรเครดิต', 'Credit Card', 120, 6),
      _amountRow('(1) รวม', 'Total', formatMoney(_creditCardAmount),
          titleWidth: 70, amountWidth: 50, height: 21, padding: 3),
      _titleBox('เอฟซีคอยน์', 'FCcion', 120, 6),
      _amountRow('(2) รวม', 'Total', '0.00', titleWidth: 70, amountWidth: 50, height: 21, padding: 3),
      _titleBox('อื่นๆ', 'Other', 120, 6),
      _otherRow('E-SHOP', eShop - payIn),
      _otherRow('VOUCHER', 0),
      _otherRow('CHEQUE', 0),
      _otherRow('PAY-IN', payIn),
      _otherRow('TAX', 0),
      _otherRow('GIFT CERTIFICATE', 0),
      _amountRow('(3) รวม /Total', 'Total', formatMoney(eShop),
          titleWidth: 70, amountWidth: 50, height: 15, padding: 4, showLabel: false),
    ]);

    final rightColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          _titleBox('เงินสกุลต่างประเทศ', 'Foreign Currency', 135, 6),
          _titleBox('ธนบัตรและเหรียญกษาปณ์', 'Notes & Coins', 135, 6),
        ]),
        for (var i = 0; i < IncomeReport._currencies.length; i++)
          _currencyRow(IncomeReport._currencies[i].$1, IncomeReport._currencies[i].$2, IncomeReport._notes[i]),
        pw.Row(children: [
          _titleBox('(4) รวม', 'Total', 60, 2.5),
          _box(formatMoney(_currencyAmount), 75, 2, pw.Alignment.centerRight, height: 20, style: _amountBold),
          _box('0.50', 40, 6.5, pw.Alignment.center),
          _box(_note('0.50').qty, 35, 2, pw.Alignment.centerRight, height: 20),
          _box(formatMoney(_note('0.50').amount), 60, 2, pw.Alignment.centerRight, height: 20),
        ]),
        pw.Row(children: [
          _box('รายได้รอบ 1 / Amount (First Collection)', 135, 5, pw.Alignment.center),
          _box('0.25', 40, 5, pw.Alignment.center),
          _box(_note('0.25').qty, 35, 2, pw.Alignment.centerRight, height: 17),
          _box(formatMoney(_note('0.25').amount), 60, 2, pw.Alignment.centerRight, height: 17),
        ]),
        pw.Row(children: [
          _amountRow('(5) เงินสด', 'Cash', '0.00', titleWidth: 55, amountWidth: 80, height: 21, padding: 3),
          _amountRow('(6) รวม', 'Total', formatMoney(notes), titleWidth: 75, amountWidth: 60, height: 21, padding: 3),
        ]),
      ],
    );

    return pw.Container(
      width: 395,
      height: 335,
      child: pw.Column(children: [
        pw.Row(children: [leftColumn, pw.SizedBox(width: 6), rightColumn]),
        pw.Row(children: [
          pw.SizedBox(
            width: 240,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 6),
                pw.Text('หมายเหตุ ', style: _label),
                pw.SizedBox(height: 2),
                pw.Text('Remark', style: _sublabel),
                for (var i = 0; i < 3; i++) ...[pw.SizedBox(height: 10), _remarkLine()],
              ],
            ),
          ),
          pw.Column(children: [
            _grandTotalRow('รวมทั้งสิ้น', 'Grand Total', grandTotal),
            _grandTotalRow('หักรับคืนคูปอง', 'Refund', refund),
            _grandTotalRow('รวมรายได้สุทธิ์', 'Net Amount', grandTotal - refund),
          ]),
        ]),
      ]),
    );
  }
}
