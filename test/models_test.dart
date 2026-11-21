import 'package:credit_payadvice_receiving/core/utils/formatters.dart';
import 'package:credit_payadvice_receiving/data/models/cash_advance.dart';
import 'package:credit_payadvice_receiving/data/models/pay_type.dart';
import 'package:credit_payadvice_receiving/data/models/staff_group.dart';
import 'package:credit_payadvice_receiving/data/models/transaction_all.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatters', () {
    test('formatMoney uses thousands separators and 2 decimals', () {
      expect(formatMoney(1234.5), '1,234.50');
      expect(formatMoney(0), '0.00');
    });

    test('parseAmount tolerates null and junk', () {
      expect(parseAmount('12.5'), 12.5);
      expect(parseAmount(null), 0.0);
      expect(parseAmount('abc'), 0.0);
    });

    test('DateFmt formats match the API and report formats', () {
      final d = DateTime(2026, 1, 12);
      expect(DateFmt.api(d), '2026-01-12');
      expect(DateFmt.display(d), '12/01/2026');
      expect(DateFmt.short(d), '12-01-26');
      expect(DateFmt.compact(d), '120126');
      expect(DateFmt.thaiLong(d), '12 มกราคม 2569');
    });
  });

  group('CashAdvance', () {
    test('status helpers and agent search', () {
      const row =
          CashAdvance(agentcode: 'C05498', agentname: 'Abetter Travel', paytype: '2', activeflag: 'Y', accode: '111');
      expect(row.isCredit, isTrue);
      expect(row.isVerified, isTrue);
      expect(row.hasAccountCode, isTrue);
      expect(row.matchesAgent('c054'), isTrue);
      expect(row.matchesAgent('abetter'), isTrue);
      expect(row.matchesAgent('zzz'), isFalse);
    });
  });

  test('StaffGroup.groupByStaff keeps order, sums totals, optionally sorts', () {
    const rows = [
      CashAdvance(userid: '20', name: 'B', amount: '10'),
      CashAdvance(userid: '3', name: 'A', amount: '5'),
      CashAdvance(userid: '20', name: 'B', amount: '2.5'),
    ];

    final groups = StaffGroup.groupByStaff(rows);
    expect(groups.map((g) => g.userId), ['20', '3']);
    expect(groups.first.total, 12.5);
    expect(groups.first.items.length, 2);

    final sorted = StaffGroup.groupByStaff(rows, sortByUserId: true);
    expect(sorted.map((g) => g.userId), ['3', '20']);
  });

  test('PayTypeNames falls back to "-"', () {
    final names = PayTypeNames(const [PayType(acccode: '111', shutname: 'เงินสด')]);
    expect(names.of('111'), 'เงินสด');
    expect(names.of('999'), '-');
  });

  test('TransactionAll.payInAmount sums only "payin" e-shop rows', () {
    final t = TransactionAll.fromJson({
      'userid': '1',
      'payeshop': [
        {'referno': 'PayIn', 'amount': '100'},
        {'referno': 'other', 'amount': '50'},
        {'referno': 'payin', 'amount': '25.5'},
      ],
    });
    expect(t.payInAmount, 125.5);
    expect(t.creditcard, isEmpty);
  });

  group('tolerant API parsing', () {
    test('amounts with thousands separators', () {
      expect(parseAmount('1,234.50'), 1234.5);
      expect(parseAmount(' 12 '), 12);
      expect(parseAmount('abc'), 0);
    });

    test('numeric JSON values become strings', () {
      final row = CashAdvance.fromJson({'id': 42, 'amount': 1500.5, 'userid': 12168, 'paytype': 2});
      expect(row.id, '42');
      expect(row.amountValue, 1500.5);
      expect(row.userIdValue, 12168);
      expect(row.isCredit, isTrue);
    });

    test('empty nested lists sent as null, string or map', () {
      final t = TransactionAll.fromJson({'userid': 7, 'creditcard': '', 'payeshop': {}, 'details': null});
      expect(t.userid, '7');
      expect(t.creditcard, isEmpty);
      expect(t.payeshop, isEmpty);
      expect(t.details, isEmpty);
    });
  });
}
