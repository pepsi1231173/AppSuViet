import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/provinces.dart';
import '../widgets/interactive_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';



class MapScreen extends StatefulWidget {
  final String? focusProvinceCode;

  const MapScreen({
    super.key,
    this.focusProvinceCode,
  });

  static const routeName = '/map';

  @override
  State<MapScreen> createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  String? selectedProvinceCode;
  String searchText = "";
  final TransformationController _transformationController = TransformationController();

  late Future<List<Province>> _provincesFuture;
  bool showProvincePanel = false;
  late stt.SpeechToText _speech;
  bool _speechReady = false;
  bool _isListening = false;

  final TextEditingController _provinceSearchCtrl = TextEditingController();


  final FlutterTts flutterTts = FlutterTts();
  List<Map<String, String>> vnVoices = [];
  String? selectedVoiceId;

  @override
  @override
  void initState() {
    super.initState();
    _provincesFuture = fetchProvinces();
    initTTS();

    _speech = stt.SpeechToText();
    _initSpeech();

    _provinceSearchCtrl.addListener(() {
      setState(() {
        searchText = _provinceSearchCtrl.text.toLowerCase().trim();
      });
    });

    if (widget.focusProvinceCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provincesFuture.then((provinces) {
          _onProvinceTap(provinces, widget.focusProvinceCode!);
        });
      });
    }
  }



  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // ==============================
  // FETCH API
  // ==============================
  Future<List<Province>> fetchProvinces() async {
    const String apiUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev/api/Provinces';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Province.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi fetchProvinces: $e');
      throw Exception('Không thể kết nối tới API: $e');
    }
  }

  // ==============================
  // INIT TTS (CHỈ CHẠY 1 LẦN)
  // ==============================
  Future<void> initTTS() async {
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    await loadVoices();
  }

  Future<void> loadVoices() async {
    try {
      dynamic voices = await flutterTts.getVoices;
      if (voices == null) return;

      Map<String, Map<String, String>> unique = {};

      for (var v in voices) {
        if (v["locale"] != "vi-VN") continue;

        final name = (v["name"] ?? "").toLowerCase();
        final match = RegExp(r"vi-vn-x-([a-z]+)").firstMatch(name);
        if (match == null) continue;

        String idKey = match.group(1)!;

        unique[idKey] = {
          "id": v["voiceIdentifier"] ?? v["name"],
          "name": v["name"],
          "display": "Giọng ${unique.length + 1}"
        };
      }

      setState(() {
        vnVoices = unique.values.toList();
        if (vnVoices.isNotEmpty) selectedVoiceId = vnVoices.first["id"];
      });
    } catch (e) {
      debugPrint("⚠ Load Voice Error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (selectedVoiceId == null) return;

    await flutterTts.stop();
    await flutterTts.setVoice({
      "name": selectedVoiceId!,
      "locale": "vi-VN",
    });

    await flutterTts.speak(text);
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
        }
      },
      onError: (error) {
        debugPrint("❌ SPEECH ERROR: $error");
        setState(() => _isListening = false);
      },
    );

    debugPrint("🎙 SPEECH READY = $_speechReady");
  }
  void _toggleListeningProvince() async {
    if (!_speechReady) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'vi_VN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        setState(() {
          _provinceSearchCtrl.text = result.recognizedWords;
          _provinceSearchCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _provinceSearchCtrl.text.length),
          );
        });
      },
    );
  }

  // ==============================
  // WHEN TAP A PROVINCE
  // ==============================
  void _onProvinceTap(List<Province> provinces, String code) async {
    setState(() => selectedProvinceCode = code);

    final province = provinces.firstWhere(
          (p) => p.code == code,
      orElse: () => Province(
        id: 0,
        code: '',
        name: 'Không xác định',
        history: 'Chưa có dữ liệu lịch sử cho tỉnh này.',
        imageUrl: null,
      ),
    );

    bool isSpeaking = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF8E8C8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    province.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF5C4033),
                    ),
                  ),
                ),

                // 🔖 ICON LƯU TỈNH
                IconButton(
                  icon: Icon(
                    SavedManager().isSaved("province_${province.code}")
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: Colors.brown,
                  ),
                  onPressed: () {
                    setDialog(() {
                      SavedManager().toggle(
                        SavedItem(
                          id: "province_${province.code}",
                          title: province.name,
                          type: 'Tỉnh thành',
                          screen: MapScreen(
                            focusProvinceCode: province.code, // ⭐ QUAN TRỌNG
                          ),
                          data: province.code,
                        ),
                      );
                    });
                  },
                ),

                // 🔊 TTS
                IconButton(
                  icon: Icon(
                    isSpeaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.brown,
                    size: 28,
                  ),
                  onPressed: () async {
                    if (isSpeaking) {
                      await flutterTts.stop();
                      setDialog(() => isSpeaking = false);
                    } else {
                      await speak(province.history);
                      setDialog(() => isSpeaking = true);
                    }
                  },
                ),
              ],
            ),

            // CONTENT
            content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vnVoices.isNotEmpty) ...[
                      const Text("Chọn giọng đọc:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          )),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.brown),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedVoiceId,
                            isExpanded: true,
                            items: vnVoices.map((v) {
                              return DropdownMenuItem(
                                value: v["id"],
                                child: Text(v["display"]!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedVoiceId = value);
                              setDialog(() {});
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (province.imageUrl != null &&
                        province.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          province.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Text("Không hiển thị được ảnh"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      province.history,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () async {
                  await flutterTts.stop();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Đóng",
                  style: TextStyle(color: Color(0xFF8B4513)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản đồ Việt Nam lịch sử',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFFFFE4B5),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C4033), Color(0xFF8B4513)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      backgroundColor: const Color(0xFFF5E6CA),

      body: FutureBuilder<List<Province>>(
        future: _provincesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('❌ Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có dữ liệu tỉnh."));
          }

          final provinces = snapshot.data!;

          return Stack(
            children: [
              // ================= MAP =================
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.8,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: InteractiveMap(
                          onProvinceTap: (code) => _onProvinceTap(provinces, code),
                          selectedProvince: selectedProvinceCode,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ================= MENU BUTTON (☰) =================
              Positioned(
                top: 20,
                left: 20,
                child: FloatingActionButton(
                  heroTag: "menu",
                  mini: true,
                  backgroundColor: Colors.brown,
                  onPressed: () {
                    setState(() {
                      showProvincePanel = !showProvincePanel;
                    });
                  },
                  child: Icon(
                    showProvincePanel ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ),

              // ================= ZOOM BUTTONS =================
              Positioned(
                right: 20,
                bottom: 20,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "zoom_in",
                      mini: true,
                      backgroundColor: Colors.brown.shade300,
                      onPressed: () {
                        Matrix4 matrix = _transformationController.value.clone();
                        matrix.scale(1.2);
                        _transformationController.value = matrix;
                      },
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: "zoom_out",
                      mini: true,
                      backgroundColor: Colors.brown.shade300,
                      onPressed: () {
                        Matrix4 matrix = _transformationController.value.clone();
                        matrix.scale(0.8);
                        _transformationController.value = matrix;
                      },
                      child: const Icon(Icons.remove, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ================= PROVINCE PANEL (SLIDE) =================
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 70,
                left: showProvincePanel ? 20 : -180, // 👈 TRƯỢT RA / ẨN
                child: Container(
                  width: 160,
                  height: 340,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E8C8).withOpacity(0.97),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5E3C)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(2, 3),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // ===== TITLE =====
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5E3C),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        width: double.infinity,
                        child: const Text(
                          'Tỉnh thành Việt Nam',
                          style: TextStyle(
                            color: Color(0xFFFFE4B5),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // ===== SEARCH =====
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.brown),
                        ),
                        child: TextField(
                          controller: _provinceSearchCtrl,
                          decoration: InputDecoration(
                            hintText: "Tìm tỉnh (nói)...",
                            border: InputBorder.none,

                            // 🎤 MIC BÊN TRÁI
                            prefixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                size: 18,
                                color: _isListening ? Colors.red : Colors.brown,
                              ),
                              onPressed: _toggleListeningProvince,
                            ),

                            // ❌ CLEAR
                            suffixIcon: _provinceSearchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _provinceSearchCtrl.clear();
                                setState(() => searchText = "");
                              },
                            ),
                          ),
                        ),
                      ),

                      // ===== LIST =====
                      Expanded(
                        child: ListView(
                          children: provinces
                              .where((p) =>
                              p.name.toLowerCase().contains(searchText))
                              .map((province) {
                            final isSelected =
                                selectedProvinceCode == province.code;

                            return InkWell(
                              onTap: () {
                                _onProvinceTap(provinces, province.code);
                                setState(() => showProvincePanel = false); // 👈 auto ẩn
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD4A373).withOpacity(0.4)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  province.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: const Color(0xFF3E2723),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
