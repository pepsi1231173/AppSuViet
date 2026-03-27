import 'package:flutter/material.dart';
import '../models/historical_figure.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'historical_figure_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class HistoricalFiguresScreen extends StatefulWidget {
  const HistoricalFiguresScreen({super.key});

  @override
  State<HistoricalFiguresScreen> createState() =>
      _HistoricalFiguresScreenState();
}

class _HistoricalFiguresScreenState extends State<HistoricalFiguresScreen> {
  late Future<List<HistoricalFigure>> _future;

  List<HistoricalFigure> allFigures = [];
  List<HistoricalFigure> filteredFigures = [];
  late stt.SpeechToText _speech;
  bool _speechReady = false;
  bool _isListening = false;


  final TextEditingController _searchController = TextEditingController();
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchHistoricalFigures();
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
    try {
      final data = await _future;
      setState(() {
        allFigures = data;
        filteredFigures = List.from(allFigures);
      });
    } catch (e) {}
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
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
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
  // Normalize tiếng Việt
  // =============================
  String _normalize(String input) {
    final s = input.toLowerCase();

    const from =
        "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ";
    const to =
        "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd";

    String result = s;
    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }

    result = result.replaceAll(RegExp(r"[^\w\s]"), " ");
    result = result.replaceAll(RegExp(r"\s+"), " ").trim();

    return result;
  }

  // =============================
  // Filter theo tên
  // =============================
  void _filterSearch(String query) {
    final q = _normalize(query);

    if (q.isEmpty) {
      setState(() {
        filteredFigures = List.from(allFigures);
      });
      return;
    }

    setState(() {
      filteredFigures = allFigures.where((f) {
        final nameNorm = _normalize(f.name);
        return nameNorm.contains(q);
      }).toList();
    });
  }

  // =============================
  // Icon theo vai trò
  // =============================
  Widget _getRoleIcon(String role) {
    final r = role.trim().toLowerCase();

    if (r == "vua") {
      return const Icon(Icons.account_balance,
          color: Colors.deepPurple, size: 40);
    }

    if (r.contains("nhiếp chính")) {
      return const Icon(Icons.gavel,
          color: Colors.indigo, size: 40);
    }

    if (r.contains("hoàng hậu")) {
      return const Icon(Icons.favorite,
          color: Colors.pink, size: 40);
    }

    if (r.contains("hoàng tộc")) {
      return const Icon(Icons.family_restroom,
          color: Colors.brown, size: 40);
    }

    if (r.contains("quốc sư")) {
      return const Icon(Icons.menu_book,
          color: Colors.teal, size: 40);
    }

    if (r.contains("quan đại thần") || r.contains("quan chức")) {
      return const Icon(Icons.badge,
          color: Colors.green, size: 40);
    }

    if (r.contains("danh tướng")) {
      return const Icon(Icons.shield,
          color: Colors.red, size: 40);
    }

    if (r.contains("tướng lĩnh")) {
      return const Icon(Icons.military_tech,
          color: Colors.redAccent, size: 40);
    }

    if (r.contains("anh hùng")) {
      return const Icon(Icons.star,
          color: Colors.orange, size: 40);
    }

    if (r.contains("nhà cách mạng")) {
      return const Icon(Icons.flag,
          color: Colors.deepOrange, size: 40);
    }

    if (r.contains("nhà yêu nước")) {
      return const Icon(Icons.volunteer_activism,
          color: Colors.orangeAccent, size: 40);
    }

    if (r.contains("thế lực cát cứ")) {
      return const Icon(Icons.location_city,
          color: Colors.grey, size: 40);
    }

    if (r.contains("thần thoại")) {
      return const Icon(Icons.auto_awesome,
          color: Colors.purple, size: 40);
    }

    return const Icon(Icons.person, color: Colors.grey, size: 40);
  }

  void _filterByRole(String? role) {
    setState(() {
      selectedRole = role;

      if (role == null) {
        filteredFigures = List.from(allFigures);
      } else {
        filteredFigures =
            allFigures.where((f) => f.role.trim() == role).toList();
      }
    });
  }

  // =============================
  // Item chú giải vai trò
  // =============================
  PopupMenuItem<String> _roleLegendItem(
      IconData icon, Color color, String text) {
    return PopupMenuItem<String>(
      value: text, // ⭐ bắt buộc để onSelected nhận
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.notoSerif(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87, // rõ nét
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),

      // =============================
      // APP BAR + MENU
      // =============================
      appBar: AppBar(
        centerTitle: true, // 👈 căn giữa tiêu đề
        title: Text(
          'Các nhân vật lịch sử Việt Nam',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white, // 👈 chữ trắng
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            color: const Color(0xFFFFF8E7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            // ⭐ CLICK ROLE → LỌC NGAY
            onSelected: (value) {
              _filterByRole(value == "Tất cả" ? null : value);
            },

            itemBuilder: (context) => [
              _roleLegendItem(
                  Icons.list, Colors.black87, "Tất cả"),

              const PopupMenuDivider(),

              _roleLegendItem(
                  Icons.account_balance, Colors.deepPurple, "Vua"),
              _roleLegendItem(
                  Icons.gavel, Colors.indigo, "Nhiếp chính"),
              _roleLegendItem(
                  Icons.favorite, Colors.pink,
                  "Hoàng hậu – Hoàng thái hậu"),
              _roleLegendItem(
                  Icons.family_restroom, Colors.brown, "Hoàng tộc"),
              _roleLegendItem(
                  Icons.menu_book, Colors.teal, "Quốc sư"),
              _roleLegendItem(
                  Icons.badge, Colors.green, "Quan đại thần"),
              _roleLegendItem(
                  Icons.badge, Colors.green, "Quan chức"),
              _roleLegendItem(
                  Icons.shield, Colors.red, "Danh tướng"),
              _roleLegendItem(
                  Icons.military_tech, Colors.redAccent, "Tướng lĩnh"),
              _roleLegendItem(
                  Icons.star, Colors.orange, "Anh hùng"),
              _roleLegendItem(
                  Icons.flag, Colors.deepOrange, "Nhà cách mạng"),
              _roleLegendItem(
                  Icons.volunteer_activism,
                  Colors.orangeAccent, "Nhà yêu nước"),
              _roleLegendItem(
                  Icons.location_city,
                  Colors.grey, "Thế lực cát cứ"),
              _roleLegendItem(
                  Icons.auto_awesome,
                  Colors.purple, "Thần thoại"),
            ],
          )
        ],
      ),


      // =============================
      // BODY
      // =============================
      body: FutureBuilder<List<HistoricalFigure>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (allFigures.isEmpty) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          return Column(
            children: [
              // SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm theo tên nhân vật (gõ hoặc nói)...",

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
                        icon:
                        const Icon(Icons.clear, color: Colors.brown),
                        onPressed: () {
                          _searchController.clear();
                          _filterSearch("");
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


              // LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredFigures.length,
                  itemBuilder: (context, index) {
                    final figure = filteredFigures[index];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFF8B5E3C),
                          width: 1.5,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFFFF8E7),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: _getRoleIcon(figure.role),
                        title: Text(
                          figure.name,
                          style: GoogleFonts.cormorantGaramond(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "${figure.dynasty} • ${figure.reignPeriod}",
                          style: GoogleFonts.notoSerif(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HistoricalFigureDetailScreen(
                                      figure: figure),
                            ),
                          );
                        },
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
