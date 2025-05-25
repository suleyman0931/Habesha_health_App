class Activity {
  final String title;
  final String time;
  final String description;
  final String duration;
  final String calories;
  final String bpm;
  final DateTime date;
  final DateTime? startTime;
  final String status;
  final int elapsedMilliseconds;
  final int? steps;

  Activity({
    required this.title,
    required this.time,
    required this.description,
    required this.duration,
    required this.calories,
    required this.bpm,
    required this.date,
    this.startTime,
    this.status = 'Not Started',
    this.elapsedMilliseconds = 0,
    this.steps,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time,
    'description': description,
    'duration': duration,
    'calories': calories,
    'bpm': bpm,
    'date': date.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'status': status,
    'elapsedMilliseconds': elapsedMilliseconds,
    'steps': steps,
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    title: json['title'],
    time: json['time'],
    description: json['description'],
    duration: json['duration'],
    calories: json['calories'],
    bpm: json['bpm'],
    date: DateTime.parse(json['date']),
    startTime:
        json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    status: json['status'] ?? 'Not Started',
    elapsedMilliseconds: json['elapsedMilliseconds'] ?? 0,
    steps: json['steps'],
  );
}
