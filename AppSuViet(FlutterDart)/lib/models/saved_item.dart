import 'package:flutter/material.dart';

class SavedItem {
  final String id;
  final String title;
  final String type;

  /// Màn hình sẽ mở lại
  final Widget screen;

  /// Dữ liệu truyền kèm (id, index, object...)
  final dynamic data;

  SavedItem({
    required this.id,
    required this.title,
    required this.type,
    required this.screen,
    this.data,
  });
}
