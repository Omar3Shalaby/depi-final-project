class Meal {
  final String id;
  final String name;
  final String time;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String icon;
  final bool checked;
  final String? date;

  Meal({
    required this.id,
    required this.name,
    required this.time,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.icon,
    this.checked = false,
    this.date,
  });

  // Convert from JSON (Map) to Model
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown Meal',
      time: json['time'] ?? '12:00 PM',
      kcal: (json['kcal'] ?? 0) is String
          ? int.tryParse(
                  json['kcal'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0
          : json['kcal'] as int,
      protein: (json['protein'] ?? 0) is String
          ? int.tryParse(
                  json['protein'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0
          : json['protein'] as int,
      carbs: (json['carbs'] ?? 0) is String
          ? int.tryParse(
                  json['carbs'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0
          : json['carbs'] as int,
      fat: (json['fat'] ?? 0) is String
          ? int.tryParse(
                  json['fat'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0
          : json['fat'] as int,
      icon: json['icon'] ?? 'default',
      checked: json['checked'] ?? false,
      date: json['date'],
    );
  }

  // Convert from Model to JSON (Map) for Storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'time': time,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'icon': icon,
    'checked': checked,
    if (date != null) 'date': date,
  };
}
