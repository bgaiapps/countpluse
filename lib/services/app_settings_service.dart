import 'app_state.dart';

class AppSettingsService {
  static Future<void> init() async {
    countTargetNotifier.value = 'Radha';
    dailyGoalNotifier.value = 100;
    milestoneGoalNotifier.value = 1000;
  }

  static Future<void> setCountTarget(String value) async {
    final normalized = value.trim();
    countTargetNotifier.value = normalized;
  }

  static Future<void> setDailyGoal(int value) async {
    dailyGoalNotifier.value = value;
  }

  static Future<void> setMilestoneGoal(int value) async {
    milestoneGoalNotifier.value = value;
  }
}
