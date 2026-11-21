import 'cash_advance.dart';

/// Rows grouped by the staff member (`userid`) who recorded them.
class StaffGroup {
  final String userId;
  final String name;
  final List<CashAdvance> items;

  StaffGroup({required this.userId, required this.name, required this.items});

  double get total => items.totalAmount;

  /// Groups [rows] by `userid`, keeping first-seen order.
  /// Set [sortByUserId] to order the groups numerically by user id.
  static List<StaffGroup> groupByStaff(Iterable<CashAdvance> rows, {bool sortByUserId = false}) {
    final groups = <String, StaffGroup>{};
    for (final row in rows) {
      final userId = row.userid ?? '';
      groups.putIfAbsent(userId, () => StaffGroup(userId: userId, name: row.name ?? '', items: [])).items.add(row);
    }
    final result = groups.values.toList();
    if (sortByUserId) {
      result.sort((a, b) => (int.tryParse(a.userId) ?? 0).compareTo(int.tryParse(b.userId) ?? 0));
    }
    return result;
  }
}
