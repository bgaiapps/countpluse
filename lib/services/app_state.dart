import 'package:flutter/foundation.dart';

/// Global app state notifiers.
final ValueNotifier<String> countTargetNotifier = ValueNotifier<String>(
  'Radha',
);
final ValueNotifier<int> dailyGoalNotifier = ValueNotifier<int>(100);
final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> remindersNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> isGuestNotifier = ValueNotifier<bool>(true);
final ValueNotifier<String> userNameNotifier = ValueNotifier<String>('');
final ValueNotifier<String> userEmailNotifier = ValueNotifier<String>('');
final ValueNotifier<String> userPhoneNotifier = ValueNotifier<String>('');
