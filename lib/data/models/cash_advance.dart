import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

/// One credit / pay-advance row from the marketing API.
class CashAdvance {
  final String? id;
  final String? rsvn;
  final String? voucher;
  final String? trdate;
  final String? agentcode;
  final String? agentname;
  final String? userid;
  final String? paytype;
  final String? amount;
  final String? acc;
  final String? activeflag;
  final String? name;
  final String? accode;
  final String? datediff;

  const CashAdvance({
    this.id,
    this.rsvn,
    this.voucher,
    this.trdate,
    this.agentcode,
    this.agentname,
    this.userid,
    this.paytype,
    this.amount,
    this.acc,
    this.activeflag,
    this.name,
    this.accode,
    this.datediff,
  });

  factory CashAdvance.fromJson(Map<String, dynamic> json) => CashAdvance(
        id: jsonString(json['id']),
        rsvn: jsonString(json['rsvn']),
        voucher: jsonString(json['voucher']),
        trdate: jsonString(json['trdate']),
        agentcode: jsonString(json['agentcode']),
        agentname: jsonString(json['agentname']),
        userid: jsonString(json['userid']),
        paytype: jsonString(json['paytype']),
        amount: jsonString(json['amount']),
        acc: jsonString(json['acc']),
        activeflag: jsonString(json['activeflag']),
        name: jsonString(json['name']),
        accode: jsonString(json['accode']),
        datediff: jsonString(json['datediff']),
      );

  static List<CashAdvance> fromJsonList(List list) => list.map((item) => CashAdvance.fromJson(item)).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'rsvn': rsvn,
        'voucher': voucher,
        'trdate': trdate,
        'agentcode': agentcode,
        'agentname': agentname,
        'userid': userid,
        'paytype': paytype,
        'amount': amount,
        'acc': acc,
        'activeflag': activeflag,
        'name': name,
        'accode': accode,
        'datediff': datediff,
      };

  double get amountValue => parseAmount(amount);
  int get userIdValue => int.tryParse(userid ?? '') ?? 0;

  /// Transaction date shown on reports (`12/01/2026`), or empty if missing.
  String get displayDate {
    final date = DateTime.tryParse(trdate ?? '');
    return date == null ? '' : DateFmt.display(date);
  }

  bool get isCredit => paytype == PayTypeCode.credit;
  bool get isPayAdvance => paytype == PayTypeCode.payAdvance;
  bool get isVerified => activeflag == ActiveFlag.verified;
  bool get isPrinted => activeflag == ActiveFlag.printed;
  bool get hasAccountCode => accode != null && accode!.isNotEmpty;

  /// `C05498 Abetter Travel & Tours`
  String get agentLabel => '${agentcode ?? ''} ${agentname ?? ''}';

  /// Case-insensitive match on agent code or agent name.
  bool matchesAgent(String query) {
    final q = query.toLowerCase();
    return (agentcode ?? '').toLowerCase().contains(q) || (agentname ?? '').toLowerCase().contains(q);
  }
}

extension CashAdvanceListX on Iterable<CashAdvance> {
  double get totalAmount => fold(0.0, (sum, item) => sum + item.amountValue);
}
