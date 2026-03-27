import 'package:flutter/material.dart';
import '../models/quiz_question.dart';

class QuizFullReviewScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final List<int> answers;

  const QuizFullReviewScreen({
    super.key,
    required this.questions,
    required this.answers,
  });

  @override
  State<QuizFullReviewScreen> createState() => _QuizFullReviewScreenState();
}

class _QuizFullReviewScreenState extends State<QuizFullReviewScreen> {
  int index = 0;

  // Tông màu nâu giấy cổ
  Color ancientPaper = const Color(0xFFF7EED3);
  Color ancientBorder = const Color(0xFF8C5A3B);
  Color darkBrown = const Color(0xFF6B3F2A);
  Color brownText = const Color(0xFF5B3826);

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[index];
    final selected = widget.answers[index];
    final correct = q.correctIndex;
    final isCorrect = selected == correct;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E9D8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBrown,
        title: const Text(
          "📜 Xem lại bài làm",
          style: TextStyle(
            color: Color(0xFFFFE8C2),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFE8C2)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROGRESS BAR — chỉnh tông nâu đỏ
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (index + 1) / widget.questions.length,
                color: const Color(0xFF8C5A3B),
                backgroundColor: const Color(0xFFDFC9A8),
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              "Câu ${index + 1}/${widget.questions.length}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),

            const SizedBox(height: 16),

            // 40 Ô CÂU HỎI
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ancientPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ancientBorder, width: 2),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, i) {
                  bool answered = widget.answers[i] != -1;
                  bool correctQ = widget.answers[i] ==
                      widget.questions[i].correctIndex;
                  bool isCurrent = index == i;

                  Color color;
                  if (isCurrent)
                    color = const Color(0xFF6B3F2A); // nâu đậm đang xem
                  else if (!answered)
                    color = Colors.grey.shade500;
                  else
                    color = correctQ
                        ? Colors.green.shade700
                        : Colors.red.shade700;

                  return GestureDetector(
                    onTap: () => setState(() => index = i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color,
                      ),
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // HỘP CÂU HỎI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ancientPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ancientBorder, width: 2),
              ),
              child: Text(
                q.question,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: brownText,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DANH SÁCH ĐÁP ÁN
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // DANH SÁCH ĐÁP ÁN
                    ...List.generate(q.options.length, (i) {
                      bool isSelected = selected == i;
                      bool isCorrectOption = correct == i;

                      Color tileColor;
                      if (isCorrectOption)
                        tileColor = Colors.green.shade200;
                      else if (isSelected)
                        tileColor = Colors.red.shade200;
                      else
                        tileColor = const Color(0xFFE8DCC0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          tileColor: tileColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: Text(
                            q.options[i],
                            style: TextStyle(color: brownText, fontSize: 16),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    // HỘP GIẢI THÍCH
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCorrect ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect ? "✓ Bạn trả lời đúng" : "✗ Bạn trả lời sai",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Đáp án đúng: ${q.options[correct]}",
                            style: TextStyle(fontSize: 16, color: brownText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Giải thích: ${q.explanation ?? "Không có giải thích"}",
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                              color: brownText,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
