import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../models/era.dart';
import '../models/historical_figure.dart';
import '../models/TimelineItem.dart';
import 'timeline_detail_screen.dart';
import 'historical_figure_detail_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';

class EraDetailScreen extends StatefulWidget {
  final String eraName;

  const EraDetailScreen({
    super.key,
    required this.eraName,
  });

  @override
  State<EraDetailScreen> createState() => _EraDetailScreenState();
}

class _EraDetailScreenState extends State<EraDetailScreen> {
  final ApiService _api = ApiService();

  late Future<Era> _eraFuture;
  late Future<List<HistoricalFigure>> _figuresFuture;
  late Future<List<TimelineItem>> _eventsFuture;

  // ---------------- TTS ----------------
  final FlutterTts flutterTts = FlutterTts();
  List<Map<String, String>> vietnamVoices = [];
  String? selectedVoiceId;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();

    _eraFuture = _api.fetchEraDetailByName(widget.eraName);

    // ✅ LẤY TẤT CẢ → LỌC THEO TRIỀU ĐẠI (KHÔNG TRÙNG)
    _figuresFuture = _api.fetchHistoricalFigures().then((figures) {
      final String dynastyName = widget.eraName.replaceAll('_', ' ');

      // role hợp lệ
      const validRoles = {'Vua', 'Danh tướng', 'Tướng lĩnh'};

      return figures.where((f) {
        return f.dynasty == dynastyName &&
            validRoles.contains(f.role);
      }).toList();
    });

    _eventsFuture = _api.fetchEventsByPeriod(widget.eraName);

    loadVietnamVoices();
    setupTts();
  }



  // Bảng thời gian triều đại
  final Map<String, List<int>> _eraRanges = {
    "Nhà_Ngô": [939, 965],
    "Nhà_Đinh": [968, 980],
    "Nhà_Tiền_Lê": [980, 1009],
    "Nhà_Lý": [1009, 1225],
    "Nhà_Trần": [1226, 1400],
    "Nhà_Hồ": [1400, 1407],
    "Nhà_Hậu_Lê": [1428, 1789],
    "Nhà_Mạc": [1527, 1677],
    "Nhà_Tây_Sơn": [1778, 1802],
    "Nhà_Nguyễn": [1802, 1945]
  };

  // ---------------- TTS ----------------
  Future<void> loadVietnamVoices() async {
    dynamic voices = await flutterTts.getVoices;
    if (voices == null) return;

    Map<String, Map<String, String>> unique = {};

    for (var v in voices) {
      if (v["locale"] != "vi-VN") continue;

      final String fullName = v["name"];

      final RegExp regex = RegExp(r'vi-vn-x-([a-z]+)');
      final match = regex.firstMatch(fullName.toLowerCase());
      if (match == null) continue;

      final voiceKey = match.group(1)!;

      unique.putIfAbsent(voiceKey, () => {
        "name": fullName,
        "id": v["voiceIdentifier"] ?? fullName,
      });
    }

    List<Map<String, String>> cleaned = unique.values.toList();

    for (int i = 0; i < cleaned.length; i++) {
      cleaned[i]["display"] = "Voice ${i + 1}";
    }

    setState(() {
      vietnamVoices = cleaned;
      if (cleaned.isNotEmpty) {
        selectedVoiceId = cleaned.first["id"];
      }
    });
  }

  Future<void> setupTts() async {
    await flutterTts.setSpeechRate(0.46);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  Future<void> speakText(String text) async {
    if (selectedVoiceId == null) return;

    await flutterTts.stop();
    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
  }

  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }


  // ---------------- ERA IMAGE (USING FLAGS) ----------------
  Widget _buildEraImage(Era era) {
    final Map<String, String> flagMap = {
      "Nhà Ngô": "assets/images/flags/conhango.jpg",
      "Nhà Đinh": "assets/images/flags/conhadinh.jpg",
      "Nhà Tiền Lê": "assets/images/flags/conhatienle.jpg",
      "Nhà Lý": "assets/images/flags/conhaly.jpg",
      "Nhà Trần": "assets/images/flags/conhatran.jpg",
      "Nhà Hồ": "assets/images/flags/conhaho.jpg",
      "Nhà Hậu Lê": "assets/images/flags/conhahaule.jpg",
      "Nhà Mạc": "assets/images/flags/conhamac.jpg",
      "Nhà Tây Sơn": "assets/images/flags/conhatayson.jpg",
      "Nhà Nguyễn": "assets/images/flags/conhanguyen.jpg",
    };

    final img = flagMap[era.name] ?? era.imageUrl;

    return Image.asset(
      img,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 220,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image_not_supported,
              size: 60, color: Colors.grey),
        ),
      ),
    );
  }

  Future<String> buildFullSpeechText() async {
    final era = await _eraFuture;
    final figures = await _figuresFuture;
    final events = await _eventsFuture;

    StringBuffer buffer = StringBuffer();

    buffer.writeln("Triều đại: ${era.name.replaceAll('_', ' ')}.");
    buffer.writeln("Mô tả: ${era.description}.");

    buffer.writeln("Các vị vua và danh tướng:");
    if (figures.isEmpty) {
      buffer.writeln("Không có nhân vật nổi bật.");
    } else {
      for (var f in figures) {
        buffer.writeln("${f.name}, thời gian trị vì: ${f.reignPeriod}. ${f.description}.");
      }
    }

    buffer.writeln("Các sự kiện của triều đại:");
    if (events.isEmpty) {
      buffer.writeln("Không có sự kiện nổi bật.");
    } else {
      for (var e in events) {
        buffer.writeln("Năm ${e.year}: ${e.eventTitle}. ${e.description}.");
      }
    }

    return buffer.toString();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8), // nền giấy cổ

      appBar: AppBar(
        title: Text(
          widget.eraName.replaceAll('_', ' '),
          style: const TextStyle(
            fontFamily: "Merriweather",
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C4A2E), // nâu gỗ
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              SavedManager().isSaved(widget.eraName)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                SavedManager().toggle(
                  SavedItem(
                    id: widget.eraName,
                    title: widget.eraName.replaceAll('_', ' '),
                    type: 'Triều đại',
                    screen: EraDetailScreen(eraName: widget.eraName), // ⭐ QUAN TRỌNG
                  ),
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    SavedManager().isSaved(widget.eraName)
                        ? '📌 Đã lưu triều đại'
                        : '❌ Đã bỏ lưu triều đại',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // 🔊 TTS (GIỮ NGUYÊN)
          IconButton(
            icon: Icon(
              isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              if (isSpeaking) {
                stopText();
              } else {
                String fullText = await buildFullSpeechText();
                await speakText(fullText);
              }
            },
          ),
        ],

      ),

      body: FutureBuilder<Era>(
        future: _eraFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final era = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------- ẢNH TRIỀU ĐẠI --------------------
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown.shade700, width: 3),
                  ),
                  child: _buildEraImage(era),
                ),

                const SizedBox(height: 12),

                // -------------------- GIỌNG ĐỌC --------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3DE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.brown, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🎙️ Giọng đọc",
                          style: TextStyle(
                            fontFamily: "Merriweather",
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C4A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.brown),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedVoiceId,
                              items: vietnamVoices.map((v) {
                                return DropdownMenuItem(
                                  value: v["id"],
                                  child: Text(
                                    v["display"] ?? v["name"]!,
                                    style: const TextStyle(
                                      fontFamily: "Merriweather",
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => selectedVoiceId = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // -------------------- MÔ TẢ TRIỀU ĐẠI --------------------
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.brown, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          era.name.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontFamily: "Merriweather",
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C3518),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          era.description.isEmpty
                              ? "Không có mô tả chi tiết."
                              : era.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: "NotoSerif",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(thickness: 2),

                // -------------------- NHÂN VẬT --------------------
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    "🧑‍🤴 Các vị vua và danh tướng",
                    style: TextStyle(
                      fontFamily: "Merriweather",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C4A2E),
                    ),
                  ),
                ),
// -------------------- GHI CHÚ ROLE --------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3DE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.crown, color: Colors.brown),
                            SizedBox(width: 8),
                            Text("Vua", style: TextStyle(fontFamily: "NotoSerif")),
                          ],
                        ),
                        SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(FontAwesomeIcons.shieldHalved, color: Colors.brown),
                            SizedBox(width: 8),
                            Text("Danh tướng", style: TextStyle(fontFamily: "NotoSerif")),
                          ],
                        ),
                        SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(FontAwesomeIcons.userShield, color: Colors.brown),
                            SizedBox(width: 8),
                            Text("Tướng lĩnh", style: TextStyle(fontFamily: "NotoSerif")),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                FutureBuilder<List<HistoricalFigure>>(
                  future: _figuresFuture,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final figures = snap.data!;
                    if (figures.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Không có nhân vật nổi bật."),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: figures.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final f = figures[i];

                        IconData icon = Icons.person;

                        if (f.role == "Vua") {
                          icon = FontAwesomeIcons.crown;
                        } else if (f.role == "Danh tướng") {
                          icon = FontAwesomeIcons.shieldHalved;
                        } else if (f.role == "Tướng lĩnh") {
                          icon = FontAwesomeIcons.userShield;
                        }


                        return ListTile(
                          leading: Icon(
                            icon,
                            size: 48,
                            color: Colors.brown.shade700,
                          ),
                          title: Text(
                            f.name,
                            style: const TextStyle(
                              fontFamily: "Merriweather",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "${f.reignPeriod}\n${f.description}",
                            style: const TextStyle(fontFamily: "NotoSerif"),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoricalFigureDetailScreen(figure: f),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: Icon(
                              SavedManager().isSaved(f.id.toString())
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.brown.shade700,
                            ),
                            onPressed: () {
                              setState(() {
                                SavedManager().toggle(
                                  SavedItem(
                                    id: f.id.toString(), // ⭐ ÉP STRING
                                    title: f.name,
                                    type: 'Nhân vật',
                                    screen: HistoricalFigureDetailScreen(figure: f),
                                  ),
                                );

                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // -------------------- SỰ KIỆN --------------------
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    "📜 Các sự kiện nổi bật",
                    style: TextStyle(
                      fontFamily: "Merriweather",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C4A2E),
                    ),
                  ),
                ),

                FutureBuilder<List<TimelineItem>>(
                  future: _eventsFuture,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final events = snap.data!;
                    if (events.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Không có sự kiện nổi bật."),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        return Card(
                          elevation: 3,
                          color: const Color(0xFFFFF8E7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.brown.shade700, width: 2),
                          ),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.history_edu,
                                color: Colors.brown.shade800, size: 32),
                            title: Text(
                              e.eventTitle,
                              style: const TextStyle(
                                  fontFamily: "Merriweather",
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${e.year}\n${e.description}",
                              style: const TextStyle(fontFamily: "NotoSerif"),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TimelineDetailScreen(item: e),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: Icon(
                                SavedManager().isSaved(e.id.toString())
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.brown.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  SavedManager().toggle(
                                    SavedItem(
                                      id: e.id.toString(), // ⭐ ÉP STRING
                                      title: e.eventTitle,
                                      type: 'Sự kiện',
                                      screen: TimelineDetailScreen(item: e),
                                        ),
                                      );
                                  });
                              },
                            ),

                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
