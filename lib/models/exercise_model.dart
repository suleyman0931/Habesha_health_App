class Exercise {
  final String name;
  final int calories;
  final int duration;
  final String type;

  Exercise({required this.name, required this.calories, required this.duration, required this.type});

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'],
        calories: json['calories'],
        duration: json['duration'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'duration': duration,
        'type': type,
      };
}