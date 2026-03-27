import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/TimelineItem.dart';
import '../services/api_service.dart';
import 'timeline_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<TimelineItem>> _future;
  List<TimelineItem> allItems = [];
  List<TimelineItem> filteredItems = [];
  late stt.SpeechToText _speech;
  bool _speechReady = false;
  bool _isListening = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _future = ApiService().fetchTimeline();
    _loadData();
    _searchController.addListener(() {
      _filterSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final items = await _future;
      setState(() {
        allItems = items;
        filteredItems = List<TimelineItem>.from(allItems);
      });
    } catch (e) {
      // lỗi sẽ được hiển thị bởi FutureBuilder nếu cần
    }
  }

  // -----------------------------
  // Hàm chuyển chuỗi sang dạng không dấu, lowercase
  // -----------------------------
  String _normalize(String input) {
    final s = input.toLowerCase();

    // Bảng chuyển các ký tự có dấu sang không dấu (tiếng Việt)
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to   = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';
    String result = s;
    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }

    // loại bỏ ký tự đặc biệt cơ bản
    result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // thu gọn nhiều khoảng trắng
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  // Lọc chỉ theo eventTitle (tên sự kiện), không theo mô tả/năm/period
  void _filterSearch(String query) {
    final qNorm = _normalize(query);

    if (qNorm.isEmpty) {
      setState(() => filteredItems = List<TimelineItem>.from(allItems));
      return;
    }

    setState(() {
      filteredItems = allItems.where((item) {
        final title = (item.eventTitle ?? '');
        final titleNorm = _normalize(title);
        return titleNorm.contains(qNorm);
      }).toList();
    });
  }

  // Helper highlight (giữ nguyên như trước) — có thể bỏ nếu muốn
  Widget _buildDescriptionWithHighlight(String text, String query) {
    if (query.trim().isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.justify,
        style: GoogleFonts.notoSerif(
          fontSize: 16,
          height: 1.5,
          color: Colors.brown.shade800,
        ),
      );
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase().trim();

    final spans = <TextSpan>[];
    int start = 0;
    int index = lower.indexOf(q, start);

    while (index >= 0) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: GoogleFonts.notoSerif(
            fontSize: 16,
            height: 1.5,
            color: Colors.brown.shade800,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + q.length),
        style: GoogleFonts.notoSerif(
          fontSize: 16,
          height: 1.5,
          color: Colors.black,
          backgroundColor: Colors.yellowAccent.withOpacity(0.6),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + q.length;
      index = lower.indexOf(q, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.notoSerif(
          fontSize: 16,
          height: 1.5,
          color: Colors.brown.shade800,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(children: spans),
    );
  }
  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint("❌ MIC PERMISSION DENIED");
      return;
    }

    _speechReady = await _speech.initialize(
      onStatus: (status) {
        debugPrint("🎧 STATUS: $status");

        if (status == "done" || status == "notListening") {
          setState(() => _isListening = false);
          _filterSearch(_searchController.text); // 🔥 TỰ FILTER
        }
      },
      onError: (error) {
        debugPrint("❌ SPEECH ERROR: $error");
        setState(() => _isListening = false);
        _filterSearch(_searchController.text); // 🔥 VẪN FILTER
      },
    );

    debugPrint("🎙 SPEECH READY = $_speechReady");
  }
  Future<void> _toggleListening() async {
    if (!_speechReady) {
      debugPrint("❌ SPEECH NOT READY");
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _filterSearch(_searchController.text);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'vi_VN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        });
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD1), // nền giấy cổ
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF8B5E3C),
        centerTitle: true,
        title: Text(
          '📜 Dòng Thời Gian Việt Nam',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),

      body: FutureBuilder<List<TimelineItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: GoogleFonts.notoSerif(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            );
          }

          if (allItems.isEmpty) {
            return Center(
              child: Text(
                'Không có dữ liệu timeline.',
                style: GoogleFonts.cormorantGaramond(fontSize: 18),
              ),
            );
          }

          return Column(
            children: [

              // ================= SEARCH BAR + MIC =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.brown.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.shade100.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSearch,
                    decoration: InputDecoration(
                      hintText:
                      "Tìm kiếm theo tên sự kiện (gõ hoặc nói)...",

                      // 🎤 MIC BÊN TRÁI
                      prefixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color:
                          _isListening ? Colors.red : Colors.brown,
                        ),
                        onPressed: _toggleListening,
                      ),

                      // ❌ CLEAR BÊN PHẢI
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.brown),
                        onPressed: () {
                          _searchController.clear();
                          _filterSearch('');
                          FocusScope.of(context).unfocus();
                        },
                      ),

                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),

              // ================= LIST =================
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                  child: Text(
                    'Không tìm thấy sự kiện phù hợp.',
                    style:
                    GoogleFonts.notoSerif(fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TimelineDetailScreen(item: item),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E9),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.brown.shade300,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.shade300
                                  .withOpacity(0.3),
                              offset: const Offset(2, 3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              // ==== PERIOD ====
                              Text(
                                item.period,
                                style: GoogleFonts
                                    .cormorantGaramond(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.brown.shade700,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ==== YEAR + TITLE ====
                              Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 14,
                                        vertical: 7),
                                    decoration:
                                    BoxDecoration(
                                      color: const Color(
                                          0xFF8B5E3C),
                                      borderRadius:
                                      BorderRadius
                                          .circular(12),
                                    ),
                                    child: Text(
                                      item.year,
                                      style: GoogleFonts
                                          .notoSerif(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item.eventTitle,
                                      style: GoogleFonts
                                          .cormorantGaramond(
                                        fontSize: 24,
                                        height: 1.2,
                                        fontWeight:
                                        FontWeight.bold,
                                        color: Colors
                                            .brown.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ==== DESCRIPTION ====
                              _buildDescriptionWithHighlight(
                                item.description ?? "",
                                _searchController.text,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
