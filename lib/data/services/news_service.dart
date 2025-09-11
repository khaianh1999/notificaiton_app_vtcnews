import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const _host = 'https://api.vtcnews.vn/api';

  Future<List<Map<String, dynamic>>> fetchNewsHot(int cateId) async {
    final uri = Uri.parse('$_host/News/NewsHot?categoryId=$cateId');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  }

  Future<List<Map<String, dynamic>>> fetchSuggestion(
    int cateId,
    int page,
  ) async {
    final uri = Uri.parse(
      '$_host/News/GetArticleSuggestionInNews'
      '?categoryId=$cateId&pageIndex=$page',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Server ${res.statusCode}');
    }

    /* 1) JSON gốc là Map, chứa key Articles */
    final Map<String, dynamic> map =
        json.decode(res.body) as Map<String, dynamic>;

    /* 2) Lấy danh sách Articles – nếu null thì gán []  */
    final List<dynamic> raw = map['Articles'] as List<dynamic>? ?? [];

    /* 3) Trả về List<Map<String,dynamic>>  (đã lọc Title & ImageUrl) */
    return raw
        .where((e) => e['Title'] != null && e['ImageUrl'] != null)
        .map(
          (e) => {
            'Id': e['Id'],
            'Title': e['Title'],
            'Description': e['Description'] ?? '',
            'ImageUrl': '${e['ImageUrl']}',
          },
        )
        .toList();
  }
}
