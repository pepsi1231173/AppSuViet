import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class QuizCategoryScreen extends StatelessWidget {
  const QuizCategoryScreen({super.key});

  final List<Map<String, String>> categories = const [
    {
      'title': 'Lịch sử Việt Nam 1856 - 1930',
      'era': '1856-1930',
      'desc': 'Phong trào yêu nước và cách mạng Việt Nam trước 1930.'
    },
    {
      'title': 'Lịch sử Việt Nam 1930 - 1945',
      'era': '1930-1945',
      'desc': 'Sự ra đời của Đảng Cộng sản Việt Nam và Cách mạng Tháng Tám.'
    },
    {
      'title': 'Lịch sử Việt Nam 1945 - 1954',
      'era': '1945-1954',
      'desc': 'Kháng chiến chống Pháp và chiến thắng Điện Biên Phủ.'
    },
    {
      'title': 'Lịch sử Việt Nam 1954 - 1975',
      'era': '1954-1975',
      'desc': 'Cuộc kháng chiến chống Mỹ, thống nhất đất nước.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EED3), // Nền kem nâu nhạt
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B3F2A), // Nâu đậm
        elevation: 0,
        title: const Text(
          "📜 Chọn phần trắc nghiệm",
          style: TextStyle(
            color: Color(0xFFFFE8C2),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFE8C2)),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8C7), // Nâu kem
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8C5A3B), // Nâu viền
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.25),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(eraName: item['era']),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon phong cách cổ
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: Color(0xFF6B3F2A), // nâu đậm
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B3F2A), // Nâu đậm
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['desc']!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: Color(0xFF3E2A1F), // Nâu chữ
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF8C5A3B), // nâu đất
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
