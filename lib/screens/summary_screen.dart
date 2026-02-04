import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../services/counts_service.dart';
import '../theme/app_theme.dart';

const List<String> _weekdayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

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

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _timeframe = 'Weekly';
  Map<String, int> _countMap = {};
  bool _loadingCounts = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loadingCounts = true;
      _loadError = null;
    });
    try {
      final counts = await CountsService.fetchCounts();
      setState(() {
        _countMap = counts;
        _loadingCounts = false;
      });
    } catch (error) {
      setState(() {
        _loadError = error.toString();
        _loadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Summary', style: AppTypography.titleLarge),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              navIndexNotifier.value = 0;
            }
          },
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16,
                ),
                child: _TimeframeSelector(
                  value: _timeframe,
                  onChanged: (v) => setState(() => _timeframe = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: _AnalyticsCard(
                  timeframe: _timeframe,
                  countMap: _countMap,
                  isLoading: _loadingCounts,
                  loadError: _loadError,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Period Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Export',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _InsightsGrid(),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: const [
                    _MilestoneItem(
                      title: '1,000 Total Tally',
                      subtitle: 'Achieved 2 days ago',
                      leadingIcon: Icons.workspace_premium,
                      enabled: true,
                    ),
                    SizedBox(height: 12),
                    _MilestoneItem(
                      title: '50 Daily Goal',
                      subtitle: '8 counts remaining',
                      leadingIcon: Icons.gps_fixed,
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TimeframeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = ['Weekly', 'Monthly', '6 Months', 'Yearly'];
    const activeColor = Color(0xFF3A5A4A);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((opt) {
          final active = opt == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String timeframe;
  final Map<String, int> countMap;
  final bool isLoading;
  final String? loadError;

  const _AnalyticsCard({
    required this.timeframe,
    required this.countMap,
    required this.isLoading,
    required this.loadError,
  });

  @override
  Widget build(BuildContext context) {
    final countValue = isLoading
        ? '...'
        : _formatCount(_totalCountForTimeframe(timeframe, countMap));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and count
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COUNT FREQUENCY',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    countValue,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'counts',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatRangeForTimeframe(timeframe),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (loadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Using demo data',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Chart area
        const SizedBox(height: 12),
        SizedBox(
          height: 256,
          child: _MiniBarChart(timeframe: timeframe, countMap: countMap),
        ),
      ],
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final String timeframe;
  final Map<String, int> countMap;

  const _MiniBarChart({required this.timeframe, required this.countMap});
  @override
  Widget build(BuildContext context) {
    final data = _getChartData(countMap);
    final counts = data.counts;
    final labels = data.labels;
    final activeIndex = data.highlightIndex;
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelAreaHeight = 24.0;
        final barAreaHeight = (constraints.maxHeight - labelAreaHeight).clamp(
          0,
          constraints.maxHeight,
        );
        final totalLabelHeight = labelAreaHeight;
        final barGap = timeframe == 'Weekly' ? 6.0 : 4.0;

        return Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChartGridPainter(
                        labelAreaHeight: totalLabelHeight,
                        lineColor: AppColors.cardBorder.withValues(alpha: 0.6),
                        barCount: counts.length,
                        groupDividers: data.groupDividers,
                        drawBarDividers: data.drawBarDividers,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(counts.length, (i) {
                      final h = (counts[i] / _chartMaxCount).clamp(0.0, 1.0);
                      final isActive = i == activeIndex;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: barGap / 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: barAreaHeight.toDouble(),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: barAreaHeight * h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(AppRadius.xs),
                                      ),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 12,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: labelAreaHeight,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: labels[i].isNotEmpty
                                      ? Text(
                                          labels[i],
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            color: isActive
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                            fontWeight: isActive
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: timeframe == 'Monthly'
                                                ? 9
                                                : timeframe == '6 Months'
                                                ? 10
                                                : 11,
                                            height: 1,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                children: [
                  SizedBox(
                    height: barAreaHeight.toDouble(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '10k',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '5k',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '0',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: labelAreaHeight),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  _ChartData _getChartData(Map<String, int> countMap) {
    switch (timeframe) {
      case 'Weekly':
        final dates = _buildDailySeries(7);
        return _ChartData(
          counts: _dailyCounts(dates, countMap),
          labels: _labelsForWeekly(dates),
          groupDividers: const [],
          drawBarDividers: true,
          highlightIndex: dates.length - 1,
        );
      case 'Monthly':
        final range = _buildMonthlyRange();
        final dates = range.dates;
        return _ChartData(
          counts: _dailyCounts(dates, countMap),
          labels: _labelsForMonthly(dates),
          groupDividers: const [7, 14, 21, 28],
          drawBarDividers: true,
          highlightIndex: range.highlightIndex,
        );
      case '6 Months':
        return _buildSixMonthBuckets(countMap);
      case 'Yearly':
        return _buildYearlyBuckets(countMap);
      default:
        final dates = _buildDailySeries(7);
        return _ChartData(
          counts: _dailyCounts(dates, countMap),
          labels: _labelsForWeekly(dates),
          groupDividers: const [],
          drawBarDividers: true,
          highlightIndex: dates.length - 1,
        );
    }
  }
}

class _ChartGridPainter extends CustomPainter {
  final double labelAreaHeight;
  final Color lineColor;
  final int barCount;
  final List<int> groupDividers;
  final bool drawBarDividers;

  const _ChartGridPainter({
    required this.labelAreaHeight,
    required this.lineColor,
    required this.barCount,
    required this.groupDividers,
    required this.drawBarDividers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    final barHeight = size.height - labelAreaHeight;
    final dashedLevels = [1.0, 0.5];

    for (final level in dashedLevels) {
      final y = barHeight * (1 - level);
      double x = 0;
      while (x < size.width) {
        final nextX = (x + dashWidth).clamp(0.0, size.width).toDouble();
        canvas.drawLine(Offset(x, y), Offset(nextX, y), paint);
        x += dashWidth + dashSpace;
      }
    }

    canvas.drawLine(Offset(0, barHeight), Offset(size.width, barHeight), paint);

    if (barCount > 1) {
      final slotWidth = size.width / barCount;
      if (drawBarDividers) {
        for (var i = 1; i < barCount; i++) {
          final x = slotWidth * i;
          double y = 0;
          while (y < barHeight) {
            final nextY = (y + dashWidth).clamp(0.0, barHeight).toDouble();
            canvas.drawLine(Offset(x, y), Offset(x, nextY), paint);
            y += dashWidth + dashSpace;
          }
        }
      }

      for (final divider in groupDividers) {
        if (divider <= 0 || divider >= barCount) continue;
        final x = slotWidth * divider;
        final dividerPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.9)
          ..strokeWidth = 1.2;
        double y = 0;
        while (y < barHeight) {
          final nextY = (y + dashWidth).clamp(0.0, barHeight).toDouble();
          canvas.drawLine(Offset(x, y), Offset(x, nextY), dividerPaint);
          y += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartGridPainter oldDelegate) {
    return oldDelegate.labelAreaHeight != labelAreaHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.barCount != barCount ||
        oldDelegate.drawBarDividers != drawBarDividers ||
        oldDelegate.groupDividers != groupDividers;
  }
}

const int _chartMaxCount = 10000;

class _ChartData {
  final List<int> counts;
  final List<String> labels;
  final List<int> groupDividers;
  final bool drawBarDividers;
  final int highlightIndex;

  const _ChartData({
    required this.counts,
    required this.labels,
    required this.groupDividers,
    required this.drawBarDividers,
    required this.highlightIndex,
  });
}

DateTime _stripTime(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<DateTime> _buildDailySeries(int days) {
  final end = _stripTime(DateTime.now());
  return List.generate(days, (i) {
    final offset = days - 1 - i;
    return end.subtract(Duration(days: offset));
  });
}

class _MonthlyRange {
  final List<DateTime> dates;
  final int highlightIndex;

  const _MonthlyRange({required this.dates, required this.highlightIndex});
}

_MonthlyRange _buildMonthlyRange() {
  final today = _stripTime(DateTime.now());
  final start = _firstSundayOfMonth(today);
  final dates = List.generate(35, (i) => start.add(Duration(days: i)));
  var highlightIndex = dates.lastIndexWhere((d) => !d.isAfter(today));
  if (highlightIndex < 0) {
    highlightIndex = dates.length - 1;
  }
  return _MonthlyRange(dates: dates, highlightIndex: highlightIndex);
}

DateTime _startOfWeek(DateTime date) {
  final offset = date.weekday % 7;
  return date.subtract(Duration(days: offset));
}

DateTime _firstSundayOfMonth(DateTime date) {
  final firstDay = DateTime(date.year, date.month, 1);
  final offset = (DateTime.sunday - firstDay.weekday) % 7;
  return firstDay.add(Duration(days: offset));
}

List<int> _dailyCounts(List<DateTime> dates, Map<String, int> countMap) {
  final today = _stripTime(DateTime.now());
  return dates.map((date) {
    if (date.isAfter(today)) return 0;
    return _lookupCount(date, countMap);
  }).toList();
}

int _countForDate(DateTime date) {
  return 0;
}

int _averageCountForRange(
  DateTime start,
  DateTime end,
  DateTime today,
  Map<String, int> countMap,
) {
  if (start.isAfter(today)) return 0;
  var current = start;
  var total = 0;
  var days = 0;
  final last = end.isAfter(today) ? today : end;
  while (!current.isAfter(last)) {
    total += _lookupCount(current, countMap);
    days += 1;
    current = current.add(const Duration(days: 1));
  }
  if (days == 0) return 0;
  return (total / days).round().clamp(0, _chartMaxCount);
}

List<String> _labelsForWeekly(List<DateTime> dates) {
  return dates.map((date) => _weekdayShort[date.weekday - 1]).toList();
}

List<String> _labelsForMonthly(List<DateTime> dates) {
  return dates
      .map((date) => date.weekday == DateTime.sunday ? '${date.day}' : '')
      .toList();
}

_ChartData _buildSixMonthBuckets(Map<String, int> countMap) {
  final today = _stripTime(DateTime.now());
  final currentMonthStart = DateTime(today.year, today.month, 1);
  final monthStarts = List.generate(
    6,
    (i) => _shiftMonth(currentMonthStart, i - 5),
  );

  final counts = <int>[];
  final labels = <String>[];
  var highlightIndex = 0;
  var foundHighlight = false;

  for (var m = 0; m < monthStarts.length; m++) {
    final monthStart = monthStarts[m];
    final daysInMonth = _daysInMonth(monthStart.year, monthStart.month);
    for (var bucket = 0; bucket < 4; bucket++) {
      final startDay = 1 + (bucket * daysInMonth ~/ 4);
      final endDay = ((bucket + 1) * daysInMonth ~/ 4);
      final rangeStart = DateTime(monthStart.year, monthStart.month, startDay);
      final rangeEnd = DateTime(monthStart.year, monthStart.month, endDay);
      counts.add(_averageCountForRange(rangeStart, rangeEnd, today, countMap));
      labels.add(bucket == 0 ? _monthShort[monthStart.month - 1] : '');
      if (monthStart.year == today.year &&
          monthStart.month == today.month &&
          today.day >= startDay &&
          today.day <= endDay) {
        highlightIndex = counts.length - 1;
        foundHighlight = true;
      }
    }
  }

  return _ChartData(
    counts: counts,
    labels: labels,
    groupDividers: const [4, 8, 12, 16, 20],
    drawBarDividers: false,
    highlightIndex: foundHighlight
        ? highlightIndex
        : (counts.isEmpty ? 0 : counts.length - 1),
  );
}

_ChartData _buildYearlyBuckets(Map<String, int> countMap) {
  final today = _stripTime(DateTime.now());
  final year = today.year;
  final counts = <int>[];
  final labels = <String>[];

  for (var month = 1; month <= 12; month++) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month, _daysInMonth(year, month));
    counts.add(_averageCountForRange(monthStart, monthEnd, today, countMap));
    labels.add(_monthShort[month - 1]);
  }

  return _ChartData(
    counts: counts,
    labels: labels,
    groupDividers: const [],
    drawBarDividers: true,
    highlightIndex: today.month - 1,
  );
}

String _formatRangeForTimeframe(String timeframe) {
  final end = _stripTime(DateTime.now());
  DateTime start;
  switch (timeframe) {
    case 'Weekly':
      start = end.subtract(const Duration(days: 6));
      break;
    case 'Monthly':
      start = _buildMonthlyRange().dates.first;
      break;
    case '6 Months':
      start = _shiftMonth(DateTime(end.year, end.month, 1), -5);
      break;
    case 'Yearly':
      start = DateTime(end.year, 1, 1);
      break;
    default:
      start = end.subtract(const Duration(days: 6));
  }

  if (start.year == end.year) {
    return '${_formatMonthDay(start)} – ${_formatMonthDayYear(end)}';
  }
  return '${_formatMonthDayYear(start)} – ${_formatMonthDayYear(end)}';
}

String _formatMonthDay(DateTime date) {
  return '${_monthShort[date.month - 1]} ${date.day}';
}

String _formatMonthDayYear(DateTime date) {
  return '${_monthShort[date.month - 1]} ${date.day}, ${date.year}';
}

DateTime _shiftMonth(DateTime date, int monthsToAdd) {
  final monthIndex = date.month - 1 + monthsToAdd;
  final year = date.year + (monthIndex ~/ 12);
  var month = monthIndex % 12;
  if (month < 0) {
    month += 12;
  }
  final monthNumber = month + 1;
  final day = date.day.clamp(1, _daysInMonth(year, monthNumber));
  return DateTime(year, monthNumber, day);
}

int _daysInMonth(int year, int month) {
  final firstNextMonth = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  return firstNextMonth.subtract(const Duration(days: 1)).day;
}

int _totalCountForTimeframe(String timeframe, Map<String, int> countMap) {
  final today = _stripTime(DateTime.now());
  DateTime start;
  DateTime end = today;

  switch (timeframe) {
    case 'Weekly':
      start = today.subtract(const Duration(days: 6));
      break;
    case 'Monthly':
      start = _buildMonthlyRange().dates.first;
      break;
    case '6 Months':
      start = DateTime(today.year, today.month, 1);
      start = _shiftMonth(start, -5);
      break;
    case 'Yearly':
      start = DateTime(today.year, 1, 1);
      break;
    default:
      start = today.subtract(const Duration(days: 6));
  }

  return _sumCountOverRange(start, end, countMap);
}

int _sumCountOverRange(
  DateTime start,
  DateTime end,
  Map<String, int> countMap,
) {
  var current = _stripTime(start);
  final last = _stripTime(end);
  var total = 0;
  while (!current.isAfter(last)) {
    total += _lookupCount(current, countMap);
    current = current.add(const Duration(days: 1));
  }
  return total;
}

int _lookupCount(DateTime date, Map<String, int> countMap) {
  final key = date.toIso8601String().split('T').first;
  return countMap[key] ?? _countForDate(date);
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

class _InsightsGrid extends StatelessWidget {
  const _InsightsGrid();

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Column(
      children: [
        // Total Count Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Count',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.layers,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    '1,284',
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: 30,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '5.2%',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Accumulated since Monday',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Daily Avg and Peak Day Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Avg',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.equalizer,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '18.5',
                      style: AppTypography.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '2.1%',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Peak Day',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.event_available,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '42',
                      style: AppTypography.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.success, size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Oct 12',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final bool enabled;

  const _MilestoneItem({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = enabled
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.backgroundDark;
    final textColor = enabled ? AppColors.textPrimary : AppColors.textSecondary;
    final tileOpacity = enabled ? 1.0 : 0.6;

    return Opacity(
      opacity: tileOpacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                leadingIcon,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom navigation removed; use RootShell for shared navigation.
