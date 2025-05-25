import 'package:intl/intl.dart';

class User {
  String name;
  DateTime birthdate;
  double weight;
  double height;
  String fitnessLabel;
  String gender;  // Added to support accurate BMR calculation
  int age;
  double calorieGoal;
  double waterGoal;
  List<String> recommendedExercises;
  String? profilePicturePath;

  User({
    required this.name,
    required this.birthdate,
    required this.weight,
    required this.height,
    required this.fitnessLabel,
    required this.gender,  // Required field for BMR calculation
    this.age = 0,
    this.calorieGoal = 2000.0,
    this.waterGoal = 2.0,
    this.recommendedExercises = const [],
    this.profilePicturePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthdate': birthdate.toIso8601String(),
        'weight': weight,
        'height': height,
        'fitnessLabel': fitnessLabel,
        'gender': gender,
        'age': age,
        'calorieGoal': calorieGoal,
        'waterGoal': waterGoal,
        'recommendedExercises': recommendedExercises,
        'profilePicturePath': profilePicturePath,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json['name'],
        birthdate: DateTime.parse(json['birthdate']),
        weight: json['weight'],
        height: json['height'],
        fitnessLabel: json['fitnessLabel'],
        gender: json['gender'] ?? 'Male',  // Default to Male if not present (for backward compatibility)
        age: json['age'],
        calorieGoal: json['calorieGoal'],
        waterGoal: json['waterGoal'],
        recommendedExercises: List<String>.from(json['recommendedExercises']),
        profilePicturePath: json['profilePicturePath'],
      );

  double getBMI() {
    if (height <= 0) return 0.0;  // Prevent division by zero
    return weight / ((height / 100) * (height / 100));
  }

  void calculateGoals() {
    // Input validation
    if (weight <= 0 || height <= 0) {
      throw Exception('Weight and height must be positive values');
    }

    // Calculate age based on current date (12:27 PM EAT, May 21, 2025)
    age = DateTime.now().year - birthdate.year;
    if (DateTime.now().month < birthdate.month ||
        (DateTime.now().month == birthdate.month && DateTime.now().day < birthdate.day)) {
      age--;
    }

    // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;  // Adjusted for females
    }

    // Adjust calorie goal based on fitness level
    if (fitnessLabel == 'Athlete') {
      calorieGoal = bmr * 1.5;  // Higher multiplier for athletes
    } else if (fitnessLabel == 'Intermediate') {
      calorieGoal = bmr * 1.3;  // Moderate multiplier for intermediate
    } else {
      calorieGoal = bmr * 1.0;  // Baseline for beginners
    }

    // Adjust water goal based on fitness level
    if (fitnessLabel == 'Athlete') {
      waterGoal = weight * 0.04 + 0.5;
    } else if (fitnessLabel == 'Intermediate') {
      waterGoal = weight * 0.035 + 0.3;
    } else {
      waterGoal = weight * 0.03;
    }

    // Recommend exercises based on fitness level
    if (fitnessLabel == 'Beginner') {
      recommendedExercises = ['Yoga', 'Morning Jog'];
    } else if (fitnessLabel == 'Intermediate') {
      recommendedExercises = ['Eskista Dance', 'Bodyweight Circuit'];
    } else {
      recommendedExercises = ['Eskista Dance', 'Traditional Wrestling'];
    }
  }
}