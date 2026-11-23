import 'package:flutter/foundation.dart';

import '../utils/local_store.dart';

/// Who is using this browser. The backend has no login, so each machine sets
/// its own name and department once; it is kept in localStorage.
@immutable
class DeskUser {
  final String name;
  final String department;

  const DeskUser({required this.name, this.department = ''});

  static const _nameKey = 'desk_user.name';
  static const _departmentKey = 'desk_user.department';

  /// Current user, or `null` when no name has been set on this browser.
  static final current = ValueNotifier<DeskUser?>(_load());

  static DeskUser? _load() {
    final name = readLocal(_nameKey)?.trim() ?? '';
    return name.isEmpty ? null : DeskUser(name: name, department: readLocal(_departmentKey)?.trim() ?? '');
  }

  /// Saves [user] for this browser; `null` clears it.
  static void save(DeskUser? user) {
    writeLocal(_nameKey, user?.name);
    writeLocal(_departmentKey, user?.department);
    current.value = user;
  }

  /// First name only, for greetings ("สวัสดีตอนบ่าย คุณสมใจ").
  String get firstName => name.split(RegExp(r'\s+')).first;

  /// Two-letter avatar text: the first consonant of the first two words for
  /// Thai (leading vowels such as เ/โ are skipped), else the first letters.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final letters = words.map((w) {
      final runes = w.runes.toList();
      final consonant = runes.firstWhere((r) => r >= 0x0E01 && r <= 0x0E2E, orElse: () => runes.first);
      return String.fromCharCode(consonant);
    });
    final text = letters.join().toUpperCase();
    return text.isEmpty ? '?' : text;
  }
}
