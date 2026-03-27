import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();

  static final List<Map<String, String>> voices = [
    {"name": "Hồng Ngọc", "code": "vi-vn-x-hnf-local"},
    {"name": "Cánh Đồng", "code": "vi-vn-x-wfm-local"},
    {"name": "Rêu",        "code": "vi-vn-x-ncx-local"},
    {"name": "Đám Mây",    "code": "vi-vn-x-bmh-local"},
  ];

  static Future init() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // BẮT BUỘC PHẢI CÓ
    await _tts.awaitSpeakCompletion(true);
  }

  static Future setVoice(String voiceCode) async {
    // Giọng cần đúng key: "name" + "locale"
    await _tts.setVoice({
      "name": voiceCode,
      "locale": "vi-VN",
    });
  }

  static Future speak(String text, String voiceCode) async {
    await _tts.stop();
    await setVoice(voiceCode);
    await _tts.speak(text);
  }

  static Future stop() async {
    await _tts.stop();
  }
}
