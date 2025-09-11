import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/short_video.dart';

class ShortVideoApiService {
  static const _headers = {'referer': 'https://vtcnews.vn'};
  static const _timeout = Duration(seconds: 20);

  Future<List<ShortVideo>> fetchPage(int page) async {
    final url = Uri.parse(
      'https://api.vtcnews.vn/api/News/AjaxListShortVideo?pageIndex=$page',
    );

    try {
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        throw HttpException('Máy chủ trả về mã ${res.statusCode}', uri: url);
      }

      final body = jsonDecode(res.body);

      /* ①  NEW – mảng ở cấp gốc */
      if (body is Map && body['ShortVideos'] is List) {
        return (body['ShortVideos'] as List)
            .map((e) => ShortVideo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      /* ②  OLD – mảng lồng trong data.ShortVideos */
      if (body is Map &&
          body['data'] is Map &&
          (body['data'] as Map)['ShortVideos'] is List) {
        return (body['data']['ShortVideos'] as List)
            .map((e) => ShortVideo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      /* ③  Fallback list thuần (hiếm) */
      if (body is List) {
        return body
            .map((e) => ShortVideo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw const FormatException('Cấu trúc JSON không khớp');
    } on TimeoutException {
      throw Exception('Máy chủ phản hồi chậm, vui lòng thử lại sau.');
    } on SocketException {
      throw Exception('Không có kết nối Internet, kiểm tra mạng của bạn.');
    } on FormatException catch (e) {
      throw Exception('Lỗi dữ liệu: ${e.message}');
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
}
