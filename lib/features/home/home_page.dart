import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/surfaces.dart';
import '../credit/credit_page.dart';
import '../pay_advance/pay_advance_page.dart';
import 'widgets/nav_actions.dart';

/// App shell: floating nav bar with the Credit and Pay Advance tabs.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  final _creditPending = ValueNotifier<int?>(null);
  final _advancePending = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _tabs.dispose();
    _creditPending.dispose();
    _advancePending.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: _NavBar(
              selected: _tabs.index,
              onSelect: _tabs.animateTo,
              tabs: [
                _TabInfo(Icons.credit_card_rounded, 'เงินเชื่อ', 'Credit', _creditPending),
                _TabInfo(Icons.account_balance_wallet_outlined, 'เงินรับล่วงหน้า', 'Pay Advance', _advancePending),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CreditPage(onPendingCount: (n) => _creditPending.value = n),
                PayAdvancePage(onPendingCount: (n) => _advancePending.value = n),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String label;
  final String labelEng;
  final ValueNotifier<int?> count;

  const _TabInfo(this.icon, this.label, this.labelEng, this.count);
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.selected, required this.onSelect, required this.tabs});

  final int selected;
  final ValueChanged<int> onSelect;
  final List<_TabInfo> tabs;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.glow(AppColors.magenta, opacity: .8),
          ),
          child: const Icon(Icons.attractions_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 11),
        if (wide)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Carnival Magic', style: AppText.display(15)),
            Text('Receiving App', style: AppText.body(12, color: AppColors.muted)),
          ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.ink.withOpacity(.05), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < tabs.length; i++)
              _TabPill(info: tabs[i], selected: selected == i, onTap: () => onSelect(i), showEnglish: wide),
          ]),
        ),
        const Spacer(),
        PendingBell(
          tabs: [for (final t in tabs) (icon: t.icon, label: t.label, count: t.count)],
          onSelect: onSelect,
        ),
        const SizedBox(width: 10),
        UserChip(compact: !wide),
      ]),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.info, required this.selected, required this.onTap, required this.showEnglish});

  final _TabInfo info;
  final bool selected;
  final VoidCallback onTap;
  final bool showEnglish;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected ? AppColors.glow(const Color(0xFF781E46), opacity: .4) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(info.icon, size: 18, color: selected ? AppColors.magenta : AppColors.muted),
            const SizedBox(width: 9),
            Text(info.label,
                style: AppText.body(14, color: selected ? AppColors.ink : AppColors.muted, weight: FontWeight.w500)),
            if (showEnglish) ...[
              const SizedBox(width: 6),
              Text(info.labelEng, style: AppText.body(12, color: AppColors.faint)),
            ],
            ValueListenableBuilder<int?>(
              valueListenable: info.count,
              builder: (context, count, _) => count == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: 9),
                      child: CountBadge(
                        text: '$count',
                        background: selected ? AppColors.magenta : AppColors.magentaSoft,
                        foreground: selected ? Colors.white : AppColors.magentaDark,
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
