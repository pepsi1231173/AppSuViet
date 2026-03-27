import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/HistoricalDocument .dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';


class DocumentDetailScreen extends StatefulWidget {
  final HistoricalDocument doc;

  const DocumentDetailScreen({super.key, required this.doc});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  List<Map<String, String>> vietnamVoices = [];
  String? selectedVoiceId;
  bool isSpeaking = false;
  bool isPlayingOriginal = false;

  // ================================
  // AUDIO FILE MAPPING
  // ================================
  String? getOriginalAudioForDoc() {
    switch (widget.doc.id) {
      case 6:
        return "audio/BacHo_TuyenNgonDocLap.mp3";
      case 7:
        return "audio/DocLoiKeuGoiToanQuocKhangChien_.mp3";
      case 9:
        return "audio/DocLoiKeuGoiChongMyCuuNuoc.mp3";
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    setupTts();
    loadVietnamVoices();
  }

  // ============================================================
  // LOAD TTS VOICES
  // ============================================================
  Future<void> loadVietnamVoices() async {
    dynamic voices = await flutterTts.getVoices;
    if (voices == null) return;

    // Tách network / local
    final networkVoices = <Map<String, String>>[];
    final localVoices = <Map<String, String>>[];

    for (var v in voices) {
      if (v["locale"] != "vi-VN") continue;

      final name = v["name"].toString().toLowerCase();
      final id = v["voiceIdentifier"] ?? v["name"];

      if (name.contains("network")) {
        networkVoices.add({
          "id": id,
          "name": v["name"],
        });
      } else if (name.contains("local")) {
        localVoices.add({
          "id": id,
          "name": v["name"],
        });
      }
    }

    final List<Map<String, String>> result = [];

    // ============================
    // ÉP GIỌNG 1 (NETWORK)
    // ============================
    if (networkVoices.isNotEmpty) {
      result.add(networkVoices.first);
    }

    // ============================
    // GIỌNG 2,3: thêm bất kỳ
    // ============================
    final combined = [...networkVoices, ...localVoices];
    for (var v in combined) {
      if (result.length >= 3) break;
      if (!result.any((e) => e["id"] == v["id"])) {
        result.add(v);
      }
    }

    // ============================
    // ÉP GIỌNG 4 (LOCAL)
    // ============================
    if (localVoices.isNotEmpty &&
        !result.any((e) => e["id"] == localVoices.first["id"])) {
      result.add(localVoices.first);
    }

    // ============================
    // GIỌNG 5: bổ sung cho đủ
    // ============================
    for (var v in combined) {
      if (result.length >= 5) break;
      if (!result.any((e) => e["id"] == v["id"])) {
        result.add(v);
      }
    }

    // Gán display
    for (int i = 0; i < result.length; i++) {
      result[i]["display"] = "Giọng ${i + 1}";
    }

    setState(() {
      vietnamVoices = result;
      if (result.isNotEmpty) {
        selectedVoiceId = result.first["id"];
      }
    });
  }

  // ============================================================
  // SETUP TTS
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
  // SPEAK WITH TTS
  // ============================================================
  Future<void> speakText() async {
    // Dừng giọng gốc
    await audioPlayer.stop();
    setState(() => isPlayingOriginal = false);

    if (selectedVoiceId == null) return;

    await flutterTts.stop();
    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    final text = widget.doc.content.isNotEmpty
        ? widget.doc.content
        : widget.doc.description;

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
  }

  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  // ============================================================
  // PLAY ORIGINAL AUDIO (Giọng Bác Hồ)
  // ============================================================
  Future<void> playOriginal() async {
    final audioFile = getOriginalAudioForDoc();
    if (audioFile == null) return;

    await flutterTts.stop();
    setState(() => isSpeaking = false);

    await audioPlayer.play(AssetSource(audioFile));

    setState(() => isPlayingOriginal = true);

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() => isPlayingOriginal = false);
    });
  }

  Future<void> stopOriginal() async {
    await audioPlayer.stop();
    setState(() => isPlayingOriginal = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.doc.imageUrl.isNotEmpty && widget.doc.imageUrl != "NULL";

    final hasOriginalAudio = getOriginalAudioForDoc() != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),

      // ===============================
      //             APPBAR
      // ===============================
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        title: Text(
          widget.doc.title,
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🎙 GIỌNG GỐC BÁC HỒ (NẾU CÓ)
          if (hasOriginalAudio)
            IconButton(
              icon: Icon(
                isPlayingOriginal
                    ? Icons.stop_circle
                    : Icons.record_voice_over_rounded,
                color: Colors.yellowAccent,
                size: 28,
              ),
              tooltip: "Giọng gốc Bác Hồ",
              onPressed: () async {
                if (isPlayingOriginal) {
                  await stopOriginal();
                } else {
                  await playOriginal();
                }
              },
            ),

          // 🔊 TTS
          IconButton(
            icon: Icon(
              isSpeaking ? Icons.stop : Icons.volume_up_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: "Đọc bằng TTS",
            onPressed: () async {
              if (isSpeaking) {
                await stopText();
              } else {
                await speakText();
              }
            },
          ),

          // ⭐ LƯU VĂN KIỆN
          AnimatedBuilder(
            animation: SavedManager(),
            builder: (context, _) {
              final isSaved =
              SavedManager().isSaved(widget.doc.id.toString());

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: "Lưu văn kiện",
                onPressed: () {
                  SavedManager().toggle(
                    SavedItem(
                      id: widget.doc.id.toString(),
                      title: widget.doc.title,
                      type: 'Văn kiện',
                      screen: DocumentDetailScreen(doc: widget.doc),
                    ),
                  );
                },
              );
            },
          ),
        ],

      ),

      // ===============================
      //             BODY
      // ===============================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.doc.imageUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // GIỌNG TTS DROPDOWN
            if (vietnamVoices.isNotEmpty) ...[
              Text(
                "Giọng TTS:",
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  color: Colors.brown.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.brown.shade300, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
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

            Text(
              widget.doc.title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5B3A29),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "📌 Loại văn kiện: ${widget.doc.documentType}",
              style: GoogleFonts.notoSerif(fontSize: 16),
            ),
            Text(
              "📅 Năm ban hành: ${widget.doc.year}",
              style: GoogleFonts.notoSerif(fontSize: 16),
            ),

            const SizedBox(height: 20),

            Text(
              widget.doc.description,
              style: GoogleFonts.notoSerif(
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "📖 Nội dung chi tiết:",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.doc.content,
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
