class Province {
  final int id;
  final String code;
  final String name;
  final String history;
  final String? imageUrl;

  const Province({
    required this.id,
    required this.code,
    required this.name,
    required this.history,
    this.imageUrl,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    final String? imagePath = json['imageUrl'];

    // Lấy ảnh từ wwwroot qua API, đổi localhost -> 10.0.2.2 cho Android Emulator
    final String? fullUrl = imagePath != null && imagePath.isNotEmpty
        ? 'https://entrappingly-humanlike-letha.ngrok-free.dev$imagePath' : null;

    return Province(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      history: json['history'] ?? '',
      imageUrl: fullUrl,
    );
  }
}
