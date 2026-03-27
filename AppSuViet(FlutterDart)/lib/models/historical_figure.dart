class HistoricalFigure {
  final int id;
  final String dynasty;
  final String name;
  final String reignPeriod;
  final String description;
  final String detail;
  final String imageUrl;
  final String role;

  HistoricalFigure({
    required this.id,
    required this.dynasty,
    required this.name,
    required this.reignPeriod,
    required this.description,
    required this.detail,
    required this.imageUrl,
    required this.role,
  });

  factory HistoricalFigure.fromJson(Map<String, dynamic> json) {
    // Raw data từ API
    String raw = (json['imageUrl'] ?? '').toString().trim();

    // Nếu NULL hoặc rỗng → không hiện ảnh
    if (raw.isEmpty) {
      return HistoricalFigure(
        id: json['id'],
        dynasty: json['dynasty'] ?? '',
        name: json['name'] ?? '',
        reignPeriod: json['reignPeriod'] ?? '',
        description: json['description'] ?? '',
        detail: json['detail'] ?? '',
        imageUrl: "", // Không có ảnh
        role: (json['role'] ?? '').toString().trim(),
      );
    }

    // Nếu API trả đường dẫn kiểu /images/historical_figures/1.jpg
    String file = raw.split('/').last;
    String fullUrl = "https://entrappingly-humanlike-letha.ngrok-free.dev/images/historical_figures/$file";

    return HistoricalFigure(
      id: json['id'],
      dynasty: json['dynasty'] ?? '',
      name: json['name'] ?? '',
      reignPeriod: json['reignPeriod'] ?? '',
      description: json['description'] ?? '',
      detail: json['detail'] ?? '',
      imageUrl: fullUrl,
      role: (json['role'] ?? '').toString().trim(),
    );
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'dynasty': dynasty,
    'name': name,
    'reignPeriod': reignPeriod,
    'description': description,
    'detail': detail,
    'imageUrl': imageUrl,
    'role': role,
  };
}
