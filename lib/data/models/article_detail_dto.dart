// lib/models/article_detail_dto.dart
import 'article_detail.dart';

/// DTO phản ánh đúng cấu trúc JSON gốc.
/// (Bạn có thể giữ lại các field khác nếu cần dùng.)
class ArticleDetailDto {
  // ---- các trường bạn thực sự cần ----
  final int id;
  final String title;
  final String description;
  final String imageUrl; // đã ghép CDN sẵn
  final DateTime publishedDate;
  final String content;
  final String author;
  final String categoryName;
  final int categoryId;
  final int categoryCode;

  // ---- constructor ----
  ArticleDetailDto({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedDate,
    required this.content,
    required this.author,
    required this.categoryName, // nếu không có thì để rỗng
    required this.categoryId,
    required this.categoryCode,
  });

  /// Parse từ JSON trả về:
  ///  {
  ///    "videoList": [],
  ///    "DetailData": { ... }
  ///  }
  factory ArticleDetailDto.fromJson(Map<String, dynamic> json) {
    // 1. Lấy phần detail; nếu không có thì dùng chính json gốc
    final dRaw = json['DetailData'] ?? json; //  <-- thêm null‑fallback
    if (dRaw is! Map<String, dynamic>) {
      throw FormatException('Không tìm thấy dữ liệu DetailData hợp lệ');
    }
    final d = dRaw as Map<String, dynamic>;

    // 2. Build DTO
    const cdn = 'https://cdn-i.vtcnews.vn';
    final rawImg = d['ImageUrl'] as String? ?? '';
    final fullImg = rawImg.startsWith('http') ? rawImg : '$cdn$rawImg';

    return ArticleDetailDto(
      id: d['Id'] as int? ?? 0,
      title: d['Title'] ?? '',
      description: d['Description'] ?? '',
      imageUrl: fullImg,
      publishedDate:
          DateTime.tryParse(d['PublishedDate'] ?? '') ?? DateTime.now(),
      content: d['Content'] ?? '',
      author: d['Author'] ?? 'VTCNews',
      categoryName: d['CategoryName'] ?? '',
      categoryId: d['CategoryId'],
      categoryCode: int.tryParse(d['CategoryCode'].toString()) ?? 0,
    );
  }

  // ---------------- Mapper ----------------
  /// Chuyển sang Entity sạch cho domain/UI.
  ArticleDetail toEntity() => ArticleDetail(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    publishedDate: publishedDate,
    content: content,
    author: author,
    categoryName: categoryName,
    categoryId: categoryId,
    categoryCode: categoryCode,
  );
}
