import 'package:flutter/material.dart';
// Bottom navigation is provided by RootShell; no direct screen imports needed here.
import '../services/app_state.dart';
import '../services/counts_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _count = 42;
  bool _goalReached = false;
  late final AnimationController _overlayController;
  OverlayEntry? _goalOverlayEntry;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    dailyGoalNotifier.addListener(_onDailyGoalChanged);
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    final count = CountsService.getCountForDate(DateTime.now());
    if (!mounted) return;
    setState(() => _count = count);
  }

  void _onDailyGoalChanged() {
    if (_goalReached && _count < dailyGoalNotifier.value) {
      setState(() {
        _goalReached = false;
      });
    }
  }

  @override
  void dispose() {
    dailyGoalNotifier.removeListener(_onDailyGoalChanged);
    _overlayController.dispose();
    _removeGoalOverlay();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _count++;
      if (_count > 9999) _count = 9999;
    });
    CountsService.setCountForDate(DateTime.now(), _count);

    if (!_goalReached && _count >= dailyGoalNotifier.value) {
      _goalReached = true;
      _showGoalOverlay();
    }
  }

  void _reset() {
    setState(() {
      _count = 0;
      _goalReached = false;
    });
    CountsService.resetCountForDate(DateTime.now());
  }

  void _showGoalOverlay() {
    if (_goalOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _goalOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Center(
              child: FadeTransition(
                opacity: _overlayController.drive(Tween(begin: 0.0, end: 1.0)),
                child: _buildGoalPopup(),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_goalOverlayEntry!);
    _overlayController.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await _overlayController.reverse();
      _removeGoalOverlay();
    });
  }

  void _removeGoalOverlay() {
    try {
      _goalOverlayEntry?.remove();
    } catch (_) {}
    _goalOverlayEntry = null;
  }

  Widget _buildGoalPopup() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarker.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Daily goal successfully completed',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    final wd = weekdays[now.weekday - 1];
    final mo = months[now.month - 1];
    return '$wd, $mo ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatDate(),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<int>(
                        valueListenable: dailyGoalNotifier,
                        builder: (context, dailyGoal, _) => Text(
                          'Daily Goal: $dailyGoal',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: dailyGoalNotifier,
                      builder: (context, dailyGoal, _) {
                        final percent = (_count / dailyGoal).clamp(0.0, 1.0);
                        return GestureDetector(
                          onTap: _increment,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: circleSize,
                                height: circleSize,
                                child: CustomPaint(
                                  painter: _CirclePainter(
                                    progress: percent,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Container(
                                width: circleSize * 0.84,
                                height: circleSize * 0.84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_count',
                                      style: AppTypography.displayLarge
                                          .copyWith(
                                            fontSize: 72,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Use the global count target (e.g. Radha, Ram)
                                    ValueListenableBuilder<String>(
                                      valueListenable: countTargetNotifier,
                                      builder: (context, label, _) => Text(
                                        label.toUpperCase(),
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              letterSpacing: 4,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ValueListenableBuilder<String>(
                        valueListenable: countTargetNotifier,
                        builder: (context, value, _) {
                          return Text(
                            'Tap anywhere on the circle to count, $value',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cardBackground,
                                foregroundColor: AppColors.textPrimary,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _reset,
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('End Session'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation moved to RootShell
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = AppColors.cardBackground.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * 3.141592653589793 * progress;
    final start = -3.141592653589793 / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// Navigation item removed — RootShell provides shared navigation UI.
