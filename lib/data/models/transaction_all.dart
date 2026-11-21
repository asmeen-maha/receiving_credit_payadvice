import '../../core/utils/formatters.dart';

/// Nested lists may come back as `null`, `""` or `{}` when empty.
List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) => json is List
    ? [for (final e in json) if (e is Map<String, dynamic>) fromJson(e)]
    : <T>[];

/// A cashier's daily transaction summary (ticketing API `reportpaymentall`).
class TransactionAll {
  final String? userid;
  final String? code;
  final String? name;
  final List<Creditcard> creditcard;
  final List<Notesandcoins> notesandcoins;
  final List<Payeshop> payeshop;
  final List<Details> details;
  final List<NotesandcoinsDetail> notesandcoinsDetail;

  const TransactionAll({
    this.userid,
    this.code,
    this.name,
    this.creditcard = const [],
    this.notesandcoins = const [],
    this.payeshop = const [],
    this.details = const [],
    this.notesandcoinsDetail = const [],
  });

  factory TransactionAll.fromJson(Map<String, dynamic> json) => TransactionAll(
        userid: jsonString(json['userid']),
        code: jsonString(json['code']),
        name: jsonString(json['name']),
        creditcard: _list(json['creditcard'], Creditcard.fromJson),
        notesandcoins: _list(json['notesandcoins'], Notesandcoins.fromJson),
        payeshop: _list(json['payeshop'], Payeshop.fromJson),
        details: _list(json['details'], Details.fromJson),
        notesandcoinsDetail: _list(json['notesandcoins_detail'], NotesandcoinsDetail.fromJson),
      );

  static List<TransactionAll> fromJsonList(List list) => list.map((item) => TransactionAll.fromJson(item)).toList();

  int get userIdValue => int.tryParse(userid ?? '') ?? 0;

  /// Sum of e-shop payments whose reference is `payin`.
  double get payInAmount => payeshop
      .where((p) => (p.referno ?? '').toLowerCase() == 'payin')
      .fold(0.0, (sum, p) => sum + parseAmount(p.amount));
}

class Creditcard {
  final String? idcreditcard;
  final String? saledate;
  final String? userid;
  final String? point;
  final String? cardno;
  final String? amount;

  const Creditcard({this.idcreditcard, this.saledate, this.userid, this.point, this.cardno, this.amount});

  factory Creditcard.fromJson(Map<String, dynamic> json) => Creditcard(
        idcreditcard: jsonString(json['idcreditcard']),
        saledate: jsonString(json['saledate']),
        userid: jsonString(json['userid']),
        point: jsonString(json['point']),
        cardno: jsonString(json['cardno']),
        amount: jsonString(json['amount']),
      );
}

class Notesandcoins {
  final String? idnotesandcoins;
  final String? saledate;
  final String? userid;
  final String? point;
  final String? ntype;
  final String? qty;
  final String? amount;

  const Notesandcoins(
      {this.idnotesandcoins, this.saledate, this.userid, this.point, this.ntype, this.qty, this.amount});

  factory Notesandcoins.fromJson(Map<String, dynamic> json) => Notesandcoins(
        idnotesandcoins: jsonString(json['idnotesandcoins']),
        saledate: jsonString(json['saledate']),
        userid: jsonString(json['userid']),
        point: jsonString(json['point']),
        ntype: jsonString(json['ntype']),
        qty: jsonString(json['qty']),
        amount: jsonString(json['amount']),
      );
}

class Payeshop {
  final String? idpayeshop;
  final String? point;
  final String? saledate;
  final String? salecode;
  final String? referno;
  final String? amount;
  final String? docdate;

  const Payeshop({this.idpayeshop, this.point, this.saledate, this.salecode, this.referno, this.amount, this.docdate});

  factory Payeshop.fromJson(Map<String, dynamic> json) => Payeshop(
        idpayeshop: jsonString(json['idpayeshop']),
        point: jsonString(json['point']),
        saledate: jsonString(json['saledate']),
        salecode: jsonString(json['salecode']),
        referno: jsonString(json['referno']),
        amount: jsonString(json['amount']),
        docdate: jsonString(json['docdate']),
      );
}

class Details {
  final String? rsvn;
  final String? trrunno;
  final String? refno;
  final String? amount;
  final String? extcode;
  final String? accode;

  const Details({this.rsvn, this.trrunno, this.refno, this.amount, this.extcode, this.accode});

  factory Details.fromJson(Map<String, dynamic> json) => Details(
        rsvn: jsonString(json['rsvn']),
        trrunno: jsonString(json['trrunno']),
        refno: jsonString(json['refno']),
        amount: jsonString(json['amount']),
        extcode: jsonString(json['extcode']),
        accode: jsonString(json['accode']),
      );
}

class NotesandcoinsDetail {
  final String? idnotesandcoins;
  final String? saledate;
  final String? userid;
  final String? point;
  final String? currencyCode;
  final String? rate;
  final String? qty;
  final String? amount;

  const NotesandcoinsDetail({
    this.idnotesandcoins,
    this.saledate,
    this.userid,
    this.point,
    this.currencyCode,
    this.rate,
    this.qty,
    this.amount,
  });

  factory NotesandcoinsDetail.fromJson(Map<String, dynamic> json) => NotesandcoinsDetail(
        idnotesandcoins: jsonString(json['idnotesandcoins']),
        saledate: jsonString(json['saledate']),
        userid: jsonString(json['userid']),
        point: jsonString(json['point']),
        currencyCode: jsonString(json['currency_code']),
        rate: jsonString(json['rate']),
        qty: jsonString(json['qty']),
        amount: jsonString(json['amount']),
      );
}
