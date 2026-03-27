class EventModel {
  final int id;
  final int eraId;
  final String title;
  final int year;
  final String description;
  final String imageUrl;
  final String? date; // ✅ thêm để hiển thị ngày hoặc niên đại

  EventModel({
    required this.id,
    required this.eraId,
    required this.title,
    required this.year,
    required this.description,
    required this.imageUrl,
    this.date,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      eraId: json['eraId'] ?? 0,
      title: json['title'] ?? '',
      year: json['year'] ?? 0,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eraId': eraId,
    'title': title,
    'year': year,
    'description': description,
    'imageUrl': imageUrl,
    'date': date,
  };
}
