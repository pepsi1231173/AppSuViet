import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/map_history.dart';
import '../services/api_service.dart';
import 'dart:ui';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapHistoryScreen extends StatefulWidget {
  final int? savedMapId; // 👈 THÊM
  const MapHistoryScreen({super.key,this.savedMapId});


  @override
  State<MapHistoryScreen> createState() => _MapHistoryScreenState();
}

class _MapHistoryScreenState extends State<MapHistoryScreen> {
  final ApiService _api = ApiService();
  late Future<List<MapHistory>> _future;

  PageController? _pageController;
  int _currentIndex = 0;
  bool _isSheetOpen = false;

  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, String>> vietnamVoices = [];
  String? selectedVoiceId;
  bool isSpeaking = false;


  @override
  void initState() {
    super.initState();
    _future = _api.fetchMapHistories();
    setupTts();
    loadVietnamVoices();
  }


  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }



  void _jumpToIndex(int index) {
    Navigator.pop(context);
    _pageController?.jumpToPage(index);
  }

  Map<String, List<MapHistory>> groupByPeriod(List<MapHistory> list) {
    final Map<String, List<MapHistory>> map = {};
    for (var item in list) {
      map.putIfAbsent(item.period, () => []).add(item);
    }
    return map;
  }
// ============================================================
//       LOAD VOICES FROM DEVICE
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

// ============================================================
//                   STOP TTS
// ============================================================
  Future<void> stopText() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapHistory>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            ),
          );
        }

        final maps = snapshot.data!;

// ⭐ KHỞI TẠO PAGE CONTROLLER 1 LẦN DUY NHẤT
        if (_pageController == null) {
          int initialPage = 0;

          if (widget.savedMapId != null) {
            final index = maps.indexWhere((e) => e.id == widget.savedMapId);
            if (index != -1) {
              initialPage = index;
              _currentIndex = index;
            }
          }

          _pageController = PageController(
            initialPage: initialPage,
            viewportFraction: 1.0,
          );
        }

        final grouped = groupByPeriod(maps);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF8B5E3C),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Lãnh thổ Việt Nam qua các thời kì',
              maxLines: 2,              // 👈 cho xuống dòng
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.bold,
                fontSize: 18,           // 👈 giảm nhẹ cho vừa
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            // ⭐ FIX NÚT 3 GẠCH – PHẢI DÙNG BUILDER
            actions: [
              // menu cũ
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),

            endDrawer: Drawer(
              backgroundColor: const Color(0xFFF5E6C8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8B5E3C),
                          Color(0xFF5C3B24),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Icon(Icons.history_edu, size: 70, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          "Lịch Sử Việt Nam",
                          style: GoogleFonts.notoSerif(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Lãnh thổ qua các thời kỳ",
                          style: GoogleFonts.notoSerif(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      children: [
                        for (var period in grouped.keys)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5E1),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(2, 4),
                                )
                              ],
                            ),
                            child: ExpansionTile(
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              leading: const Icon(Icons.flag, color: Color(0xFF8B4513)),
                              title: Text(
                                period,
                                style: GoogleFonts.notoSerif(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade800,
                                ),
                              ),
                              children: [
                                for (var item in grouped[period]!)
                                  ListTile(
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.brown.shade200,
                                      backgroundImage: NetworkImage(item.imageUrl),
                                      onBackgroundImageError: (_, __) {},
                                    ),
                                    title: Text(
                                      item.redTitle,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.redYear,
                                      style: const TextStyle(color: Colors.brown),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.brown),
                                    onTap: () {
                                      final index = maps.indexOf(item);
                                      _jumpToIndex(index);
                                    },
                                  )
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/paper_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRect( // 🔥 CẮT Ở TẦNG NGOÀI CÙNG
                    child: PageView.builder(
                      controller: _pageController!, // 👈 DÒNG NÀY
                      itemCount: maps.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController!,
                          builder: (context, child) {
                            double scale = 1.0;

                            if (_pageController!.position.haveDimensions) {
                              scale = (_pageController!.page! - index).abs();
                              scale = (1 - scale * 0.2).clamp(0.85, 1.0);
                            }

                            return Center(
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SizedBox.expand(
                              child: _buildMapPage(
                                maps[index],
                                index == _currentIndex,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapCard(MapHistory map) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            /// 🗺️ ẢNH BẢN ĐỒ
            AspectRatio(
              aspectRatio: 3 / 5,
              child: Image.network(
                map.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.map, size: 60, color: Colors.brown),
                ),
              ),
            ),

            /// ⭐ ICON LƯU – GÓC PHẢI TRÊN ẢNH
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedBuilder(
                animation: SavedManager(),
                builder: (context, _) {
                  final isSaved =
                  SavedManager().isSaved(map.id.toString());

                  return InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      SavedManager().toggle(
                        SavedItem(
                          id: map.id.toString(),
                          title: map.redTitle,
                          type: 'Bản đồ lịch sử',
                          screen: MapHistoryScreen(
                            savedMapId: map.id,
                          ),
                          data: map.id,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: isSaved
                            ? Colors.red.shade700
                            : Colors.brown,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPage(MapHistory map, bool isActive) {
    return Stack(
      children: [
        /// NỀN FULL
        Positioned.fill(
          child: Container(color: const Color(0xFFFFF7E6)),
        ),

        /// 🌿 NỘI DUNG TRÊN – CĂN GIỮA TUYỆT ĐỐI
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420, // 👈 GIỮ BỐ CỤC GỌN – KHÔNG BỊ LỆCH
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 14),

                /// 🔴 TIÊU ĐỀ – RIÊNG BIỆT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      /// ⭐ NÚT LƯU – GÓC PHẢI (KHÔNG ẢNH HƯỞNG CANH GIỮA)

                      /// 🟥 TIÊU ĐỀ + NĂM – CANH GIỮA TUYỆT ĐỐI
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              map.redTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSerifDisplay(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              map.redYear,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSerif(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 12),

                /// 🗺️ ẢNH – GIỮ NGUYÊN, CĂN GIỮA
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.68,
                  child: Center(
                    child: _buildMapCard(map),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 📜 SHEET – CHỈ PAGE ACTIVE
        if (isActive)
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _isSheetOpen = notification.extent > 0.22;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.15, // 👈 thấp hơn
              minChildSize: 0.15,     // 👈 thấp hơn
              maxChildSize: 0.8,
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6).withOpacity(0.94),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ======================
                        // 🔊 GIỌNG ĐỌC (TTS) – GỌN NHẸ
                        // ======================
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 38, // 👈 THẤP HƠN
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.brown.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedVoiceId,
                                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                                    style: GoogleFonts.notoSerif(
                                      fontSize: 14, // 👈 CHỮ NHỎ HƠN
                                      color: Colors.brown.shade900,
                                    ),
                                    items: vietnamVoices.map((v) {
                                      return DropdownMenuItem(
                                        value: v["id"],
                                        child: Text(
                                          v["display"] ?? v["name"]!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => selectedVoiceId = value);
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
                                  size: 22, // 👈 ICON NHỎ LẠI
                                  color: Colors.brown.shade800,
                                ),
                                onPressed: () {
                                  if (isSpeaking) {
                                    stopText();
                                  } else {
                                    speakText(map.detail);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),



                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: map.detail
                              .split('\n')
                              .where((e) => e.trim().isNotEmpty)
                              .map(
                                (paragraph) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                paragraph.trim(),
                                textAlign: TextAlign.justify,
                                style: GoogleFonts.notoSerif(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Colors.brown.shade900,
                                ),
                              ),
                            ),
                          )
                              .toList(),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

}
