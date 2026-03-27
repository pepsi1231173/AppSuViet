// ====================================================
//       GIAO DIỆN CỔ TRANG VIỆT NAM – QUIZ SCREEN
// ====================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/quiz_question.dart';
import 'quiz_full_review_screen.dart';

class QuizScreen extends StatefulWidget {
  final String? eraName;

  const QuizScreen({super.key, required this.eraName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _api = ApiService();
  late Future<List<QuizQuestion>> _future;

  List<QuizQuestion> _questions = [];
  List<int> _answers = [];
  int _index = 0;

  bool _loading = true;
  bool _showResult = false;

  Timer? _timer;
  int _remainingSeconds = 45 * 60;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchQuizByEra(widget.eraName ?? "");
    _load();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        setState(() => _showResult = true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  QuizQuestion _shuffleOptions(QuizQuestion q) {
    final indexedOptions = q.options
        .asMap()
        .entries
        .map((e) => {
      'text': e.value,
      'index': e.key,
    })
        .toList();

    indexedOptions.shuffle();

    final newOptions =
    indexedOptions.map((e) => e['text'] as String).toList();

    final newCorrectIndex = indexedOptions
        .indexWhere((e) => e['index'] == q.correctIndex);

    return QuizQuestion(
      id: q.id,
      question: q.question,
      options: newOptions,
      correctIndex: newCorrectIndex,
      era: q.era,
      explanation: q.explanation, // ✅ BẮT BUỘC PHẢI GIỮ
    );
  }


  String _formatTime(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _load() async {
    try {
      _questions = await _future;

      if (_questions.length > 40) {
        _questions = _questions.sublist(0, 40);
      }

      _questions.shuffle();

// 🔥 ĐẢO ĐÁP ÁN CHO TỪNG CÂU
      _questions = _questions.map(_shuffleOptions).toList();

      _answers = List<int>.filled(_questions.length, -1);

    } catch (e) {
      _questions = [];
    }
    setState(() => _loading = false);
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  void _submit() {
    setState(() => _showResult = true);
  }

  // ====================================================
  // MAIN UI
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF8E7), // <<< MÀU NỀN GIẤY NHẸ – KHÔNG DÙNG ẢNH
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(widget.eraName ?? ""),
        body: const Center(child: Text("Không có câu hỏi cho phần này.")),
      );
    }

    if (_showResult) return _buildResult();

    return _buildQuizBody();
  }

  // ====================================================
  //  🎋 AppBar phong cách cổ trang
  // ====================================================
  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: const Color(0xFF8B5E3C),
      centerTitle: true,
      elevation: 6,
      shadowColor: Colors.brown.shade700,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 23,
          fontFamily: "RobotoSlab",
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(
                fontSize: 20,
                fontFamily: "RobotoSlab",
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }

  // ====================================================
// 📌 MÀN HÌNH KẾT QUẢ — FULL CODE ĐÃ CĂN GIỮA
// ====================================================
  Widget _buildResult() {
    int totalCorrect = _answers.asMap().entries
        .where((e) => e.value == _questions[e.key].correctIndex)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.brown.shade700,
        title: Text(
          "Kết quả: ${widget.eraName}",
          style: const TextStyle(
            fontSize: 23,
            fontFamily: "RobotoSlab",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: Align(
        alignment: Alignment.topCenter,  // <<< NHÍCH LÊN
        child: Padding(
          padding: const EdgeInsets.only(top: 10), // <<< NHÍCH LÊN THÊM
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _woodDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Kết quả tổng",
                        style: TextStyle(
                          fontSize: 26,
                          fontFamily: "RobotoSlab",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "$totalCorrect / ${_questions.length} câu đúng",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: "RobotoSlab",
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _rating(totalCorrect),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: "RobotoSlab",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizFullReviewScreen(
                            questions: _questions,
                            answers: _answers,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book, color: Colors.white),
                    label: const Text(
                      "Xem lại toàn bộ bài làm",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: _vietnamButton(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// ====================================================
// 📌 ĐÁNH GIÁ XẾP LOẠI
// ====================================================
  String _rating(int correct) {
    if (correct >= 35) return "🔥 Xuất sắc như Trạng Nguyên!";
    if (correct >= 25) return "👍 Khá tốt – Kiến thức vững vàng!";
    if (correct >= 15) return "🙂 Trung bình – Nên ôn luyện thêm!";
    return "😢 Yếu – Cần luyện lại nhiều chương hơn!";
  }


  // ====================================================
  // 📌 MÀN LÀM BÀI
  // ====================================================
  Widget _buildQuizBody() {
    final q = _questions[_index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar("Phần: ${widget.eraName}"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              backgroundColor: Colors.brown.shade200,
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.brown.shade700),
            ),

            const SizedBox(height: 16),

            Text(
              "Câu ${_index + 1}/${_questions.length}",
              style: const TextStyle(
                fontSize: 22,
                fontFamily: "RobotoSlab",
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: _woodDecoration(),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (_, i) {
                  bool isAnswered = _answers[i] != -1;
                  bool isCurrent = _index == i;

                  return GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isCurrent
                            ? Colors.brown.shade700
                            : isAnswered
                            ? Colors.brown.shade400
                            : Colors.brown.shade200,
                      ),
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "RobotoSlab",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: _paperDecoration(),
              child: Text(
                q.question,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontFamily: "RobotoSlab",
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (_, i) {
                  bool isSelected = _answers[_index] == i;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Colors.brown.shade300
                          : Colors.brown.shade100,
                    ),
                    child: ListTile(
                      title: Text(
                        q.options[i],
                        style: const TextStyle(
                          fontFamily: "RobotoSlab",
                          fontSize: 18,
                        ),
                      ),
                      onTap: () =>
                          setState(() => _answers[_index] = i),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _index > 0 ? _prev : null,
                  style: _vietnamButton(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _answers[_index] == -1
                      ? null
                      : () {
                    if (_index == _questions.length - 1) {
                      _submit();
                    } else {
                      _next();
                    }
                  },
                  style: _vietnamButton(),
                  child: Text(
                    _index == _questions.length - 1
                        ? "Nộp bài"
                        : "Tiếp tục",
                    style: const TextStyle(color: Colors.white), // <<< THÊM DÒNG NÀY
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 🎨 DECORATIONS
  // ====================================================

  BoxDecoration _paperDecoration() => BoxDecoration(
    color: const Color(0xFFFFFBE6),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.brown.shade400, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.brown.shade300,
        offset: const Offset(3, 3),
        blurRadius: 6,
      )
    ],
  );

  BoxDecoration _woodDecoration() => BoxDecoration(
    color: const Color(0xFFB68A68),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.brown.shade900,
        offset: const Offset(4, 4),
        blurRadius: 8,
      ),
    ],
  );

  ButtonStyle _vietnamButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8B5E3C),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontFamily: "RobotoSlab",
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
