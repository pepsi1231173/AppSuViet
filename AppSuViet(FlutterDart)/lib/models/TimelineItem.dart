class TimelineItem {
  final int id;
  final String period;
  final String year;
  final String eventTitle;
  final String description;
  final String? details;
  final String? imageUrl;
  final String dynasty;

  TimelineItem({
    required this.id,
    required this.period,
    required this.year,
    required this.eventTitle,
    required this.description,
    required this.dynasty,
    this.details,
    this.imageUrl,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      id: json['id'] ?? 0,
      period: json['period'] ?? '',
      year: json['year'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      description: json['description'] ?? '',
      dynasty: json['dynasty'] ?? '',
      details: json['details'],
      imageUrl: json['imageUrl'],
    );
  }


  // ⭐ COPY từ Festival
  String? getFullImageUrl(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return '$baseUrl/${imageUrl!}';
  }
}
