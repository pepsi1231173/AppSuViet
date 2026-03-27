class HistoricalDocument {
  final int id;
  final String title;
  final String documentType;
  final String year;
  final String description;
  final String content;
  final String imageUrl;

  HistoricalDocument({
    required this.id,
    required this.title,
    required this.documentType,
    required this.year,
    required this.description,
    required this.content,
    required this.imageUrl,
  });

  factory HistoricalDocument.fromJson(Map<String, dynamic> j) {
    String raw = (j['imageUrl'] ?? "").toString().trim();

    // Nếu không có ảnh → không hiển thị
    if (raw.isEmpty) {
      return HistoricalDocument(
        id: j['id'],
        title: j['title'] ?? '',
        documentType: j['documentType'] ?? '',
        year: j['year'] ?? '',
        description: j['description'] ?? '',
        content: j['content'] ?? '',
        imageUrl: "",
      );
    }

    // Lấy tên file ảnh cuối cùng
    String file = raw.split('/').last;

    // Tự động tạo link giống HistoricalFigure
    String fullUrl =
        "https://entrappingly-humanlike-letha.ngrok-free.dev/images/HistoricalDocuments/$file";

    return HistoricalDocument(
      id: j['id'],
      title: j['title'] ?? '',
      documentType: j['documentType'] ?? '',
      year: j['year'] ?? '',
      description: j['description'] ?? '',
      content: j['content'] ?? '',
      imageUrl: fullUrl,
    );
  }
}
