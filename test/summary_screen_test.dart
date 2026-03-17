import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countpluse/screens/summary_screen.dart';

const List<String> _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

Map<String, int> _buildCountsForRange(DateTime start, DateTime end, int value) {
  final map = <String, int>{};
  var current = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!current.isAfter(last)) {
    final key = current.toIso8601String().split('T').first;
    map[key] = value;
    current = current.add(const Duration(days: 1));
  }
  return map;
}

DateTime _stripTime(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _startOfWeek(DateTime date) {
  final offset = date.weekday % 7;
  return date.subtract(Duration(days: offset));
}

String _formatCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final indexFromEnd = text.length - i;
    buffer.write(text[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fixedNow = DateTime(2026, 2, 4);
    setSummaryNowProvider(() => fixedNow);
  });

  tearDown(() {
    resetSummaryNowProvider();
  });

  testWidgets('Weekly total updates when timeframe changes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    final today = _stripTime(DateTime(2026, 2, 4));
    final weekStart = today.subtract(const Duration(days: 6));
    final weekCounts = _buildCountsForRange(weekStart, today, 3);

    await tester.pumpWidget(
      MaterialApp(
        home: SummaryScreen(initialCounts: weekCounts, skipInitialLoad: true),
      ),
    );
    final countFinder = find.byKey(const Key('summary_total_count'));
    expect(countFinder, findsWidgets);
    expect(tester.widget<Text>(countFinder).data, _formatCount(21));

    // Switch to 6 Months, total should still include weekly data (21)
    await tester.tap(find.text('6 Months'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(countFinder).data, _formatCount(21));
  });

  testWidgets('Monthly labels show day-month for week starts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    final today = _stripTime(DateTime(2026, 2, 4));
    final end = _startOfWeek(today);
    final start = end.subtract(const Duration(days: 21));
    final counts = _buildCountsForRange(start, end, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: SummaryScreen(initialCounts: counts, skipInitialLoad: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    final label = '${end.day}-${_monthShort[end.month - 1]}';
    expect(find.text(label), findsWidgets);
  });
}
