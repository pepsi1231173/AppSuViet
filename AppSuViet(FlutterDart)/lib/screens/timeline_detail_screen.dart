import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/TimelineItem.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';


class TimelineDetailScreen extends StatefulWidget {
  final TimelineItem item;

  const TimelineDetailScreen({super.key, required this.item});

  @override
  State<TimelineDetailScreen> createState() => _TimelineDetailScreenState();
}

class _TimelineDetailScreenState extends State<TimelineDetailScreen> {
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

  // ============================================================
  //       LOAD VOICES FROM DEVICE (ANDROID SETTINGS)
  // ============================================================
  Future<void> loadVietnamVoices() async {
    dynamic voices = await flutterTts.getVoices;

    if (voices == null) return;

    // Map: key = code voice (hbt, htf...), value = voice đại diện
    Map<String, Map<String, String>> unique = {};

    for (var v in voices) {
      if (v["locale"] != "vi-VN") continue;

      final String fullName = v["name"];

      // Lấy code nhân vật (ví dụ: hbt, htf...)
      final RegExp regex = RegExp(r'vi-vn-x-([a-z]+)');
      final match = regex.firstMatch(fullName.toLowerCase());

      if (match == null) continue;

      final voiceKey = match.group(1)!; // ví dụ: "hbt"

      // Chỉ lưu voice đầu tiên của nhóm
      unique.putIfAbsent(voiceKey, () => {
        "name": fullName,
        "id": v["voiceIdentifier"] ?? fullName,
      });
    }

    // Convert lại thành list
    List<Map<String, String>> cleaned = unique.values.toList();

    // Đặt tên hiển thị dễ nhìn
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


  // ============================================================
  //                   SETUP TTS
  // ============================================================
  Future<void> setupTts() async {
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  // ============================================================
  //                   SPEAK TEXT
  // ============================================================
  Future<void> speakText() async {
    if (selectedVoiceId == null) return;

    await flutterTts.stop();

    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    final text = (widget.item.details != null &&
        widget.item.details!.trim().isNotEmpty)
        ? widget.item.details!
        : widget.item.description;

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
  }

  // ============================================================
  //                   STOP TTS
  // ============================================================
  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    const String baseUrl = "https://entrappingly-humanlike-letha.ngrok-free.dev";

    String? fullImageUrl;
    if (widget.item.imageUrl != null && widget.item.imageUrl!.trim().isNotEmpty) {
      final img = widget.item.imageUrl!.trim();

      if (img.startsWith("http")) {
        // Nếu API đã trả về link đầy đủ thì dùng trực tiếp
        fullImageUrl = img;
      } else {
        // Nếu chỉ là tên file hoặc đường dẫn tương đối thì ghép với baseUrl
        final path = img.contains("/") ? img : "images/TimelineEvents/$img";
        fullImageUrl = "$baseUrl/$path";
      }
    }


    return Scaffold(
      backgroundColor: const Color(0xFFF4EAD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        elevation: 3,
        title: Text(
          widget.item.eventTitle,
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [

          // 🔖 ICON LƯU
          IconButton(
            icon: Icon(
              SavedManager().isSaved(widget.item.id.toString())
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              setState(() {
                SavedManager().toggle(
                  SavedItem(
                    id: widget.item.id.toString(), // ⭐ ÉP STRING
                    title: widget.item.eventTitle,
                    type: 'Sự kiện',
                    screen: TimelineDetailScreen(item: widget.item),
                  ),
                );
              });
            },
          ),

          // 🔊 ICON ĐỌC TTS (GIỮ NGUYÊN)
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
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            if (fullImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Image.network(
                  fullImageUrl!,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 260,
                      color: Colors.brown.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),


            // =========================
            //       MAIN CONTENT
            // =========================
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF9EFD6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.brown.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chọn giọng đọc:",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedVoiceId,
                        items: vietnamVoices.map((v) {
                          return DropdownMenuItem(
                            value: v["id"],
                            child: Text(v["display"] ?? v["name"]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedVoiceId = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // YEAR
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5E3C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.year,
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.period,
                          style: GoogleFonts.notoSerif(
                            fontSize: 16,
                            color: Colors.brown.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Text(
                    widget.item.eventTitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    (widget.item.details != null &&
                        widget.item.details!.trim().isNotEmpty)
                        ? widget.item.details!
                        : widget.item.description,
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.brown.shade800,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
