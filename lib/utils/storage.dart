import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';

class Storage {
  static Future<void> saveUser(User user) async {
    user.calculateGoals();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user');
    return userData != null ? User.fromJson(jsonDecode(userData)) : null;
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') ?? 'light';
  }

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localeCode = prefs.getString('locale');
    return Locale(localeCode ?? 'en', '');
  }

  static Future<void> saveActivity(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Activity> activities = await getActivities();

    // Find if an activity with the same title, time, and date already exists
    int existingIndex = activities.indexWhere(
      (a) =>
          a.title == activity.title &&
          a.time == activity.time &&
          a.date.isAtSameMomentAs(activity.date),
    );

    if (existingIndex != -1) {
      // Update existing activity
      activities[existingIndex] =
          activity; // Assuming the new activity object has the updated date if needed
    } else {
      // Add new activity with the provided date (or current date if not provided)
      activities.add(activity);
    }

    await prefs.setString(
      'activities',
      jsonEncode(activities.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<Activity>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesJson = prefs.getString('activities');
    if (activitiesJson == null) return [];
    return (jsonDecode(activitiesJson) as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

  static Future<List<Activity>> getTodayActivities() async {
    final List<Activity> activities = await getActivities();
    final List<Activity> plannedMeals = await getTodayPlannedMeals();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Combine regular activities and planned meals
    final allActivities = [
      ...activities.where((activity) {
        return activity.date.year == today.year &&
            activity.date.month == today.month &&
            activity.date.day == today.day;
      }),
      ...plannedMeals,
    ];

    // Sort by date (newest first)
    allActivities.sort((a, b) => b.date.compareTo(a.date));

    return allActivities;
  }

  static Future<Map<String, Map<String, dynamic>>> getWeeklyActivities() async {
    final List<Activity> activities = await getActivities();
    final List<Activity> plannedMeals = await getPlannedMeals();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final Map<String, Map<String, dynamic>> weeklyData = {};
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(day);
      weeklyData[dayName] = {
        'steps': 0,
        'water': 0.0,
        'calories': 0,
        'caloriesGained': 0,
      };
    }

    // Process regular activities
    for (var activity in activities) {
      if (activity.date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          activity.date.isBefore(endOfWeek.add(Duration(days: 1)))) {
        final dayName = DateFormat('EEEE').format(activity.date);
        if (weeklyData.containsKey(dayName)) {
          if (activity.title == 'Steps') {
            weeklyData[dayName]!['steps'] =
                activity.steps ??
                int.tryParse(activity.calories.replaceAll(' calories', '')) ??
                0;
          } else if (activity.title == 'Water Intake') {
            final waterAmount =
                double.tryParse(
                  activity.description
                      .replaceAll('Added ', '')
                      .replaceAll('ml of water', ''),
                ) ??
                0;
            weeklyData[dayName]!['water'] += waterAmount / 1000;
          } else if (activity.title.startsWith('Meal - ')) {
            // Track calories from meals
            final calories = int.tryParse(activity.calories) ?? 0;
            weeklyData[dayName]!['caloriesGained'] =
                (weeklyData[dayName]!['caloriesGained'] as int) + calories;
          } else if (activity.calories.isNotEmpty) {
            weeklyData[dayName]!['calories'] +=
                int.tryParse(activity.calories.replaceAll(' calories', '')) ??
                0;
          }
        }
      }
    }

    // Process planned meals
    for (var meal in plannedMeals) {
      if (meal.date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          meal.date.isBefore(endOfWeek.add(Duration(days: 1)))) {
        final dayName = DateFormat('EEEE').format(meal.date);
        if (weeklyData.containsKey(dayName)) {
          final calories = int.tryParse(meal.calories) ?? 0;
          weeklyData[dayName]!['caloriesGained'] =
              (weeklyData[dayName]!['caloriesGained'] as int) + calories;
        }
      }
    }

    return weeklyData;
  }

  static Future<void> saveTodayProgress(
    int steps,
    double waterIntake,
    int caloriesBurned,
    int caloriesGained,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Create a step activity
    final stepActivity = Activity(
      title: 'Steps',
      time: DateFormat('h:mm a').format(now),
      description: 'Daily steps',
      duration: '',
      calories: '$steps calories',
      bpm: '',
      date: now,
      steps: steps,
    );

    // Save the step activity
    await saveActivity(stepActivity);

    // Save the progress
    final progress = {
      'date': today,
      'steps': steps,
      'waterIntake': waterIntake,
      'caloriesBurned': caloriesBurned,
      'caloriesGained': caloriesGained,
    };
    await prefs.setString('today_progress', jsonEncode(progress));
  }

  static Future<Map<String, dynamic>?> getTodayProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progressJson = prefs.getString('today_progress');
    if (progressJson == null) return null;
    final progress = jsonDecode(progressJson);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (progress['date'] != today) return null;
    return progress;
  }

  static Future<void> savePlannedMeal(Activity meal) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Activity> plannedMeals = await getPlannedMeals();
    plannedMeals.add(meal);
    await prefs.setString(
      'planned_meals',
      jsonEncode(plannedMeals.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<Activity>> getPlannedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? plannedMealsJson = prefs.getString('planned_meals');
    if (plannedMealsJson == null) return [];
    return (jsonDecode(plannedMealsJson) as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

  static Future<List<Activity>> getTodayPlannedMeals() async {
    final List<Activity> plannedMeals = await getPlannedMeals();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    return plannedMeals.where((meal) {
      try {
        final mealTime = DateFormat('h:mm a').parse(meal.time);
        final mealDate = DateFormat('yyyy-MM-dd').format(mealTime);
        return mealDate == today;
      } catch (e) {
        print('Error parsing time for planned meal ${meal.title}: $e');
        return false;
      }
    }).toList();
  }

  // Added method to remove an activity
  static Future<void> removeActivity(Activity activityToRemove) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Activity> activities = await getActivities();
    activities.removeWhere(
      (activity) =>
          activity.title == activityToRemove.title &&
          activity.time == activityToRemove.time &&
          activity.date.isAtSameMomentAs(activityToRemove.date),
    );
    await prefs.setString(
      'activities',
      jsonEncode(activities.map((a) => a.toJson()).toList()),
    );
  }

  // Added method to save a meal (Activity is used for meals too)
  static Future<void> saveMeal(Activity meal) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Activity> meals = await getMeals();

    // Add meal with date from the meal object
    meals.add(meal);

    // Save to meals list
    await prefs.setString(
      'meals',
      jsonEncode(meals.map((m) => m.toJson()).toList()),
    );

    // Also save as an activity to show in today's activities
    await saveActivity(meal);

    // Update today's progress with the new meal's calories
    final progress = await getTodayProgress();
    if (progress != null) {
      final caloriesGained = progress['caloriesGained'] ?? 0;
      final calories = int.tryParse(meal.calories) ?? 0;
      await saveTodayProgress(
        progress['steps'] ?? 0,
        progress['waterIntake'] ?? 0.0,
        progress['caloriesBurned'] ?? 0,
        caloriesGained + calories,
      );
    }
  }

  // Added method to get all meals
  static Future<List<Activity>> getMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealsJson = prefs.getString('meals');
    if (mealsJson == null) return [];
    return (jsonDecode(mealsJson) as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

  // Added method to get today's meals
  static Future<List<Activity>> getTodayMeals() async {
    final List<Activity> meals = await getMeals();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return meals
        .where(
          (meal) =>
              meal.date.year == today.year &&
              meal.date.month == today.month &&
              meal.date.day == today.day,
        )
        .toList();
  }

  // Added method to remove a meal
  static Future<void> removeMeal(Activity mealToRemove) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Activity> meals = await getMeals();
    meals.removeWhere(
      (meal) =>
          meal.title == mealToRemove.title &&
          meal.time == mealToRemove.time &&
          meal.date.isAtSameMomentAs(mealToRemove.date),
    );
    await prefs.setString(
      'meals',
      jsonEncode(meals.map((m) => m.toJson()).toList()),
    );
  }

  static Future<List<Activity>> getDayActivities(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getStringList('activities') ?? [];
    final activities =
        activitiesJson.map((json) => Activity.fromJson(jsonDecode(json))).where(
          (activity) {
            final activityDate = activity.date;
            return activityDate.year == date.year &&
                activityDate.month == date.month &&
                activityDate.day == date.day;
          },
        ).toList();
    return activities;
  }
}
