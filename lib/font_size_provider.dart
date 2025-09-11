import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  double _fontSize = 16;
  double get fontSize => _fontSize;

  // Hàm load từ SharedPreferences khi khởi động
  Future<void> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16;
    notifyListeners(); // thông báo cho tất cả listener
  }

  // Hàm set fontSize và lưu xuống SharedPreferences
  Future<void> setFontSize(double newSize) async {
    _fontSize = newSize;
    notifyListeners(); // thông báo ngay lập tức
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', newSize);
  }
}
