import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/festival.dart';
import 'festival_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class FestivalScreen extends StatefulWidget {
  const FestivalScreen({Key? key}) : super(key: key);

  @override
  State<FestivalScreen> createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Festival>> _festivals;
  late stt.SpeechToText _speech;
  bool _speechReady = false;
  bool _isListening = false;


  final String baseUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev';

  List<Festival> allFestivals = [];
  List<Festival> filteredFestivals = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _festivals = _apiService.fetchFestivals();
    _loadData();

    _speech = stt.SpeechToText();
    _initSpeech();

    _searchController.addListener(() {
      _filterSearch(_searchController.text);
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _festivals;
    setState(() {
      allFestivals = data;
      filteredFestivals = List.from(allFestivals);
    });
  }

  // FORMAT DATE
  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Không rõ';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  // =============================
  //  Hàm bỏ dấu tiếng Việt
  // =============================
  String _normalize(String input) {
    const from =
        "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ";
    const to =
        "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd";

    String result = input.toLowerCase();

    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }

    result = result.replaceAll(RegExp(r"[^\w\s]"), " ");
    result = result.replaceAll(RegExp(r"\s+"), " ").trim();

    return result;
  }

  // =============================
  // Lọc theo tên lễ hội
  // =============================
  void _filterSearch(String query) {
    final q = _normalize(query);

    if (q.isEmpty) {
      setState(() => filteredFestivals = List.from(allFestivals));
      return;
    }

    setState(() {
      filteredFestivals = allFestivals.where((f) {
        final nameNorm = _normalize(f.name);
        return nameNorm.contains(q);
      }).toList();
    });
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
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          _filterSearch(_searchController.text);
        }
      },
      onError: (error) {
        debugPrint("❌ SPEECH ERROR: $error");
        setState(() => _isListening = false);
        _filterSearch(_searchController.text);
      },
    );

    debugPrint("🎙 SPEECH READY = $_speechReady");
  }
  void _toggleListening() async {
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
      pauseFor: const Duration(seconds: 4),
      listenFor: const Duration(seconds: 10),
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

  // =============================
  // Badge loại lễ hội
  // =============================
  Widget buildTypeBadge(String type) {
    Color bgColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'lịch sử':
        bgColor = Colors.brown.shade700;
        icon = Icons.flag_rounded;
        break;
      case 'văn hóa':
        bgColor = Colors.orange.shade800;
        icon = Icons.museum_rounded;
        break;
      case 'tôn giáo':
        bgColor = Colors.deepPurple.shade700;
        icon = Icons.temple_buddhist_rounded;
        break;
      case 'giáo dục':
        bgColor = Colors.indigo.shade700;
        icon = Icons.school_rounded;
        break;
      default:
        bgColor = Colors.green.shade700;
        icon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bgColor, size: 20),
          const SizedBox(width: 6),
          Text(
            type,
            style: TextStyle(
              color: bgColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Merriweather',
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // UI chính
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        title: const Text(
          'Ngày lễ & Lễ hội Việt Nam',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Merriweather',
            fontSize: 22,
            color: Colors.white, // 👈 chữ trắng
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),

        centerTitle: true,
      ),

      body: FutureBuilder<List<Festival>>(
        future: _festivals,
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }

          // DATA
          if (allFestivals.isEmpty) {
            return const Center(child: Text("Không có dữ liệu lễ hội."));
          }

          return Column(
            children: [
              // =============================
              // SEARCH BAR
              // =============================
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.brown.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm lễ hội (gõ hoặc nói)...",

                      // 🎤 MIC BÊN TRÁI
                      prefixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.brown,
                        ),
                        onPressed: _toggleListening,
                      ),

                      // ❌ CLEAR
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.brown),
                        onPressed: () {
                          _searchController.clear();
                          _filterSearch("");
                          FocusScope.of(context).unfocus();
                        },
                      ),

                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),

              // =============================
              // LIST VIEW
              // =============================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredFestivals.length,
                  itemBuilder: (context, index) {
                    final f = filteredFestivals[index];
                    final fullImageUrl = f.getFullImageUrl(baseUrl);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FestivalDetailScreen(
                              festival: f,
                              baseUrl: baseUrl,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: const Color(0xFFFFF6E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.brown.shade400, width: 1.5),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fullImageUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  fullImageUrl,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.celebration, size: 100, color: Colors.orangeAccent),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                      fontFamily: 'Merriweather',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    f.isLunar
                                        ? "📅 Âm lịch: ${f.dateLunar ?? ''}"
                                        : "📅 Dương lịch: ${formatDate(f.dateGregorian)}",
                                    style: TextStyle(
                                      color: Colors.deepOrange.shade700,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Merriweather',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (f.type != null && f.type!.isNotEmpty)
                                    buildTypeBadge(f.type!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
