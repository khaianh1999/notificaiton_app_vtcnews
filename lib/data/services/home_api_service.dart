// data/services/home_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/home_zone.dart';

// Hàm top‑level để compute()
List<HomeZone> _parseZones(String body) {
  final rawMap = json.decode(body) as Map<String, dynamic>;
  final rawList = rawMap['listZoneNewsItem'] as List<dynamic>? ?? [];
  return rawList.map((e) => HomeZone.fromJson(e)).toList();
}

class HomeApiService {
  Future<List<HomeZone>> fetchHomeZones() async {
    final uri = Uri.parse('https://api.vtcnews.vn/api/News/GetDataHome');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Server ${res.statusCode}');
    }
    // 🚀 Parse ở isolate
    final zones = await compute(_parseZones, res.body);
    // 🚀 In ra debug console
    // print("res.bodyxxx: ${res.body}");
    return zones;
  }
}
