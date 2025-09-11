// lib/models/hot_article_dto.dart
import 'hot_article.dart';

class HotArticleDto {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime publishedDate;

  HotArticleDto({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedDate,
  });

  factory HotArticleDto.fromJson(Map<String, dynamic> json) {
    const cdn = 'https://cdn-i.vtcnews.vn';
    final rawImg = json['ImageUrl'] as String? ?? '';
    final fullImg = rawImg.startsWith('http') ? rawImg : '$cdn$rawImg';

    return HotArticleDto(
      id: json['Id'] as int,
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      imageUrl: fullImg,
      publishedDate: _parseDotNetDate(json['PublishedDate'] ?? ''),
    );
  }

  HotArticle toEntity() => HotArticle(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    publishedDate: publishedDate,
  );

  /// Chuyển “/Date(1742873400000)/” ➜ DateTime
  static DateTime _parseDotNetDate(String s) {
    final match = RegExp(r'\/Date\((\d+)\)\/').firstMatch(s);
    if (match != null) {
      final millis = int.parse(match.group(1)!);
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    // fallback: now
    return DateTime.now();
  }
}
