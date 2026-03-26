import 'session_service.dart';

class CountsService {
  static final Map<String, int> _memoryCounts = <String, int>{};

  static Future<void> init() async {}

  static Future<Map<String, int>> fetchCounts({
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final effectiveUserId = userId ?? SessionService.userId;
    final start = from ?? DateTime.now().subtract(const Duration(days: 365));
    final end = to ?? DateTime.now();
    if (SessionService.isAuthenticated &&
        effectiveUserId != null &&
        effectiveUserId.isNotEmpty) {
      return _readLocalRange(start, end);
    }
    return _readLocalRange(start, end);
  }

  static Map<String, int> _readLocalRange(
    DateTime start,
    DateTime end, {
    Map<String, int>? seed,
  }) {
    final map = <String, int>{...?seed};
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      final key = _toDateKey(current);
      final count = _memoryCounts[_scopedKey(key)] ?? 0;
      if (count > 0) {
        map[key] = count;
      }
      current = current.add(const Duration(days: 1));
    }

    return map;
  }

  static int getCountForDate(DateTime date) {
    return _memoryCounts[_scopedKey(_toDateKey(date))] ?? 0;
  }

  static Future<void> setCountForDate(DateTime date, int count) async {
    final normalizedCount = count.clamp(0, 9999);
    final dateKey = _toDateKey(date);
    _memoryCounts[_scopedKey(dateKey)] = normalizedCount;
  }

  static Future<void> resetCountForDate(DateTime date) async {
    await setCountForDate(date, 0);
  }

  static Future<void> seedDemoHistoryIfEmpty() async {
    if (_hasScopedCounts()) return;

    final today = DateTime.now();
    final demoCounts = <int, int>{
      0: 64,
      1: 108,
      2: 72,
      3: 144,
      4: 96,
      5: 54,
      6: 120,
      7: 88,
      8: 132,
      9: 76,
      10: 164,
      11: 92,
      12: 48,
      13: 108,
      14: 150,
      15: 84,
      16: 126,
      17: 97,
      18: 0,
      19: 112,
      20: 68,
      21: 135,
      22: 156,
      23: 82,
      24: 101,
      25: 128,
      26: 73,
      27: 118,
    };

    for (final entry in demoCounts.entries) {
      final date = today.subtract(Duration(days: entry.key));
      await setCountForDate(date, entry.value);
    }
  }

  static String _toDateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }

  static String _scopedKey(String dateKey) {
    return '${SessionService.storageScope}:$dateKey';
  }

  static bool _hasScopedCounts() {
    final prefix = '${SessionService.storageScope}:';
    return _memoryCounts.keys.any(
      (key) => key.startsWith(prefix) && (_memoryCounts[key] ?? 0) > 0,
    );
  }
}
