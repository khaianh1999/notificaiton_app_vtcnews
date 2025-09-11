import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tab_model.dart';

class MenuService {
  Future<List<TabModel>> fetchMenuTabs() async {
    const url = 'https://api.vtcnews.vn/api/News/GetDataMenuZone';

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Server trả mã ${res.statusCode}');
    }

    final jsonMap = json.decode(res.body) as Map<String, dynamic>;

    final List parentList =
        (jsonMap['DataZoneMenu']?['DataZoneMenu'] as List<dynamic>? ?? [])
                .firstWhere(
                  (z) => z['ZoneCode'] == 'zone_menu_ex_moblie',
                  orElse: () => <String, dynamic>{},
                )?['ListParent']
            as List<dynamic>? ??
        [];

    return parentList
        .where((e) => e['Name'] != null && e['CateId'] != null)
        .map((e) => TabModel.fromJson(e))
        .toList();
  }

  Future<List<TabModel>> fetchMenuTabMenu() async {
    const url = 'https://api.vtcnews.vn/api/News/GetDataMenuZone';

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Server trả mã ${res.statusCode}');
    }

    final jsonMap = json.decode(res.body) as Map<String, dynamic>;

    final List parentList =
        (jsonMap['DataZoneMenu']?['DataZoneMenu'] as List<dynamic>? ?? [])
                .firstWhere(
                  (z) => z['ZoneCode'] == 'zone_menu_bot_mobile',
                  orElse: () => <String, dynamic>{},
                )?['ListParent']
            as List<dynamic>? ??
        [];

    return parentList
        .where((e) => e['Name'] != null && e['CateId'] != null)
        .map((e) => TabModel.fromJson(e))
        .toList();
  }
}
