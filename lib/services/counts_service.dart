import 'package:hive/hive.dart';

class CountsService {
  static const String _boxName = 'daily_counts';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<int>(_boxName);
    }
  }

  static Box<int> get _box => Hive.box<int>(_boxName);

  static Future<Map<String, int>> fetchCounts({
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final _ = userId;
    final start = from ?? DateTime.now().subtract(const Duration(days: 365));
    final end = to ?? DateTime.now();
    final map = <String, int>{};
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      final key = _toDateKey(current);
      final count = _box.get(key, defaultValue: 0) ?? 0;
      if (count > 0) {
        map[key] = count;
      }
      current = current.add(const Duration(days: 1));
    }

    return map;
  }

  static int getCountForDate(DateTime date) {
    return _box.get(_toDateKey(date), defaultValue: 0) ?? 0;
  }

  static Future<void> setCountForDate(DateTime date, int count) async {
    await _box.put(_toDateKey(date), count);
  }

  static Future<void> resetCountForDate(DateTime date) async {
    await _box.put(_toDateKey(date), 0);
  }

  static String _toDateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }
}
