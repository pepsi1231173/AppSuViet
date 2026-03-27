import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class VoiceSelectorWidget extends StatefulWidget {
  const VoiceSelectorWidget({super.key});

  @override
  State<VoiceSelectorWidget> createState() => _VoiceSelectorWidgetState();
}

class _VoiceSelectorWidgetState extends State<VoiceSelectorWidget> {
  String selectedVoice = TTSService.voices.first["code"]!;

  @override
  void initState() {
    super.initState();
    TTSService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedVoice,
          items: TTSService.voices.map((v) {
            return DropdownMenuItem(
              value: v["code"],
              child: Text(v["name"]!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedVoice = value);
              TTSService.setVoice(value);
            }
          },
        ),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: () {
            TTSService.speak(
              "Xin chào! Đây là giọng đọc thử nghiệm tiếng Việt.",
              selectedVoice,
            );
          },
          child: const Text("📢 Nghe thử"),
        ),
      ],
    );
  }
}
