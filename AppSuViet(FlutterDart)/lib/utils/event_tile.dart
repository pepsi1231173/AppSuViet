import 'package:flutter/material.dart';
import '../models/event.dart';
import '../screens/event_detail_screen.dart';

class EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap; // ✅ thêm onTap

  const EventTile({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(event.title),
      subtitle: Text(event.date ?? ''),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: event.id.toString()), // ✅ ép kiểu sang String
              ),
            );
          },
    );
  }
}
