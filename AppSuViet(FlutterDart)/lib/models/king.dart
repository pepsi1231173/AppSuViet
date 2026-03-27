/// 👑 Model King (Không có hình ảnh)
class King {
  final int id;
  final int eraId;
  final String name;
  final String reign;
  final String description;

  King({
    required this.id,
    required this.eraId,
    required this.name,
    required this.reign,
    required this.description,
  });

  factory King.fromJson(Map<String, dynamic> json) {
    return King(
      id: json['id'],
      eraId: json['eraId'],
      name: json['name'] ?? '',
      reign: json['reign'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eraId': eraId,
    'name': name,
    'reign': reign,
    'description': description,
  };
}
