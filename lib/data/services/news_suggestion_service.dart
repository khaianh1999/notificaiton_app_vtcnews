import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_suggestion_response.dart';

class NewsSuggestionService {
  final String baseUrl = 'https://api.vtcnews.vn';

  Future<NewsSuggestionResponse> getSuggestions({
    required int parentCateId,
    required int categoryId,
    required int articleId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/News/GetNewsSuggestionInDetail?categoryId=$categoryId&articleId=$articleId&parentCateId=$parentCateId',
    );

    final response = await http.get(url);
    // log data trả về
    // print('GET $url → ${response.statusCode}');
    // Nếu bạn muốn log body, hãy cẩn thận với dữ liệu nhạy cảm
    // print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return NewsSuggestionResponse.fromJson(data);
    } else {
      throw Exception('Lỗi tải suggestion: ${response.statusCode}');
    }
  }
}
