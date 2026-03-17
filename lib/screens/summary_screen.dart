import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../services/counts_service.dart';
import '../services/app_state.dart';
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

DateTime Function() _nowProvider = DateTime.now;

void setSummaryNowProvider(DateTime Function() provider) {
  _nowProvider = provider;
}

void resetSummaryNowProvider() {
  _nowProvider = DateTime.now;
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    this.initialCounts,
    this.skipInitialLoad = false,
  });

  final Map<String, int>? initialCounts;
  final bool skipInitialLoad;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _timeframe = 'Weekly';
  Map<String, int> _countMap = {};
  bool _loadingCounts = false;
  String? _loadError;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    if (widget.initialCounts != null) {
      _countMap = Map<String, int>.from(widget.initialCounts!);
      _loadingCounts = false;
      _loadError = null;
      _lastLoadedAt = _nowProvider();
    }
    if (!widget.skipInitialLoad) {
      _loadCounts();
    }
    navIndexNotifier.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    navIndexNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (navIndexNotifier.value != 1) return;
    final now = DateTime.now();
    if (_loadingCounts) return;
    if (_lastLoadedAt == null ||
        now.difference(_lastLoadedAt!) > const Duration(seconds: 3)) {
      _loadCounts();
    }
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
        _lastLoadedAt = DateTime.now();
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
        backgroundColor: Colors.transparent,
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
      body: AppPageBackground(
        child: SafeArea(
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
                child: Text(
                  'Period Insights',
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _InsightsGrid(
                  timeframe: _timeframe,
                  countMap: _countMap,
                  isLoading: _loadingCounts,
                ),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Milestones',
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder<int>(
                  valueListenable: dailyGoalNotifier,
                  builder: (context, dailyGoal, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable: milestoneGoalNotifier,
                      builder: (context, milestoneGoal, _) {
                        final today = _stripTime(_nowProvider());
                        final todayCount = _loadingCounts
                            ? 0
                            : _lookupCount(today, _countMap);
                        final remainingDaily = (dailyGoal - todayCount).clamp(
                          0,
                          1 << 31,
                        );
                        final dailyAchieved = remainingDaily == 0;

                        final totalAllTime = _countMap.values.fold<int>(
                          0,
                          (sum, value) => sum + value,
                        );
                        final remainingMilestone =
                            (milestoneGoal - totalAllTime).clamp(0, 1 << 31);
                        final milestoneAchieved = remainingMilestone == 0;

                        final milestoneDate = _findMilestoneAchievedDate(
                          milestoneGoal,
                          _countMap,
                        );
                        final milestoneSubtitle = _loadingCounts
                            ? 'Loading...'
                            : milestoneAchieved
                            ? (milestoneDate == null
                                  ? 'Milestone achieved'
                                  : 'Milestone achieved ${_formatRelativeDay(milestoneDate)}')
                            : '${_formatCount(remainingMilestone)} counts remaining';
                        final dailySubtitle = _loadingCounts
                            ? 'Loading...'
                            : dailyAchieved
                            ? 'Achieved today'
                            : '${_formatCount(remainingDaily)} counts remaining';

                        return Column(
                          children: [
                            _MilestoneItem(
                              title:
                                  '${_formatCount(milestoneGoal)} Total Tally',
                              subtitle: milestoneSubtitle,
                              leadingIcon: Icons.workspace_premium,
                              enabled: milestoneAchieved,
                            ),
                            const SizedBox(height: 12),
                            _MilestoneItem(
                              title: '${_formatCount(dailyGoal)} Daily Goal',
                              subtitle: dailySubtitle,
                              leadingIcon: Icons.gps_fixed,
                              enabled: dailyAchieved,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
                  color: active ? AppColors.primaryDark : Colors.transparent,
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
                    color: active ? Colors.white : AppColors.textSecondary,
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
                    key: const Key('summary_total_count'),
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
    final rawMax = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final maxCount = _niceAxisMax(rawMax);
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelAreaHeight = timeframe == 'Monthly' ? 30.0 : 24.0;
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
                      final h = (counts[i] / maxCount).clamp(0.0, 1.0);
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
                                          softWrap: false,
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
                                                ? 10
                                                : timeframe == '6 Months'
                                                ? 11
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
                          _formatAxisLabel(maxCount),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatAxisLabel((maxCount / 2).round()),
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
                  SizedBox(height: labelAreaHeight),
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
          groupDividers: range.groupDividers,
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
  final end = _stripTime(_nowProvider());
  return List.generate(days, (i) {
    final offset = days - 1 - i;
    return end.subtract(Duration(days: offset));
  });
}

class _MonthlyRange {
  final List<DateTime> dates;
  final int highlightIndex;
  final List<int> groupDividers;

  const _MonthlyRange({
    required this.dates,
    required this.highlightIndex,
    required this.groupDividers,
  });
}

_MonthlyRange _buildMonthlyRange() {
  final end = _stripTime(_nowProvider());
  final start = end.subtract(const Duration(days: 27));
  const days = 28;
  final dates = List.generate(days, (i) => start.add(Duration(days: i)));
  final highlightIndex = dates.length - 1;
  final dividers = <int>[];
  for (var i = 7; i < dates.length; i += 7) {
    dividers.add(i);
  }
  return _MonthlyRange(
    dates: dates,
    highlightIndex: highlightIndex,
    groupDividers: dividers,
  );
}

List<int> _dailyCounts(List<DateTime> dates, Map<String, int> countMap) {
  final today = _stripTime(_nowProvider());
  return dates.map((date) {
    if (date.isAfter(today)) return 0;
    return _lookupCount(date, countMap);
  }).toList();
}

List<String> _labelsForWeekly(List<DateTime> dates) {
  return dates.map((date) => _weekdayShort[date.weekday - 1]).toList();
}

List<String> _labelsForMonthly(List<DateTime> dates) {
  return dates.map((date) {
    if (date.weekday != DateTime.sunday) return '';
    return '${date.day}-${_monthShort[date.month - 1]}';
  }).toList();
}

_ChartData _buildSixMonthBuckets(Map<String, int> countMap) {
  final today = _stripTime(_nowProvider());
  final counts = <int>[];
  final labels = <String>[];
  final endMonth = DateTime(today.year, today.month, 1);
  final startMonth = _shiftMonth(endMonth, -5);

  for (var i = 0; i < 6; i++) {
    final currentMonth = _shiftMonth(startMonth, i);
    counts.add(0);
    labels.add(_monthShort[currentMonth.month - 1]);
  }

  for (final entry in countMap.entries) {
    final parsed = _parseDateKey(entry.key);
    if (parsed == null) continue;
    final date = _stripTime(parsed);
    if (date.isBefore(startMonth) || date.isAfter(today)) continue;
    final monthIndex =
        (date.year - startMonth.year) * 12 + (date.month - startMonth.month);
    if (monthIndex >= 0 && monthIndex < counts.length) {
      counts[monthIndex] += entry.value;
    }
  }

  var total = counts.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) {
    var current = startMonth;
    while (!current.isAfter(today)) {
      final monthIndex =
          (current.year - startMonth.year) * 12 +
          (current.month - startMonth.month);
      if (monthIndex >= 0 && monthIndex < counts.length) {
        counts[monthIndex] += _lookupCount(current, countMap);
      }
      current = current.add(const Duration(days: 1));
    }
    total = counts.fold<int>(0, (sum, value) => sum + value);
  }

  return _ChartData(
    counts: counts,
    labels: labels,
    groupDividers: const [],
    drawBarDividers: true,
    highlightIndex: labels.length - 1,
  );
}

_ChartData _buildYearlyBuckets(Map<String, int> countMap) {
  final today = _stripTime(_nowProvider());
  final counts = <int>[];
  final labels = <String>[];
  final endMonth = DateTime(today.year, today.month, 1);
  final startMonth = _shiftMonth(endMonth, -11);

  for (var i = 0; i < 12; i++) {
    final currentMonth = _shiftMonth(startMonth, i);
    counts.add(0);
    labels.add(_monthShort[currentMonth.month - 1]);
  }

  for (final entry in countMap.entries) {
    final parsed = _parseDateKey(entry.key);
    if (parsed == null) continue;
    final date = _stripTime(parsed);
    if (date.isBefore(startMonth) || date.isAfter(today)) continue;
    final monthIndex =
        (date.year - startMonth.year) * 12 + (date.month - startMonth.month);
    if (monthIndex >= 0 && monthIndex < counts.length) {
      counts[monthIndex] += entry.value;
    }
  }

  var total = counts.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) {
    var current = startMonth;
    final endDate = DateTime(today.year, today.month, today.day);
    while (!current.isAfter(endDate)) {
      final monthIndex =
          (current.year - startMonth.year) * 12 +
          (current.month - startMonth.month);
      if (monthIndex >= 0 && monthIndex < counts.length) {
        counts[monthIndex] += _lookupCount(current, countMap);
      }
      current = current.add(const Duration(days: 1));
    }
  }

  return _ChartData(
    counts: counts,
    labels: labels,
    groupDividers: const [],
    drawBarDividers: true,
    highlightIndex: labels.length - 1,
  );
}

String _formatRangeForTimeframe(String timeframe) {
  final end = _stripTime(_nowProvider());
  DateTime start;
  switch (timeframe) {
    case 'Weekly':
      start = end.subtract(const Duration(days: 6));
      break;
    case 'Monthly':
      final range = _buildMonthlyRange();
      start = range.dates.first;
      final endRange = range.dates.last;
      if (start.year == endRange.year) {
        return '${_formatMonthDay(start)} – ${_formatMonthDayYear(endRange)}';
      }
      return '${_formatMonthDayYear(start)} – ${_formatMonthDayYear(endRange)}';
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
  final year = date.year + (monthIndex / 12).floor();
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
  switch (timeframe) {
    case '6 Months':
      return _sumBucketTotals(_buildSixMonthBuckets(countMap).counts);
    case 'Yearly':
      return _sumBucketTotals(_buildYearlyBuckets(countMap).counts);
    default:
      final range = _getTimeframeRange(timeframe);
      return _sumCountFromMap(range, countMap);
  }
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
  final key = _localDateKey(date);
  if (countMap.containsKey(key)) {
    return countMap[key] ?? 0;
  }
  return CountsService.getCountForDate(date);
}

String _localDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _TimeframeRange {
  final DateTime start;
  final DateTime end;

  const _TimeframeRange({required this.start, required this.end});
}

_TimeframeRange _getTimeframeRange(String timeframe) {
  final today = _stripTime(_nowProvider());
  DateTime start;
  final end = today;

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

  return _TimeframeRange(start: start, end: end);
}

_TimeframeRange _getPreviousTimeframeRange(String timeframe) {
  final current = _getTimeframeRange(timeframe);
  final start = _stripTime(current.start);
  final end = _stripTime(current.end);
  final days = end.difference(start).inDays + 1;
  final prevEnd = start.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(Duration(days: days - 1));
  return _TimeframeRange(start: prevStart, end: prevEnd);
}

DateTime? _findMilestoneAchievedDate(
  int milestoneGoal,
  Map<String, int> countMap,
) {
  if (milestoneGoal <= 0 || countMap.isEmpty) return null;
  final entries = <MapEntry<DateTime, int>>[];
  for (final entry in countMap.entries) {
    final parsed = _parseDateKey(entry.key);
    if (parsed == null) continue;
    entries.add(MapEntry(_stripTime(parsed), entry.value));
  }
  if (entries.isEmpty) return null;
  entries.sort((a, b) => a.key.compareTo(b.key));
  var total = 0;
  for (final entry in entries) {
    total += entry.value;
    if (total >= milestoneGoal) {
      return entry.key;
    }
  }
  return null;
}

String _formatRelativeDay(DateTime date) {
  final today = _stripTime(_nowProvider());
  final diff = date.difference(today).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff == -1) return 'yesterday';
  if (diff > 1) return 'in $diff days';
  return '${diff.abs()} days ago';
}

double _percentChange(double current, double previous) {
  if (previous <= 0) {
    return current == 0 ? 0 : 100;
  }
  return ((current - previous) / previous) * 100;
}

String _formatPercent(double value) {
  final safe = value.isNaN || value.isInfinite ? 0.0 : value.abs();
  return '${safe.round()}%';
}

String _formatDailyAverage(String timeframe, Map<String, int> countMap) {
  final range = _getTimeframeRange(timeframe);
  final total = _totalCountForTimeframe(timeframe, countMap);
  final days = range.end.difference(_stripTime(range.start)).inDays + 1;
  if (days <= 0) return '0.0';
  final avg = total / days;
  return avg.toStringAsFixed(1);
}

int _sumBucketTotals(List<int> counts) {
  var total = 0;
  for (final value in counts) {
    total += value;
  }
  return total;
}

class _PeakResult {
  final String countLabel;
  final String dateLabel;

  const _PeakResult({required this.countLabel, required this.dateLabel});

  factory _PeakResult.empty() =>
      const _PeakResult(countLabel: '0', dateLabel: 'No data');
}

_PeakResult _findPeakDay(String timeframe, Map<String, int> countMap) {
  final range = _getTimeframeRange(timeframe);
  var current = _stripTime(range.start);
  final end = _stripTime(range.end);
  var peakCount = -1;
  DateTime? peakDate;

  while (!current.isAfter(end)) {
    final count = _lookupCount(current, countMap);
    if (count > peakCount) {
      peakCount = count;
      peakDate = current;
    }
    current = current.add(const Duration(days: 1));
  }

  if (peakCount <= 0 || peakDate == null) {
    return _PeakResult.empty();
  }

  return _PeakResult(
    countLabel: _formatCount(peakCount),
    dateLabel: _formatMonthDay(peakDate),
  );
}

int _sumCountFromMap(_TimeframeRange range, Map<String, int> countMap) {
  if (countMap.isEmpty) {
    return _sumCountOverRange(range.start, range.end, countMap);
  }
  var total = 0;
  for (final entry in countMap.entries) {
    final parsed = _parseDateKey(entry.key);
    if (parsed == null) continue;
    final date = _stripTime(parsed);
    if (date.isBefore(range.start) || date.isAfter(range.end)) {
      continue;
    }
    total += entry.value;
  }
  if (total == 0) {
    return _sumCountOverRange(range.start, range.end, countMap);
  }
  return total;
}

DateTime? _parseDateKey(String value) {
  if (value.isEmpty) return null;
  final normalized = value.length >= 10 ? value.substring(0, 10) : value;
  return DateTime.tryParse(normalized);
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

int _niceAxisMax(int value) {
  if (value <= 0) return 1;
  if (value <= 10) return 10;
  if (value <= 50) return 50;
  if (value <= 100) return 100;
  if (value <= 500) return 500;
  if (value <= 1000) return 1000;
  if (value <= 5000) return 5000;
  if (value <= 10000) return 10000;
  final rounded = ((value + 999) ~/ 1000) * 1000;
  return rounded;
}

String _formatAxisLabel(int value) {
  if (value >= 1000) {
    final k = value / 1000;
    final text = k % 1 == 0 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    return '${text}k';
  }
  return _formatCount(value);
}

class _InsightsGrid extends StatelessWidget {
  final String timeframe;
  final Map<String, int> countMap;
  final bool isLoading;

  const _InsightsGrid({
    required this.timeframe,
    required this.countMap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final totalCount = isLoading
        ? '...'
        : _formatCount(_totalCountForTimeframe(timeframe, countMap));
    final rangeLabel = _formatRangeForTimeframe(timeframe);
    final dailyAvg = isLoading
        ? '...'
        : _formatDailyAverage(timeframe, countMap);
    final peak = isLoading
        ? _PeakResult.empty()
        : _findPeakDay(timeframe, countMap);
    final currentRange = _getTimeframeRange(timeframe);
    final previousRange = _getPreviousTimeframeRange(timeframe);
    final currentTotal = _totalCountForTimeframe(timeframe, countMap);
    final previousTotal = _sumCountFromMap(previousRange, countMap);
    final currentDays =
        currentRange.end.difference(_stripTime(currentRange.start)).inDays + 1;
    final previousDays =
        previousRange.end.difference(_stripTime(previousRange.start)).inDays +
        1;
    final currentDailyAvg = currentDays <= 0 ? 0.0 : currentTotal / currentDays;
    final previousDailyAvg = previousDays <= 0
        ? 0.0
        : previousTotal / previousDays;
    final totalChange = _percentChange(
      currentTotal.toDouble(),
      previousTotal.toDouble(),
    );
    final dailyChange = _percentChange(currentDailyAvg, previousDailyAvg);
    final totalTrendUp = totalChange >= 0;
    final dailyTrendUp = dailyChange >= 0;
    final totalDeltaLabel = isLoading ? '...' : _formatPercent(totalChange);
    final dailyDeltaLabel = isLoading ? '...' : _formatPercent(dailyChange);

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
                    totalCount,
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
                        totalTrendUp ? Icons.trending_up : Icons.trending_down,
                        color: totalTrendUp
                            ? AppColors.success
                            : AppColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        totalDeltaLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: totalTrendUp
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Accumulated for $rangeLabel',
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
                      dailyAvg,
                      style: AppTypography.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          dailyTrendUp
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: dailyTrendUp
                              ? AppColors.success
                              : AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          dailyDeltaLabel,
                          style: AppTypography.bodySmall.copyWith(
                            color: dailyTrendUp
                                ? AppColors.success
                                : AppColors.danger,
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
                      peak.countLabel,
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
                          peak.dateLabel,
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
