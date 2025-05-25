class Meal {
  final String name;
  final int calories;
  final String time;

  Meal({
    required this.name,
    required this.calories,
    this.time = '',
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        name: json['name'],
        calories: json['calories'],
        time: json['time'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'time': time,
      };
}