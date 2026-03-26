import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  static const int _maxCount = 9999;
  static const int _countsPerMala = 108;
  static const List<double> _burstLanes = [-0.24, -0.12, 0.0, 0.12, 0.24];
  static const Duration _burstLifetime = Duration(milliseconds: 980);
  static const Duration _voiceSessionDuration = Duration(seconds: 60);
  static const Duration _voicePauseDuration = Duration(seconds: 8);

  int _count = 0;
  int _nextBurstId = 0;
  int _ringPulseSeed = 0;
  final List<_TapWordBurst> _tapWordBursts = [];
  bool _goalReached = false;
  late final AnimationController _overlayController;
  OverlayEntry? _goalOverlayEntry;
  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechReady = false;
  int _highestSessionMatchCount = 0;
  String _voiceStatus = 'idle';
  String? _selectedLocaleId;
  List<String> _availableLocaleIds = const [];
  String _lastProcessedTranscript = '';
  DateTime? _voiceSessionStartedAt;
  Timer? _voiceRetryTimer;
  Timer? _voiceStartTimeoutTimer;
  bool _didRetryWithoutLocale = false;
  bool _voiceSessionHadResult = false;
  double _voiceSessionPeakLevel = -2.0;
  int _voiceSessionIndex = 0;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _speech = stt.SpeechToText();
    dailyGoalNotifier.addListener(_onDailyGoalChanged);
    _loadTodayCount();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
      debugLogging: kDebugMode,
    );
    _speechReady = available;
    _voiceLog('initialize available=$available');
    if (!available) {
      if (!mounted) return;
      setState(() => _voiceStatus = 'speech unavailable');
      return;
    }
    await _selectBestLocale();
    _voiceLog(
      'locale selected=${_selectedLocaleId ?? 'device-default'} availableLocales=${_availableLocaleIds.length}',
    );
    if (!mounted) return;
    setState(() {
      _voiceStatus = _selectedLocaleId == null
          ? 'ready'
          : 'ready (${_selectedLocaleId!.replaceAll('_', '-')})';
    });
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
    _voiceRetryTimer?.cancel();
    _voiceStartTimeoutTimer?.cancel();
    dailyGoalNotifier.removeListener(_onDailyGoalChanged);
    _overlayController.dispose();
    _removeGoalOverlay();
    _speech.stop();
    super.dispose();
  }

  void _increment() {
    _ringPulseSeed++;
    _addCount(1);
    _spawnTapWordBurst();
  }

  void _spawnTapWordBurst() {
    final lane = _burstLanes[_nextBurstId % _burstLanes.length];
    final burst = _TapWordBurst(
      id: _nextBurstId++,
      word: countTargetNotifier.value.trim().toLowerCase(),
      lane: lane,
    );
    setState(() => _tapWordBursts.add(burst));

    Future.delayed(_burstLifetime, () {
      if (!mounted) return;
      setState(() {
        _tapWordBursts.removeWhere((item) => item.id == burst.id);
      });
    });
  }

  void _addCount(int delta) {
    if (delta <= 0) return;
    setState(() {
      _count = (_count + delta).clamp(0, _maxCount);
    });
    CountsService.setCountForDate(DateTime.now(), _count);

    if (!_goalReached && _count >= dailyGoalNotifier.value) {
      _goalReached = true;
      _showGoalOverlay();
    }
  }

  Future<void> _toggleVoiceCounting() async {
    if (_isListening) {
      _voiceRetryTimer?.cancel();
      _voiceStartTimeoutTimer?.cancel();
      await _speech.stop();
      _voiceLog('toggle off');
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceStatus = 'stopped';
      });
      return;
    }

    if (!_speechReady) {
      await _initSpeech();
    }
    if (_speechReady) {
      await _selectBestLocale();
    }
    final hasPermission = await _speech.hasPermission;
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for Count as you speak'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isListening = true);
    _voiceSessionIndex = 0;
    _highestSessionMatchCount = 0;
    _lastProcessedTranscript = '';
    _voiceSessionStartedAt = null;
    _didRetryWithoutLocale = false;
    _voiceSessionHadResult = false;
    _voiceSessionPeakLevel = -2.0;
    _voiceStatus = 'starting';
    _voiceLog(
      'toggle on locale=${_selectedLocaleId ?? 'device-default'} permission=$hasPermission',
    );
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_isListening || !_speechReady) return;
    _voiceRetryTimer?.cancel();
    _voiceStartTimeoutTimer?.cancel();

    if (_speech.isListening) {
      await _speech.cancel();
    }

    // Reset session-specific transcript state so repeated single-word
    // utterances in a new session are counted again.
    _lastProcessedTranscript = '';
    _highestSessionMatchCount = 0;

    if (mounted) {
      setState(() {
        _voiceStatus = _selectedLocaleId == null
            ? 'starting'
            : 'starting (${_selectedLocaleId!.replaceAll('_', '-')})';
      });
    }

    _voiceSessionIndex++;
    _voiceSessionStartedAt = DateTime.now();
    _voiceSessionHadResult = false;
    _voiceSessionPeakLevel = -2.0;

    _voiceLog(
      'session $_voiceSessionIndex start locale=${_selectedLocaleId ?? 'device-default'}',
    );

    _voiceStartTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isListening || _speech.isListening) return;
      setState(() {
        _voiceStatus = 'start timeout';
      });
      _voiceLog('session $_voiceSessionIndex start timeout');
    });

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelChange,
        localeId: _selectedLocaleId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          autoPunctuation: false,
          cancelOnError: false,
        ),
        listenFor: _voiceSessionDuration,
        pauseFor: _voicePauseDuration,
      );
    } catch (error) {
      _voiceStartTimeoutTimer?.cancel();
      _voiceLog('session $_voiceSessionIndex start exception=$error');
      if (_selectedLocaleId != null && !_didRetryWithoutLocale) {
        _didRetryWithoutLocale = true;
        _selectedLocaleId = null;
        await _startListening();
        return;
      }
      if (!mounted) return;
      setState(() {
        _voiceStatus = 'start failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech start failed: $error')),
      );
    }
  }

  void _onSpeechStatus(String status) {
    if (!_isListening) return;
    final normalized = status.toLowerCase();
    _voiceLog('session $_voiceSessionIndex status=$normalized');
    if (normalized == 'listening') {
      _voiceStartTimeoutTimer?.cancel();
    }
    if (normalized == 'done' ||
        normalized == 'notlistening' ||
        normalized == 'donenoresult') {
      _voiceRetryTimer?.cancel();
      _voiceStartTimeoutTimer?.cancel();
      _finalizeVoiceSession(
        DateTime.now(),
        fromNoMatch: normalized == 'donenoresult',
      );
      if (mounted) {
        setState(() {
          _isListening = false;
          _voiceStatus = normalized == 'donenoresult'
              ? 'did not hear the word'
              : 'tap mic to listen again';
        });
      } else {
        _isListening = false;
      }
      return;
    }
    if (mounted) {
      setState(() {
        _voiceStatus = status;
      });
    }
  }

  void _onSpeechError(dynamic error) {
    if (!_isListening) return;
    _voiceStartTimeoutTimer?.cancel();
    final message = _extractSpeechErrorMessage(error);
    final permanent = _isPermanentSpeechError(error);
    final noMatch = _isNoMatchSpeechError(error);
    final missingLocalePack = _isMissingLocalePackError(error);
    _voiceLog(
      'session $_voiceSessionIndex error="$message" permanent=$permanent noMatch=$noMatch missingLocalePack=$missingLocalePack peak=${_voiceSessionPeakLevel.toStringAsFixed(2)}',
    );
    _finalizeVoiceSession(DateTime.now(), fromNoMatch: noMatch);
    if (missingLocalePack) {
      final fallbackLocale = _fallbackLocaleForMissingPack();
      if (fallbackLocale != null && fallbackLocale != _selectedLocaleId) {
        _selectedLocaleId = fallbackLocale;
        if (mounted) {
          setState(() {
            _voiceStatus =
                'switching locale to ${fallbackLocale.replaceAll('_', '-')}';
          });
        }
        _voiceRetryTimer?.cancel();
        _voiceRetryTimer = Timer(const Duration(milliseconds: 520), () {
          if (!mounted || !_isListening) return;
          _startListening();
        });
        return;
      }
    }
    if (mounted) {
      setState(() {
        _voiceStatus = noMatch
            ? 'did not hear the word'
            : _friendlyVoiceErrorStatus(message);
      });
    }
    if (permanent) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _voiceStatus = 'speech unavailable';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: $message')),
        );
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isListening = false;
        _voiceStatus = noMatch ? 'did not hear the word' : 'tap mic to listen again';
      });
    } else {
      _isListening = false;
    }
  }

  String _friendlyVoiceErrorStatus(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('speech error') ||
        normalized.contains('error_client') ||
        normalized.contains('error 7') ||
        normalized.contains('no match') ||
        normalized.contains('no speech')) {
      return 'listening again';
    }
    if (normalized.contains('language pack')) {
      return 'switching voice language';
    }
    return 'listening again';
  }

  void _onSoundLevelChange(double level) {
    if (!mounted || !_isListening) return;
    if (level > _voiceSessionPeakLevel) {
      _voiceSessionPeakLevel = level;
    }
    if (level > 0 && _voiceStatus.toLowerCase().contains('starting')) {
      setState(() {
        _voiceStatus = 'hearing audio';
      });
    }
  }

  Future<void> _selectBestLocale() async {
    try {
      final locales = await _speech.locales();
      final systemLocale = await _speech.systemLocale();
      final localeIds = locales.map((locale) => locale.localeId).toList();
      _availableLocaleIds = localeIds;
      final systemLocaleId = systemLocale?.localeId;
      final normalizedSystemLocale = systemLocaleId?.toLowerCase();
      final prefersDevanagariLocale = _looksDevanagari(countTargetNotifier.value);

      if (prefersDevanagariLocale) {
        for (final localeId in const ['hi_IN', 'mr_IN']) {
          if (localeIds.contains(localeId)) {
            _selectedLocaleId = localeId;
            return;
          }
        }
      }

      if (systemLocaleId != null && localeIds.contains(systemLocaleId)) {
        _selectedLocaleId = systemLocaleId;
        return;
      }

      const preferredLocales = [
        'en_IN',
        'en_US',
        'en_GB',
        'hi_IN',
        'mr_IN',
        'gu_IN',
        'ta_IN',
        'te_IN',
        'kn_IN',
        'ml_IN',
      ];
      final shouldPreferIndianLocale =
          normalizedSystemLocale != null &&
          (normalizedSystemLocale.endsWith('_in') ||
              normalizedSystemLocale.endsWith('-in') ||
              normalizedSystemLocale.startsWith('hi') ||
              normalizedSystemLocale.startsWith('mr') ||
              normalizedSystemLocale.startsWith('gu') ||
              normalizedSystemLocale.startsWith('ta') ||
              normalizedSystemLocale.startsWith('te') ||
              normalizedSystemLocale.startsWith('kn') ||
              normalizedSystemLocale.startsWith('ml'));

      if (shouldPreferIndianLocale) {
        for (final localeId in preferredLocales) {
          if (localeIds.contains(localeId)) {
            _selectedLocaleId = localeId;
            break;
          }
        }
      }
      if (_selectedLocaleId == null && localeIds.isNotEmpty) {
        _selectedLocaleId = localeIds.first;
      }
    } catch (_) {
      _availableLocaleIds = const [];
      _selectedLocaleId = null;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = _normalizeSpeechText(result.recognizedWords);
    if (transcript.isEmpty) return;

    _voiceLog(
      'session $_voiceSessionIndex result final=${result.finalResult} transcript="$transcript"',
    );

    if (transcript == _lastProcessedTranscript) return;
    _lastProcessedTranscript = transcript;
    _voiceSessionHadResult = true;

    _applyVoiceCount(transcript);
  }

  void _applyVoiceCount(String transcript) {
    final aliases = _targetAliases(countTargetNotifier.value);
    if (aliases.isEmpty || transcript.isEmpty) return;

    var currentMatchCount = 0;
    for (final alias in aliases) {
      currentMatchCount = math.max(
        currentMatchCount,
        _countTargetMatches(transcript, alias),
      );
    }
    final delta = currentMatchCount - _highestSessionMatchCount;

    if (delta > 0) {
      _addCount(delta);
      _highestSessionMatchCount = currentMatchCount;
      return;
    }

    if (currentMatchCount > _highestSessionMatchCount) {
      _highestSessionMatchCount = currentMatchCount;
    }
  }

  String _normalizeSpeechText(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(
      RegExp(r'[^a-z0-9\u0900-\u097f\s]+'),
      ' ',
    );
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksDevanagari(String input) {
    return RegExp(r'[\u0900-\u097f]').hasMatch(input);
  }

  Set<String> _targetAliases(String target) {
    final normalizedTarget = _normalizeSpeechText(target);
    if (normalizedTarget.isEmpty) return const {};

    final aliases = <String>{normalizedTarget};
    final compactTarget = normalizedTarget.replaceAll(' ', '');
    final devotionalAliases = <String, Set<String>>{
      'radha': {'radha', 'radhe', 'radhey', 'raadha', 'raatha', 'राधा', 'राधे'},
      'ram': {'ram', 'raam', 'rama', 'raama', 'राम'},
      'shiv': {'shiv', 'shiva', 'siva', 'शिव'},
      'krishna': {
        'krishna',
        'krushna',
        'krisna',
        'kishan',
        'kishna',
        'कृष्ण',
        'कृष्णा',
      },
    };

    for (final entry in devotionalAliases.entries) {
      if (entry.value.contains(normalizedTarget) || entry.value.contains(compactTarget)) {
        aliases.addAll(entry.value.map(_normalizeSpeechText).where((value) => value.isNotEmpty));
      }
    }

    return aliases;
  }

  int _countTargetMatches(String transcript, String target) {
    final transcriptTokens = transcript.split(' ');
    final targetTokens = target.split(' ');
    if (transcriptTokens.isEmpty || targetTokens.isEmpty) return 0;

    var count = 0;
    for (var i = 0; i <= transcriptTokens.length - targetTokens.length; i++) {
      var matched = true;
      for (var j = 0; j < targetTokens.length; j++) {
        if (transcriptTokens[i + j] != targetTokens[j]) {
          matched = false;
          break;
        }
      }
      if (matched) count++;
    }
    if (count > 0) return count;

    if (_countLooselyMatchedTokens(transcriptTokens, targetTokens)) {
      return 1;
    }

    final compactTranscript = transcript.replaceAll(' ', '');
    final compactTarget = target.replaceAll(' ', '');
    if (compactTarget.isNotEmpty && compactTranscript.contains(compactTarget)) {
      return 1;
    }

    return 0;
  }

  String _extractSpeechErrorMessage(dynamic error) {
    final text = error.toString();
    final match = RegExp(r'errorMsg: ([^,}]+)').firstMatch(text);
    return match?.group(1)?.trim() ?? 'speech error';
  }

  bool _isPermanentSpeechError(dynamic error) {
    final text = error.toString().toLowerCase();
    return text.contains('error_insufficient_permissions');
  }

  bool _isNoMatchSpeechError(dynamic error) {
    final text = error.toString().toLowerCase();
    return text.contains('error_no_match') || text.contains('error 7');
  }

  bool _isMissingLocalePackError(dynamic error) {
    final text = error.toString().toLowerCase();
    return text.contains('language pack') ||
        text.contains('error_language_unavailable') ||
        text.contains('error 12');
  }

  String? _fallbackLocaleForMissingPack() {
    if (_availableLocaleIds.isEmpty) return null;
    const fallbackOrder = [
      'en_US',
      'en_GB',
      'hi_IN',
      'en',
    ];
    for (final localeId in fallbackOrder) {
      if (_availableLocaleIds.contains(localeId)) {
        return localeId;
      }
    }
    for (final localeId in _availableLocaleIds) {
      if (localeId.toLowerCase().startsWith('en')) {
        return localeId;
      }
    }
    return _availableLocaleIds.first;
  }

  bool _countLooselyMatchedTokens(
    List<String> transcriptTokens,
    List<String> targetTokens,
  ) {
    if (transcriptTokens.length < targetTokens.length) return false;
    for (var i = 0; i <= transcriptTokens.length - targetTokens.length; i++) {
      var matched = true;
      for (var j = 0; j < targetTokens.length; j++) {
        if (!_looselyMatchesWord(
          transcriptTokens[i + j],
          targetTokens[j],
        )) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  bool _looselyMatchesWord(String heard, String target) {
    if (heard == target) return true;
    final normalizedHeard = _normalizePhoneticWord(heard);
    final normalizedTarget = _normalizePhoneticWord(target);
    if (normalizedHeard == normalizedTarget) return true;
    if (normalizedHeard.length >= 3 &&
        normalizedTarget.length >= 3 &&
        (normalizedHeard.startsWith(normalizedTarget.substring(0, 3)) ||
            normalizedTarget.startsWith(normalizedHeard.substring(0, 3)))) {
      return true;
    }
    final maxDistance = normalizedTarget.length <= 5 ? 1 : 2;
    return _editDistance(normalizedHeard, normalizedTarget) <= maxDistance;
  }

  String _normalizePhoneticWord(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll(RegExp(r'[aeiou]+'), 'a')
        .replaceAll(RegExp(r'h+'), '')
        .replaceAll(RegExp(r'w+'), 'v')
        .replaceAll(RegExp(r'[^a-z0-9\u0900-\u097f]+'), '')
        .trim();
  }

  int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }

  void _finalizeVoiceSession(DateTime now, {required bool fromNoMatch}) {
    final sessionPeakLevel = _voiceSessionPeakLevel;
    final sessionStartedAt = _voiceSessionStartedAt;
    final longEnough = sessionStartedAt != null &&
        now.difference(sessionStartedAt) >= const Duration(milliseconds: 900);
    _voiceLog(
      'session $_voiceSessionIndex finalize fromNoMatch=$fromNoMatch peak=${sessionPeakLevel.toStringAsFixed(2)} longEnough=$longEnough hadResult=$_voiceSessionHadResult',
    );
    if (_voiceSessionHadResult || !fromNoMatch || !longEnough) return;
    if (mounted) {
      setState(() {
        _voiceStatus = 'did not hear the word';
      });
    }
  }

  void _voiceLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[voice] $message');
  }

  Future<void> _confirmReset() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Today\'s Count?'),
          content: const Text(
            'You will lose the count for the whole current day.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      _reset();
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
      if (!mounted) return;
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
    final circleSize = size.width * 0.86;
    final innerCircleSize = circleSize * 0.88;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _formatDate(),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
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
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey(_ringPulseSeed),
                                  tween: Tween(begin: 1.0, end: 0.0),
                                  duration: const Duration(milliseconds: 520),
                                  curve: Curves.easeOutQuart,
                                  builder: (context, pulse, _) {
                                    return CustomPaint(
                                      painter: _CirclePainter(
                                        progress: percent,
                                        color: AppColors.primary,
                                        pulse: pulse,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              ValueListenableBuilder<String?>(
                                valueListenable: wallpaperPathNotifier,
                                builder: (context, wallpaperPath, _) {
                                  final wallpaperFile = wallpaperPath == null
                                      ? null
                                      : File(wallpaperPath);
                                  final hasWallpaper =
                                      wallpaperPath != null &&
                                      wallpaperPath.isNotEmpty &&
                                      wallpaperFile != null &&
                                      wallpaperFile.existsSync();
                                  return ClipOval(
                                    child: Container(
                                      width: innerCircleSize,
                                      height: innerCircleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                        image: hasWallpaper
                                            ? DecorationImage(
                                                image: FileImage(wallpaperFile),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: hasWallpaper
                                          ? ColoredBox(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                width: innerCircleSize,
                                height: innerCircleSize,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_count',
                                      style: AppTypography.displayLarge.copyWith(
                                        fontSize: 72,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ValueListenableBuilder<String>(
                                      valueListenable: countTargetNotifier,
                                      builder: (context, label, _) => Text(
                                        label.toLowerCase(),
                                        style: AppTypography.labelLarge.copyWith(
                                          fontSize: 22,
                                          letterSpacing: 4,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IgnorePointer(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: _tapWordBursts
                                      .map(
                                        (burst) => _TapWordBurstWidget(
                                          key: ValueKey(burst.id),
                                          burst: burst,
                                          circleSize: circleSize,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                      const SizedBox(height: 20),
                      Text(
                        'Counts: $_count  •  Malas: ${_count ~/ _countsPerMala}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GestureDetector(
                          onTap: _toggleVoiceCounting,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                color: _isListening
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Count as you speak',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cardBackground,
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 1,
                            ),
                            onPressed: _confirmReset,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapWordBurst {
  final int id;
  final String word;
  final double lane;

  const _TapWordBurst({
    required this.id,
    required this.word,
    required this.lane,
  });
}

class _TapWordBurstWidget extends StatelessWidget {
  final _TapWordBurst burst;
  final double circleSize;

  const _TapWordBurstWidget({
    super.key,
    required this.burst,
    required this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final xOffset = burst.lane * circleSize;
        final yOffset = circleSize * 0.14 - (t * circleSize * 0.64);
        final opacity = t < 0.12
            ? t / 0.12
            : (t < 0.74 ? 1.0 : (1 - (t - 0.74) / 0.26).clamp(0.0, 1.0));
        final scale = 0.96 + (0.08 * (1 - t));
        return Transform.translate(
          offset: Offset(xOffset, yOffset),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Text(
                burst.word,
                style: AppTypography.displaySmall.copyWith(
                  fontSize: 34,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double pulse;

  _CirclePainter({
    required this.progress,
    required this.color,
    this.pulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    const pi = math.pi;

    final bgPaint = Paint()
      ..color = AppColors.cardBackground.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    final progPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.85),
          color,
          color.withValues(alpha: 0.55),
        ],
        stops: const [0.00, 0.45, 0.78, 1.00],
        transform: const GradientRotation(-pi / 2),
      ).createShader(circleRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * pi * progress;
    final start = -pi / 2;
    canvas.drawArc(circleRect, start, sweep, false, progPaint);

    final endAngle = start + sweep;
    final head = Offset(
      center.dx + (math.cos(endAngle) * radius),
      center.dy + (math.sin(endAngle) * radius),
    );
    final headGlow = Paint()
      ..color = color.withValues(alpha: 0.35 + (0.35 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(head, 6 + (4 * pulse), headGlow);

    if (pulse > 0) {
      final ripplePaint = Paint()
        ..color = color.withValues(alpha: 0.35 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawCircle(center, radius + 8 + ((1 - pulse) * 18), ripplePaint);

      final pulseArcPaint = Paint()
        ..color = color.withValues(alpha: 0.22 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(circleRect, start, sweep, false, pulseArcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.pulse != pulse;
}
