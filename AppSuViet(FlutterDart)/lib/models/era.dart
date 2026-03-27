class Era {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int startYear;
  final int endYear;

  Era({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.startYear,
    required this.endYear,
  });

  factory Era.fromJson(Map<String, dynamic> json) {
    // 🖼 Map ảnh từ assets
    final Map<String, String> imageMap = {
      "Nhà Ngô": "assets/images/nha_ngo.jpg",
      "Nhà Đinh": "assets/images/nha_dinh.jpg",
      "Nhà Tiền Lê": "assets/images/nha_tien_le.jpg",
      "Nhà Lý": "assets/images/nha_ly.jpg",
      "Nhà Trần": "assets/images/nha_tran.jpg",
      "Nhà Hồ": "assets/images/nha_ho.jpg",
      "Nhà Hậu Lê": "assets/images/nha_hau_le.jpg",
      "Nhà Mạc": "assets/images/nha_mac.jpg",
      "Nhà Tây Sơn": "assets/images/nha_tay_son.jpg",
      "Nhà Nguyễn": "assets/images/nha_nguyen.jpg",
    };

    final name = json['name'] ?? '';

    return Era(
      id: json['id'] ?? 0,
      name: name,
      description: json['description'] ?? 'Không có mô tả chi tiết.',
      imageUrl: imageMap[name] ?? "assets/images/default.jpg",
      startYear: json['startYear'] ?? 0,
      endYear: json['endYear'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'startYear': startYear,
    'endYear': endYear,
  };
}
