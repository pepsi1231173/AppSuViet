import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/historical_figure.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';


class HistoricalFigureDetailScreen extends StatefulWidget {
  final HistoricalFigure figure;

  const HistoricalFigureDetailScreen({
    super.key,
    required this.figure,
  });

  @override
  State<HistoricalFigureDetailScreen> createState() =>
      _HistoricalFigureDetailScreenState();
}

class _HistoricalFigureDetailScreenState
    extends State<HistoricalFigureDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, String>> vietnamVoices = [];
  String? selectedVoiceId;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    setupTts();
    loadVietnamVoices();
  }

  // ============================
  //      LOAD TTS VOICES
  // ============================
  Future<void> loadVietnamVoices() async {
    dynamic voices = await flutterTts.getVoices;
    if (voices == null) return;

    Map<String, Map<String, String>> unique = {};

    for (var v in voices) {
      if (v["locale"] != "vi-VN") continue;

      final name = v["name"];
      final RegExp regex = RegExp(r'vi-vn-x-([a-z]+)');
      final match = regex.firstMatch(name.toLowerCase());
      if (match == null) continue;

      final key = match.group(1)!; // ví dụ: "hbt"

      unique.putIfAbsent(key, () => {
        "name": name,
        "id": v["voiceIdentifier"] ?? name,
      });
    }

    List<Map<String, String>> list = unique.values.toList();

    for (int i = 0; i < list.length; i++) {
      list[i]["display"] = "Voice ${i + 1}";
    }

    setState(() {
      vietnamVoices = list;
      if (list.isNotEmpty) selectedVoiceId = list.first["id"];
    });
  }

  // ============================
  //       SETUP TTS
  // ============================
  Future<void> setupTts() async {
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  // ============================
  //       SPEAK
  // ============================
  Future<void> speakText() async {
    if (selectedVoiceId == null) return;

    await flutterTts.stop();
    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    final text = widget.figure.detail.isNotEmpty
        ? widget.figure.detail
        : widget.figure.description;

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
  }

  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.figure.imageUrl.isNotEmpty && widget.figure.imageUrl != "NULL";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        title: Text(
          widget.figure.name,
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🔊 TTS
          IconButton(
            icon: Icon(
              isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              if (isSpeaking) {
                await stopText();
              } else {
                await speakText();
              }
            },
          ),

          // ⭐ LƯU NHÂN VẬT
          AnimatedBuilder(
            animation: SavedManager(),
            builder: (context, _) {
              final isSaved =
              SavedManager().isSaved(widget.figure.id.toString());

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  SavedManager().toggle(
                    SavedItem(
                      id: widget.figure.id.toString(),
                      title: widget.figure.name,
                      type: 'Nhân vật',
                      screen: HistoricalFigureDetailScreen(
                        figure: widget.figure,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),

      // ============================
      //           BODY
      // ============================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBD7), // nền cổ điển
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.figure.imageUrl,
                    fit: BoxFit.contain, // 👈 QUAN TRỌNG
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // =========================
            //    CHỌN GIỌNG RẤT GỌN
            // =========================
            if (vietnamVoices.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Giọng đọc:",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B3A29),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // BOX SHORT
                  Container(
                    height: 44, // NGẮN GỌN
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.brown.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedVoiceId,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: vietnamVoices.map((v) {
                          return DropdownMenuItem(
                            value: v["id"],
                            child: Text(v["display"]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedVoiceId = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),

            // ============================
            //    TEXT DETAILS
            // ============================
            Text(
              widget.figure.name,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5B3A29),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              "🔥 Vai trò: ${widget.figure.role}",
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B5E3C),
              ),
            ),

            const SizedBox(height: 6),

            Text("🏯 Triều đại: ${widget.figure.dynasty}",
                style: GoogleFonts.notoSerif(fontSize: 15)),

            Text("⏳ Thời gian: ${widget.figure.reignPeriod}",
                style: GoogleFonts.notoSerif(fontSize: 15)),

            const SizedBox(height: 20),

            Text(
              "📜 Mô tả ngắn:",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Text(widget.figure.description,
                style: GoogleFonts.notoSerif(fontSize: 15)),

            const SizedBox(height: 20),

            Text(
              "📖 Chi tiết lịch sử:",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B3A29),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              widget.figure.detail,
              style: GoogleFonts.notoSerif(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
