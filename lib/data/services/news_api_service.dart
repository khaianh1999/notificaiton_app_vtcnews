import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notification_vtcnews/data/models/news.dart';

class NewsApiService {
  // giả lập HTTP – return Future<List<News>>
  Future<List<News>> fetchTopNews() async {
    // await Future.delayed(const Duration(milliseconds: 800));
    // const raw = [
    //   {
    //     'title': 'Bộ GD công bố lịch thi tốt nghiệp',
    //     'desc': 'Lịch thi THPT quốc gia 2025 giữ ổn định như năm trước.',
    //     'img': 'https://picsum.photos/id/1024/400/200',
    //   },
    //   {
    //     'title': 'Kinh tế phục hồi mạnh quý II',
    //     'desc': 'GDP tăng 6.5% nhờ xuất khẩu và đầu tư công.',
    //     'img': 'https://picsum.photos/id/1037/400/200',
    //   },
    //   {
    //     'title': 'Show âm nhạc hoành tráng tại TP HCM',
    //     'desc': 'Hàng ngàn người tham dự đại nhạc hội sân Thống Nhất.',
    //     'img': 'https://picsum.photos/id/1039/400/200',
    //   },
    // ];
    // return raw.map((e) => News.fromJson(e)).toList();

    const url = 'https://api.vtcnews.vn/api/News/GetArticleSuggestionInHome';

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Server trả mã ${res.statusCode}');
    }
    final List<dynamic> jsonList =
        json.decode(res.body) as List<dynamic>; // <-- SỬA

    /* 2️⃣  Map → model News, 3️⃣  gắn domain cho ảnh  */
    return jsonList
        .where((e) => e['Title'] != null && e['ImageUrl'] != null)
        .map(
          (e) => News(
            // <-- SỬA
            id: e['Id'],
            title: e['Title'],
            desc: e['Description'] ?? '',
            img: 'https://cdn-i.vtcnews.vn/resize/me${e['ImageUrl']}',
          ),
        )
        .toList();
  }
}
