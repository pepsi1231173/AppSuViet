import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/HistoricalDocument .dart';
import '../services/api_service.dart';
import 'document_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  late Future<List<HistoricalDocument>> _future;

  List<HistoricalDocument> _allDocs = [];
  List<HistoricalDocument> _filteredDocs = [];
  late stt.SpeechToText _speech;
  bool _speechReady = false;
  bool _isListening = false;


  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchDocuments();

    _speech = stt.SpeechToText();
    _initSpeech();

    _searchCtrl.addListener(() {
      _runSearch(_searchCtrl.text);
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
          _runSearch(_searchCtrl.text);
        }
      },
      onError: (error) {
        debugPrint("❌ SPEECH ERROR: $error");
        setState(() => _isListening = false);
        _runSearch(_searchCtrl.text);
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
      _runSearch(_searchCtrl.text);
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
          _searchCtrl.text = result.recognizedWords;
          _searchCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchCtrl.text.length),
          );
        });
      },
    );
  }


  void _runSearch(String query) {
    final lower = query.toLowerCase();

    setState(() {
      _filteredDocs = _allDocs.where((d) {
        return d.title.toLowerCase().contains(lower) ||
            d.documentType.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),

      appBar: AppBar(
        centerTitle: true, // 👈 căn giữa tiêu đề
        backgroundColor: const Color(0xFF8B5E3C),
        title: Text(
          "📜 Văn Kiện Lịch Sử",
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
      ),

      body: FutureBuilder(
        future: _future,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _allDocs = snapshot.data!;
          if (_filteredDocs.isEmpty && _searchCtrl.text.isEmpty) {
            _filteredDocs = _allDocs;
          }

          return Column(
            children: [
              // ============================
              //        SEARCH BAR
              // ============================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Tìm văn kiện (gõ hoặc nói)...",
                    hintStyle: GoogleFonts.notoSerif(fontSize: 16),
                    filled: true,
                    fillColor: Colors.brown.shade100.withOpacity(0.5),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

                    // 🎤 MIC BÊN TRÁI
                    prefixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.brown.shade700,
                      ),
                      onPressed: _toggleListening,
                    ),

                    // ❌ CLEAR
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                      icon: Icon(Icons.clear, color: Colors.brown.shade700),
                      onPressed: () {
                        _searchCtrl.clear();
                        _runSearch("");
                        FocusScope.of(context).unfocus();
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.brown.shade400,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.brown.shade400,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // ============================
              //       LIST DOCUMENTS
              // ============================
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredDocs.length,
                  itemBuilder: (_, i) {
                    final d = _filteredDocs[i];
                    final hasImage = d.imageUrl.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          // BACKGROUND IMAGE
                          if (hasImage)
                            Opacity(
                              opacity: 0.35,
                              child: Image.network(
                                d.imageUrl,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 220,
                              width: double.infinity,
                              color: Colors.brown.shade100,
                            ),

                          // LIGHT OVERLAY + TEXT
                          Container(
                            height: 220,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${d.documentType} – ${d.year}",
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // CLICKABLE OVERLAY
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.white24,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentDetailScreen(doc: d),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
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
