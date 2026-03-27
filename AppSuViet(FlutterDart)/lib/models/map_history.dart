class MapHistory {
  final int id;
  final String period;
  final String redTitle;
  final String redYear;
  final String detail;
  final String imageUrl;

  MapHistory({
    required this.id,
    required this.period,
    required this.redTitle,
    required this.redYear,
    required this.detail,
    required this.imageUrl,
  });

  factory MapHistory.fromJson(Map<String, dynamic> json) {
    String raw = (json['imagePath'] ?? '').toString().trim();

    String imageUrl = "";
    if (raw.isNotEmpty) {
      String file = raw.split('/').last;
      imageUrl = "https://entrappingly-humanlike-letha.ngrok-free.dev/images/History_Map/$file";
    }

    return MapHistory(
      id: json['id'] ?? 0,
      period: json['period'] ?? '',
      redTitle: json['redTitle'] ?? '',
      redYear: json['redYear'] ?? '',
      detail: json['detail'] ?? '',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'redTitle': redTitle,
      'redYear': redYear,
      'detail': detail,
      'imageUrl': imageUrl,
    };
  }
}
