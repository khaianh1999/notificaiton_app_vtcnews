import 'dart:convert'; // jsonDecode
import 'package:http/http.dart' as http; // HTTP client

import '../models/article_detail_dto.dart'; // Đổi sang DTO!

class ArticleApiService {
  static const _baseUrl = 'https://api.vtcnews.vn/api/News';

  final http.Client _client;
  ArticleApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Gọi API /Detail?id=...
  Future<ArticleDetailDto> fetchArticleDetail(int id) async {
    final uri = Uri.parse('$_baseUrl/Detail?id=$id');

    /// Nếu API yêu cầu header Accept/Token ... thì thêm ở đây
    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'VTCNewsApp/1.0', // tuỳ bạn
      },
    );
    // print('GET $uri → ${res}');
    if (res.statusCode == 200) {
      return ArticleDetailDto.fromJson(jsonDecode(res.body));
    } else {
      throw http.ClientException('API trả về mã lỗi ${res.statusCode}', uri);
    }
  }

  /// Đóng client khi không dùng nữa (gọi trong dispose của Repository/ViewModel)
  void dispose() => _client.close();
}
