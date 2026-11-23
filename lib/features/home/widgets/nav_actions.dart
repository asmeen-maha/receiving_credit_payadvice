import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/user/desk_user.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/surfaces.dart';

/// One entry in the bell menu: a tab and its pending count.
typedef PendingTab = ({IconData icon, String label, ValueNotifier<int?> count});

/// Bell with a dot while anything is waiting; the menu lists pending counts
/// per tab and jumps to the chosen tab.
class PendingBell extends StatelessWidget {
  const PendingBell({super.key, required this.tabs, required this.onSelect});

  final List<PendingTab> tabs;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([for (final t in tabs) t.count]),
      builder: (context, _) {
        final total = tabs.fold<int>(0, (sum, t) => sum + (t.count.value ?? 0));
        return PopupMenuButton<int>(
          tooltip: total == 0 ? 'ไม่มีรายการรอตรวจสอบ' : 'รอตรวจสอบ $total รายการ',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 10),
          color: Colors.white,
          elevation: 12,
          shadowColor: const Color(0x55781E46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onSelected: onSelect,
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              enabled: false,
              height: 36,
              child:
                  Text('รายการรอตรวจสอบ', style: AppText.body(12.5, color: AppColors.muted, weight: FontWeight.w600)),
            ),
            for (var i = 0; i < tabs.length; i++)
              PopupMenuItem<int>(
                value: i,
                child: SizedBox(
                  width: 240,
                  child: Row(children: [
                    Icon(tabs[i].icon, size: 18, color: AppColors.magenta),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tabs[i].label, style: AppText.body(14, weight: FontWeight.w500))),
                    CountBadge(
                      text: '${tabs[i].count.value ?? '-'}',
                      background: (tabs[i].count.value ?? 0) > 0 ? AppColors.magenta : AppColors.magentaSoft,
                      foreground: (tabs[i].count.value ?? 0) > 0 ? Colors.white : AppColors.magentaDark,
                    ),
                  ]),
                ),
              ),
          ],
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.75), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.ink2),
            ),
            if (total > 0)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.magenta,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Avatar, name and department of whoever uses this browser. Tap to edit.
class UserChip extends StatelessWidget {
  const UserChip({super.key, this.compact = false});

  /// Avatar only (narrow screens).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DeskUser?>(
      valueListenable: DeskUser.current,
      builder: (context, user, _) {
        final avatar = Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFFFFD1E4), Color(0xFFFFE4C8)]),
          ),
          child: user == null
              ? const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.magentaDark)
              : Text(user.initials, style: AppText.body(12.5, color: AppColors.magentaDark, weight: FontWeight.w600)),
        );
        return Tooltip(
          message: 'แก้ไขชื่อผู้ใช้งาน',
          child: Material(
            color: Colors.white.withOpacity(.7),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => showUserDialog(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 4, compact ? 4 : 14, 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  avatar,
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user?.name ?? 'ตั้งชื่อผู้ใช้งาน',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(13, weight: FontWeight.w600).copyWith(height: 1.2)),
                          Text(
                            user == null ? 'คลิกเพื่อระบุ' : (user.department.isEmpty ? '-' : user.department),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(11.5, color: AppColors.muted).copyWith(height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dialog to set this browser's user name and department.
Future<void> showUserDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x38491630),
    builder: (_) => const _UserDialog(),
  );
}

class _UserDialog extends StatefulWidget {
  const _UserDialog();

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _user = DeskUser.current.value;
  late final _name = TextEditingController(text: _user?.name ?? '');
  late final _department = TextEditingController(text: _user?.department ?? '');

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    DeskUser.save(name.isEmpty ? null : DeskUser(name: name, department: _department.text.trim()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          color: const Color(0xF2FFFFFF),
          radius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const IconBadge(
                  icon: Icons.person_outline_rounded, background: AppColors.magentaSoft, foreground: AppColors.magenta),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ผู้ใช้งานเครื่องนี้', style: AppText.display(18)),
                  Text('แสดงที่มุมขวาบนและในคำทักทาย · บันทึกไว้ในเบราว์เซอร์นี้',
                      style: AppText.body(12.5, color: AppColors.muted)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', hintText: 'เช่น สมใจ ใจดี'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _department,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'ฝ่าย / ตำแหน่ง', hintText: 'เช่น ฝ่ายบัญชี'),
            ),
            const SizedBox(height: 22),
            Row(children: [
              if (_user != null)
                TextButton(
                  onPressed: () {
                    DeskUser.save(null);
                    Navigator.pop(context);
                  },
                  child: Text('ล้างชื่อ', style: AppText.body(13.5, color: AppColors.danger)),
                ),
              const Spacer(),
              PillButton(label: 'ยกเลิก', style: PillStyle.white, onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              PillButton(label: 'บันทึก', icon: Icons.check_rounded, onPressed: _save),
            ]),
          ]),
        ),
      ),
    );
  }
}
