import '../../core/utils/formatters.dart';

/// Account code → short display name (e.g. `111` → `เงินสด`).
class PayType {
  final String? acccode;
  final String? shutname;

  const PayType({this.acccode, this.shutname});

  factory PayType.fromJson(Map<String, dynamic> json) =>
      PayType(acccode: jsonString(json['acccode']), shutname: jsonString(json['shutname']));

  static List<PayType> fromJsonList(List list) => list.map((item) => PayType.fromJson(item)).toList();

  Map<String, dynamic> toJson() => {'acccode': acccode, 'shutname': shutname};
}

/// Lookup table built from the pay-type list.
class PayTypeNames {
  final Map<String, String> _names;

  PayTypeNames(List<PayType> payTypes)
      : _names = {
          for (final p in payTypes)
            if (p.acccode != null) p.acccode!: p.shutname ?? '',
        };

  /// Display name for [accode], or `-` when unknown.
  String of(String? accode) => _names[accode] ?? '-';

  /// Display name for the UI; unknown codes read "ไม่ระบุ" (not specified).
  String label(String? accode) => _names[accode] ?? 'ไม่ระบุ';
}
