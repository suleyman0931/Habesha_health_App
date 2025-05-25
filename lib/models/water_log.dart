class WaterLog {
  final DateTime date;
  final double amount;

  WaterLog({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
      };

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
        date: DateTime.parse(json['date']),
        amount: json['amount'],
      );
}