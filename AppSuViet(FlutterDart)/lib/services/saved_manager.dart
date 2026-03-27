import 'package:flutter/foundation.dart';
import '../models/saved_item.dart';

class SavedManager extends ChangeNotifier {
  static final SavedManager _instance = SavedManager._internal();
  factory SavedManager() => _instance;
  SavedManager._internal();

  final List<SavedItem> _items = [];

  List<SavedItem> get items => List.unmodifiable(_items);

  bool isSaved(String id) {
    return _items.any((e) => e.id == id);
  }

  void toggle(SavedItem item) {
    final index = _items.indexWhere((e) => e.id == item.id);

    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(item);
    }

    notifyListeners(); // 🔥 BẮT BUỘC
  }
}
