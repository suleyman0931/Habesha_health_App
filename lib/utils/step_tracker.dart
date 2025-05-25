import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTracker {
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static int _steps = 0;
  static DateTime? _lastResetDate;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastReset = prefs.getString('last_reset_date');
    _lastResetDate = lastReset != null ? DateTime.parse(lastReset) : today;

    if (_lastResetDate!.day != today.day || _lastResetDate!.month != today.month || _lastResetDate!.year != today.year) {
      await prefs.setInt('steps_${_lastResetDate!.toIso8601String().substring(0, 10)}', _steps);
      _steps = 0;
      _lastResetDate = today;
      await prefs.setString('last_reset_date', today.toIso8601String());
    } else {
      _steps = prefs.getInt('steps_${today.toIso8601String().substring(0, 10)}') ?? 0;
    }

    _stepCountSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        _steps = event.steps;
        _saveSteps();
      },
      onError: (error) {
        print('Step count error: $error');
      },
    );
  }

  static Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setInt('steps_${today.toIso8601String().substring(0, 10)}', _steps);
  }

  static Future<int> getSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    return prefs.getInt('steps_${today.toIso8601String().substring(0, 10)}') ?? 0;
  }

  static void dispose() {
    _stepCountSubscription?.cancel();
  }
}