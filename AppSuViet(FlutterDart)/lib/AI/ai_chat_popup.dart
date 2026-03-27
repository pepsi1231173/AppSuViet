import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class AiChatPopup extends StatefulWidget {
  const AiChatPopup({super.key});

  @override
  State<AiChatPopup> createState() => _AiChatPopupState();
}

class _AiChatPopupState extends State<AiChatPopup> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // Each session: { "id": "...", "title": "...", "messages": [ {"role":"user"/"bot","text":"..."} ] }
  List<Map<String, dynamic>> sessions = [];
  List<Map<String, String>> messages = [];

  String? currentSessionId;
  bool loading = false;

  bool showMenu = false;

  final String baseUrl = "https://entrappingly-humanlike-letha.ngrok-free.dev";
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechReady = false;


  @override
  void initState() {
    super.initState();
    _loadSessions();

    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _autoSendIfNeeded() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      debugPrint("📤 AUTO SEND: $text");
      sendMessage();
    }
  }


  // ================================================================
  // LOAD SESSION (SAFE: xử lý null, fallback, không auto-create nếu đã có)
  // ================================================================
  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("ai_sessions");

    if (raw != null) {
      try {
        final data = jsonDecode(raw);

        // data expected: { "sessions": [...], "currentSessionId": "..." }
        final loadedSessions = data["sessions"];
        final loadedCurrent = data["currentSessionId"];

        if (loadedSessions is List) {
          sessions = loadedSessions
              .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
              .toList();
        } else {
          sessions = [];
        }

        if (loadedCurrent is String && loadedCurrent.isNotEmpty) {
          currentSessionId = loadedCurrent;
        }

        // If there is at least one session, try to select the previously active one,
        // otherwise pick the first session available.
        if (sessions.isNotEmpty) {
          Map<String, dynamic> selected = sessions.first;
          if (currentSessionId != null) {
            try {
              selected = sessions.firstWhere((s) => s["id"] == currentSessionId);
            } catch (_) {
              selected = sessions.first;
              currentSessionId = selected["id"];
            }
          } else {
            currentSessionId = selected["id"];
          }

          // load messages safely (if missing => empty list)
          final rawMessages = selected["messages"];
          if (rawMessages is List) {
            messages = rawMessages
                .map<Map<String, String>>((m) => {
              "role": (m["role"] ?? "").toString(),
              "text": (m["text"] ?? "").toString(),
            })
                .toList();
          } else {
            messages = [];
          }

          setState(() {});
          Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
          return;
        }
      } catch (e) {
        // parsing error -> fallback to create new session later
        debugPrint("Decode error: $e");
      }
    }

    // Only create new session if there is NO session stored.
    if (sessions.isEmpty) {
      _createNewSession();
    }
  }

  // ================================================================
  // SAVE ALL (sessions + currentSessionId)
  // ================================================================
  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure current session has current messages stored inside sessions list
    if (currentSessionId != null) {
      try {
        final idx = sessions.indexWhere((s) => s["id"] == currentSessionId);
        if (idx != -1) {
          sessions[idx]["messages"] = messages;
        }
      } catch (_) {}
    }

    final payload = {
      "sessions": sessions,
      "currentSessionId": currentSessionId,
    };

    await prefs.setString("ai_sessions", jsonEncode(payload));
  }

  // ================================================================
  // NEW SESSION
  // ================================================================
  void _createNewSession() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    currentSessionId = id;

    final newSession = {
      "id": id,
      "title": "Cuộc trò chuyện mới",
      "messages": [],
    };

    // Insert at beginning so newest on top
    sessions.insert(0, newSession);
    messages = [];

    setState(() {});
    await _saveAll();

    // load welcome message (async)
    _loadWelcomeMessage();
  }

  // ================================================================
  // WELCOME MESSAGE
  // ================================================================
  Future<void> _loadWelcomeMessage() async {
    final url = Uri.parse("$baseUrl/api/ai/welcome");

    try {
      final res = await http.get(url);
      String msg = "Xin chào! Bạn muốn tìm hiểu điều gì về lịch sử Việt Nam?";

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        msg = jsonData["message"] ?? msg;
      }

      messages.add({"role": "bot", "text": msg,});

      // save to sessions
      final idx = sessions.indexWhere((s) => s["id"] == currentSessionId);
      if (idx != -1) {
        sessions[idx]["messages"] = messages;
      }

      setState(() {});
    } catch (e) {
      messages.add({
        "role": "bot",
        "text": "Xin chào! Bạn muốn hỏi gì về lịch sử Việt Nam?"
      });
    }

    _saveAll();
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  // ================================================================
  // SEND MESSAGE
  // ================================================================
  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      loading = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Ensure session exists and update title if first message
    final sessionIndex = sessions.indexWhere((s) => s["id"] == currentSessionId);
    if (sessionIndex != -1) {
      sessions[sessionIndex]["messages"] = messages;
      if (sessions[sessionIndex]["title"] == "Cuộc trò chuyện mới") {
        sessions[sessionIndex]["title"] = _extractSessionTitle(text);
      }
    }

    await _saveAll();

    final url = Uri.parse("$baseUrl/api/ai/chat");

    String botReply = "Xin lỗi, mình chưa trả lời được câu này.";

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": text, "useHybrid": true}),
      );

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        botReply = jsonData["answer"] ?? botReply;
      }
    } catch (e) {
      botReply = "Không thể kết nối tới server. Vui lòng thử lại!";
    }

    messages.add({"role": "bot", "text": botReply});

    // update session messages again
    if (sessionIndex != -1) {
      sessions[sessionIndex]["messages"] = messages;
    }

    loading = false;

    setState(() {});
    await _saveAll();
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  // ================================================================
  // SELECT SESSION FROM LIST (LOAD messages)
  // ================================================================
  void _selectSession(Map<String, dynamic> s) {
    // set currentSessionId
    currentSessionId = s["id"]?.toString();

    // load messages from the session safely
    final rawMessages = s["messages"];
    if (rawMessages is List) {
      messages = rawMessages
          .map<Map<String, String>>((m) => {
        "role": (m["role"] ?? "").toString(),
        "text": (m["text"] ?? "").toString(),
      })
          .toList();
    } else {
      messages = [];
    }

    setState(() {
      showMenu = false;
    });

    _saveAll();
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  // ================================================================
  // RENAME SESSION
  // ================================================================
  void _renameSession(Map<String, dynamic> session) {
    TextEditingController renameController =
    TextEditingController(text: session["title"] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Đổi tên chat"),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(hintText: "Nhập tên mới..."),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Lưu"),
              onPressed: () {
                setState(() {
                  final i = sessions.indexWhere((x) => x["id"] == session["id"]);
                  if (i != -1) {
                    sessions[i]["title"] = renameController.text.trim().isEmpty
                        ? sessions[i]["title"]
                        : renameController.text.trim();
                  }
                });
                _saveAll();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // DELETE SESSION
  // ================================================================
  void _deleteSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xóa cuộc trò chuyện"),
          content: const Text("Bạn có chắc muốn xóa?"),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Xóa"),
              onPressed: () {
                setState(() {
                  sessions.removeWhere((s) => s["id"] == session["id"]);
                  // Nếu xóa session đang mở -> chọn session đầu tiên nếu có, ngược lại tạo mới
                  if (session["id"] == currentSessionId) {
                    if (sessions.isNotEmpty) {
                      currentSessionId = sessions.first["id"];
                      // load its messages
                      final rawMessages = sessions.first["messages"];
                      if (rawMessages is List) {
                        messages = rawMessages
                            .map<Map<String, String>>((m) => {
                          "role": (m["role"] ?? "").toString(),
                          "text": (m["text"] ?? "").toString(),
                        })
                            .toList();
                      } else {
                        messages = [];
                      }
                    } else {
                      // no sessions left -> create new
                      currentSessionId = null;
                      messages = [];
                      _createNewSession();
                      // _createNewSession handles save
                    }
                  }
                });

                _saveAll();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // SCROLL
  // ================================================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================================================================
  // UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // MAIN BOX
          Container(
            height: 750,
            decoration: BoxDecoration(
              color: const Color(0xFFF6E9C9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD87B), width: 4),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A0F10),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          setState(() => showMenu = true);
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Trợ Lý Sử Việt AI",
                            style: TextStyle(
                              color: Color(0xFFFFF4D2),
                              fontFamily: "serif",
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat body
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isUser = (m["role"] == "user");

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(
                            maxWidth: 300,   // chỉ giới hạn theo chiều ngang
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Color(0xFFEBD8A8) : Color(0xFFD6C6A1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFB28A47), width: 2),
                          ),
                          child: _buildMessageContent(m["text"] ?? ""),
                        ),
                      );

                    },
                  ),
                ),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Colors.red),
                  ),

                _buildInputBox(),
              ],
            ),
          ),
          if (showMenu)
            Positioned(
              top: 55,          // ✅ dưới header
              left: 270,        // ✅ bên phải menu
              right: 0,
              bottom: 80,       // ✅ CHỪA INPUT BOX + MIC
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => showMenu = false),
                child: Container(color: Colors.transparent),
              ),
            ),

          // ================================================================
          // SLIDE MENU (KHÔNG CHẶN SỰ KIỆN)
          // ================================================================
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: showMenu ? 0 : -270,
            top: 0,
            bottom: 0,
            child: Container(
              width: 270,
              decoration: BoxDecoration(
                color: const Color(0xFFF6E9C9),
                border: Border(
                  right: BorderSide(color: Color(0xFFFFD87B), width: 4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(3, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 65,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A0F10),
                    ),
                    child: const Text(
                      "Danh sách Chat",
                      style: TextStyle(
                        color: Color(0xFFFFF4D2),
                        fontSize: 20,
                        fontFamily: "serif",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Nút New Chat
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A0F10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          setState(() => showMenu = false);
                          _createNewSession();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "New Chat",
                              style: TextStyle(
                                fontFamily: "serif",
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Danh sách chat
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        final isSelected = s["id"] == currentSessionId;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEBD8A8)
                                : const Color(0xFFF6E9C9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                              isSelected ? const Color(0xFFB28A47) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(2, 3),
                                )
                            ],
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              Icons.chat_bubble_outline,
                              color:
                              isSelected ? const Color(0xFF7A0F10) : Colors.brown[600],
                            ),
                            title: Text(
                              s["title"] ?? "Cuộc trò chuyện mới",
                              maxLines: null,                 // ❗ cho phép nhiều dòng
                              overflow: TextOverflow.visible, // ❗ không cắt chữ
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: "serif",
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF7A0F10)
                                    : Colors.black87,
                              ),
                            ),


                            onTap: () {
                              _selectSession(s);
                              setState(() => showMenu = false);
                            },

                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  color: isSelected
                                      ? const Color(0xFF7A0F10)
                                      : Colors.brown[700]),
                              onSelected: (value) {
                                if (value == "rename") _renameSession(s);
                                if (value == "delete") _deleteSession(s);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "rename",
                                  child: Text("Đổi tên"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text("Xóa chat"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================================================================
          // BACKGROUND OVERLAY — CHE PHẦN BÊN PHẢI KHI MENU MỞ (KHÔNG CHE MENU)
          // ================================================================

        ],
      ),
    );
  }

  // ================================================================
  // INPUT BOX
  // ================================================================
  Widget _buildInputBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFFB28A47), width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB28A47), width: 2),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Nhập câu hỏi hoặc nói...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 🎤 MICRO
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isListening ? Colors.green : const Color(0xFF7A0F10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD97D), width: 2),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ➤ SEND
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7A0F10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD97D), width: 2),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMessageContent(String text) {
    final imageRegex = RegExp(r'\[\[IMAGE\]\](.+)');
    final flagRegex = RegExp(r'\[\[FLAG\]\](.+)');

    String contentText = text;
    String? imageUrl;
    String? flagName;
    String? flagAsset;

    // ===== IMAGE URL =====
    final imageMatch = imageRegex.firstMatch(text);
    if (imageMatch != null) {
      imageUrl = imageMatch.group(1)?.trim();
      contentText = contentText.replaceAll(imageMatch.group(0)!, '').trim();
    }

    // ===== FLAG =====
    final flagMatch = flagRegex.firstMatch(text);
    if (flagMatch != null) {
      flagName = flagMatch.group(1)?.trim();
      flagAsset = _dynastyFlags[flagName];
      contentText = contentText.replaceAll(flagMatch.group(0)!, '').trim();
    }

    final isWelcomeMessage =
        contentText.startsWith("Xin chào!") ||
            contentText.startsWith("Chào bạn");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= FLAG IMAGE =================
        if (flagAsset != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                flagAsset,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

        // ================= NETWORK IMAGE =================
        if (imageUrl != null && imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _fixImageUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Text("❌ Không tải được ảnh"),
              ),
            ),
          ),

        // ================= TEXT =================
        if (contentText.isNotEmpty)
          SelectableText(
            contentText,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontFamily: "serif",
            ),
          ),

        // ================= ACTIONS =================
        if (!isWelcomeMessage)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl != null)
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    onPressed: () => _shareImage(imageUrl!),
                  ),

                if (contentText.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: contentText),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }


  Future<void> _shareImage(String imageUrl) async {
    final response = await http.get(Uri.parse(_fixImageUrl(imageUrl)));
    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shared_image.jpg');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ảnh lịch sử Việt Nam',
    );
  }
  String _extractSessionTitle(String question) {
    String q = question.toLowerCase().trim();

    // bỏ dấu câu
    q = q.replaceAll(RegExp(r'[?!.]'), '');

    // ❗ các cụm từ dư thừa (KHÔNG cần đúng tuyệt đối)
    final removePatterns = [
      r'\bcho (tui|tôi|mình)\b',
      r'\bai là\b',
      r'\blà ai\b',
      r'\bcho biết\b',
      r'\bkể về\b',
      r'\bthông tin\b',
      r'\bsự kiện\b',
      r'\btrận\b',
      r'\blịch sử\b',
      r'\bvề\b',
    ];

    for (final pattern in removePatterns) {
      q = q.replaceAll(RegExp(pattern), '');
    }

    // xoá khoảng trắng dư
    q = q.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Viết hoa chữ cái đầu
    q = q
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');

    // Giới hạn độ dài
    if (q.length > 40) {
      q = q.substring(0, 40) + '…';
    }

    return q.isEmpty ? "Cuộc trò chuyện mới" : q;
  }

  Future<void> _toggleListening() async {
    debugPrint("🎤 MIC TAP");

    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Thiết bị chưa sẵn sàng nhận giọng nói"),
        ),
      );
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);

      await _speech.listen(
        localeId: 'vi_VN',
        listenMode: stt.ListenMode.dictation,

        // ⭐⭐ BẮT BUỘC ⭐⭐
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),

        onResult: (result) {
          debugPrint("🗣 RESULT: ${result.recognizedWords}");
          debugPrint("🧠 FINAL: ${result.finalResult}");

          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });

          // 👉 Khi nói xong thật sự
          if (result.finalResult) {
            _speech.stop();
            setState(() => _isListening = false);
          }
        },
      );

    } else {
      // ⏹ DỪNG NGHE
      await _speech.stop();

      setState(() => _isListening = false);

      // ✅ NẾU CÓ NỘI DUNG → GỬI CHAT
      if (_controller.text.trim().isNotEmpty) {
        sendMessage();
      }
    }

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

        // ✅ KẾT THÚC NGHE → AUTO SEND
        if (status == "done" || status == "notListening") {
          if (_isListening) {
            setState(() => _isListening = false);
            _autoSendIfNeeded();
          }
        }
      },
      onError: (error) {
        debugPrint("❌ SPEECH ERROR: $error");

        // ⏱ Timeout = coi như nói xong
        if (error.errorMsg == 'error_speech_timeout') {
          debugPrint("⏱ Timeout – auto send");
          _autoSendIfNeeded();
        }

        setState(() => _isListening = false);
      },
    );

    debugPrint("🎙 SPEECH READY = $_speechReady");
  }



  String _fixImageUrl(String url) {
    if (url.startsWith("http")) return url;

    if (!url.startsWith("/")) {
      url = "/$url";
    }

    return "$baseUrl$url";
  }
  final Map<String, String> _dynastyFlags = {
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


}
