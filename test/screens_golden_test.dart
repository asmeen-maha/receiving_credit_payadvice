// Renders the main screens with fake data to PNGs for visual review.
// Run: flutter test --update-goldens --tags golden
@Tags(['golden'])
library;

import 'dart:io';

import 'package:credit_payadvice_receiving/app.dart';
import 'package:credit_payadvice_receiving/data/models/cash_advance.dart';
import 'package:credit_payadvice_receiving/data/models/pay_type.dart';
import 'package:credit_payadvice_receiving/data/models/transaction_all.dart';
import 'package:credit_payadvice_receiving/data/services/api_service.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApi extends ApiService {
  final _today = DateTime.now();

  String _d(int back) {
    final d = _today.subtract(Duration(days: back));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static const _agents = [
    ['C05498', 'Abetter Travel & Tours'],
    ['C02863', 'Freed Co., Ltd. (Apple Tour)'],
    ['C05034', 'Odeon Tour (Asia In Hand Co., Ltd.)'],
    ['C04112', 'Phuket Happy Holiday'],
    ['C03377', 'Siam Andaman Travel'],
    ['C05210', 'Golden Lotus Tour (Thailand)'],
    ['C01988', 'Patong Bay Holidays'],
  ];

  @override
  Future<List<PayType>?> fetchPayTypes() async => const [
        PayType(acccode: '111', shutname: 'เงินสด'),
        PayType(acccode: '114', shutname: 'บัตรเครดิต'),
        PayType(acccode: '133', shutname: 'เงินโอน'),
      ];

  @override
  Future<List<CashAdvance>?> fetchCreditRange({required String startDate, required String endDate}) async => [
        for (var i = 0; i < 11; i++)
          CashAdvance(
            id: '$i',
            rsvn: ['CZ38', 'UYZS', 'RZME', 'KX7Q', 'PL2D', 'MB91', 'TQ4H', 'ZN6E', 'HW3P', 'RD8A', 'FJ2K'][i],
            voucher: '${7040 + i * 7}',
            trdate: _d(i % 7),
            agentcode: _agents[i % 7][0],
            agentname: _agents[i % 7][1],
            userid: '${[12168, 301, 4550][i % 3]}',
            name: ['สมใจ ใจดี', 'มานี มีนา', 'ปิติ รักเรียน'][i % 3],
            paytype: '2',
            amount: '${[4800, 12600, 18450, 6300, 21900, 9750, 3200, 15480, 11250, 7900, 13800][i]}.00',
            accode: ['111', '114', '133'][i % 3],
            activeflag: [1, 3, 6, 8].contains(i) ? 'Y' : null,
          ),
      ];

  @override
  Future<List<CashAdvance>?> fetchPayAdvance({required String bookDate}) async => [
        for (var i = 0; i < 7; i++)
          CashAdvance(
            id: 'a$i',
            rsvn: ['QA4M', 'VB7T', 'LN2C', 'XE9R', 'GH5W', 'PK3S', 'MT8D'][i],
            voucher: '${7102 + i * 5}',
            trdate: bookDate,
            agentcode: _agents[i][0],
            agentname: _agents[i][1],
            userid: '12168',
            name: 'สมใจ ใจดี',
            paytype: '4',
            amount: '${[15000, 5000, 8400, 30000, 2500, 12000, 6750][i]}.00',
            accode: ['133', '111', '114', '133', '111', '133', null][i],
            activeflag: i == 1 || i == 4 ? 'Y' : null,
          ),
      ];

  @override
  Future<List<TransactionAll>?> fetchTransactions({required String showDate}) async => [
        for (final n in ['สมใจ ใจดี', 'มานี มีนา', 'ปิติ รักเรียน'])
          TransactionAll(userid: n.hashCode.toString(), code: 'S01', name: n),
      ];
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('Prompt',
        ['assets/fonts/Prompt-Regular.ttf', 'assets/fonts/Prompt-Medium.ttf', 'assets/fonts/Prompt-SemiBold.ttf']);
    await _loadFont('Anuphan',
        ['assets/fonts/Anuphan-Regular.ttf', 'assets/fonts/Anuphan-Medium.ttf', 'assets/fonts/Anuphan-SemiBold.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter';
    await _loadFont('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
    ApiService.instance = FakeApi();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(1600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('credit', (tester) async {
    await pumpApp(tester);
    await expectLater(find.byType(App), matchesGoldenFile('goldens/credit.png'));
    debugDisableShadows = true;
  });

  testWidgets('pay advance', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('เงินรับล่วงหน้า').first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(App), matchesGoldenFile('goldens/pay_advance.png'));
    debugDisableShadows = true;
  });

  testWidgets('verify dialog', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('ตรวจสอบทั้งหมดที่แสดง'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(App), matchesGoldenFile('goldens/verify_dialog.png'));
    debugDisableShadows = true;
  });

  testWidgets('agent report: type, pick an agent, enable the report buttons', (tester) async {
    await pumpApp(tester);
    final agentField = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText ?? '').startsWith('+ เพิ่มเอเย่นต์'));
    await tester.enterText(agentField, 'lotus');
    await tester.pump(const Duration(milliseconds: 100));
    // One in the table, one in the suggestion list.
    expect(find.text('Golden Lotus Tour (Thailand)'), findsNWidgets(2));
    // The suggestion overlay (OverlayPortal) sits before the table in the tree.
    await tester.tap(find.text('Golden Lotus Tour (Thailand)').first);
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(App), matchesGoldenFile('goldens/agent_report.png'));
    expect(find.text('C05210'), findsNWidgets(2)); // table row + chip
    expect(find.text('1 รายการ'), findsOneWidget);

    // Both reports generate a PDF; success clears the selection, failure shows a toast.
    for (final button in ['PDF รายการของเอเย่นต์', 'รายงานแยกตามรายชื่อ']) {
      if (find.text('C05210').evaluate().length < 2) {
        await tester.enterText(agentField, 'lotus');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Golden Lotus Tour (Thailand)').first);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.text(button));
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('สร้างรายงานไม่สำเร็จ'), findsNothing, reason: button);
      expect(find.text('C05210'), findsOneWidget, reason: '$button should clear the selection');
    }
    debugDisableShadows = true;
  });
}
