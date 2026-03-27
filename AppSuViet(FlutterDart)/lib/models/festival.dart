class Festival {
  final int id;
  final String name;
  final String description;
  final String? dateGregorian;
  final String? dateLunar;
  final bool isLunar;
  final String? type;
  final String? tags;
  final String? imageUrl; // đường dẫn tương đối từ server

  Festival({
    required this.id,
    required this.name,
    required this.description,
    this.dateGregorian,
    this.dateLunar,
    required this.isLunar,
    this.type,
    this.tags,
    this.imageUrl,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      dateGregorian: json['dateGregorian'],
      dateLunar: json['dateLunar'],
      isLunar: json['isLunar'] ?? false,
      type: json['type'],
      tags: json['tags'],
      imageUrl: json['imageUrl'], // ví dụ: images/holidays/tet.jpg
    );
  }

  // 🚀 Hàm tạo URL đầy đủ từ đường dẫn tương đối
  String? getFullImageUrl(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return '$baseUrl/$imageUrl';
  }
}
