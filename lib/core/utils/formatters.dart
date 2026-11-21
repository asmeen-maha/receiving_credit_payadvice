import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');

/// `1234.5` → `1,234.50`
String formatMoney(num value) => _money.format(value);

/// Safely parses an API amount string (`1,234.50` is accepted); invalid or
/// null values become `0.0`.
double parseAmount(String? value) => double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0.0;

/// Reads a JSON value as a string. PHP may send ids and amounts as numbers,
/// which would otherwise throw a type error when assigned to `String?`.
String? jsonString(dynamic value) => value?.toString();

const List<String> _thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

const List<String> _thaiShortMonths = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

abstract final class DateFmt {
  /// `2026-01-12` — format sent to the API.
  static String api(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// `12/01/2026` — on-screen and report display.
  static String display(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  /// `12-01-26` — reference number / short date.
  static String short(DateTime d) => DateFormat('dd-MM-yy').format(d);

  /// `120126` — digits for the voucher date boxes.
  static String compact(DateTime d) => DateFormat('ddMMyy').format(d);

  /// `12 มกราคม 2569` — Thai long date with Buddhist year.
  static String thaiLong(DateTime d) => '${DateFormat('dd').format(d)} ${_thaiMonths[d.month - 1]} ${d.year + 543}';

  /// `12 ม.ค. 2569` — short Thai date with Buddhist year (UI).
  static String thaiShort(DateTime d) => '${d.day} ${_thaiShortMonths[d.month - 1]} ${d.year + 543}';

  /// `12 ม.ค. – 19 ม.ค. 2569` (UI). Repeats the year only when it differs.
  static String thaiRange(DateTime start, DateTime end) => start.year == end.year
      ? '${start.day} ${_thaiShortMonths[start.month - 1]} – ${thaiShort(end)}'
      : '${thaiShort(start)} – ${thaiShort(end)}';

  /// `12/01/2026 - 19/01/2026`
  static String range(DateTime start, DateTime end) => '${display(start)} - ${display(end)}';
}
