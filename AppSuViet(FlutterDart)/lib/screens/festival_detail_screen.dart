import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/festival.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';

class FestivalDetailScreen extends StatefulWidget {
  final Festival festival;
  final String baseUrl;

  const FestivalDetailScreen({
    Key? key,
    required this.festival,
    required this.baseUrl,
  }) : super(key: key);

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
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
  //                   FORMAT DATE
  // ============================================================
  String getFormattedDate() {
    if (widget.festival.isLunar) {
      return "📅 Âm lịch: ${widget.festival.dateLunar ?? 'Không rõ'}";
    } else if (widget.festival.dateGregorian != null &&
        widget.festival.dateGregorian!.isNotEmpty) {
      try {
        final datePart = widget.festival.dateGregorian!.split('T').first;
        final date = DateTime.parse(datePart);
        final formatted = DateFormat('dd/MM/yyyy').format(date);
        return "📅 Dương lịch: $formatted";
      } catch (e) {
        return "📅 Dương lịch: ${widget.festival.dateGregorian!}";
      }
    } else {
      return "📅 Dương lịch: Không rõ";
    }
  }

  // ============================================================
  //       LOAD VIETNAMESE VOICES (UNIQUE)
  // ============================================================
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
      if (cleaned.isNotEmpty) selectedVoiceId = cleaned.first["id"];
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
  //                   SPEAK CONTENT
  // ============================================================
  Future<void> speakText() async {
    if (selectedVoiceId == null) return;

    await flutterTts.stop();

    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    final text = """
${widget.festival.name}.
${getFormattedDate()}.
${widget.festival.description}
""";

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
  }

  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = widget.festival.getFullImageUrl(widget.baseUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.festival.name),
        backgroundColor: const Color(0xFF8B5E3C),
        actions: [
          IconButton(
            icon: Icon(
              isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
              size: 28,
              color: Colors.white,
            ),
            onPressed: () async {
              if (isSpeaking) {
                await stopText();
              } else {
                await speakText();
              }
            },
          ),

          // ⭐ NÚT LƯU
          AnimatedBuilder(
            animation: SavedManager(),
            builder: (context, _) {
              final isSaved =
              SavedManager().isSaved(widget.festival.id.toString());

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  SavedManager().toggle(
                    SavedItem(
                      id: widget.festival.id.toString(),
                      title: widget.festival.name,
                      type: 'Lễ hội',
                      screen: FestivalDetailScreen(
                        festival: widget.festival,
                        baseUrl: widget.baseUrl,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fullImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fullImageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.orange.shade100,
                      child: const Icon(
                        Icons.celebration,
                        size: 70,
                        color: Colors.orangeAccent,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            // =======================
            //     CHỌN GIỌNG ĐỌC
            // =======================
            const Text(
              "Chọn giọng đọc:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Merriweather',
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

            const SizedBox(height: 16),

            Text(
              widget.festival.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Merriweather',
              ),
            ),

            const SizedBox(height: 8),

            Text(
              getFormattedDate(),
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.deepOrange.shade700,
                fontFamily: 'Merriweather',
              ),
            ),

            const SizedBox(height: 8),

            if (widget.festival.type != null &&
                widget.festival.type!.isNotEmpty)
              Text(
                "Loại: ${widget.festival.type!}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Merriweather',
                ),
              ),

            const SizedBox(height: 8),

            if (widget.festival.tags != null &&
                widget.festival.tags!.isNotEmpty)
              Text(
                "Tags: ${widget.festival.tags}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Merriweather',
                ),
              ),

            const SizedBox(height: 16),

            Text(
              widget.festival.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: 'Merriweather',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
