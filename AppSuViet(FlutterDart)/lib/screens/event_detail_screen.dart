import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiService _api = ApiService();
  late Future<EventModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchEventDetail(int.tryParse(widget.eventId) ?? 0); // ✅ ép kiểu String → int
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sự kiện")),
      body: FutureBuilder<EventModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          final event = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.date ?? '',
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 20),
                  Text(event.description),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
