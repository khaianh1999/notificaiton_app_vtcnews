// lib/models/hot_article.dart
class HotArticle {
  final int id;
  final String title;
  final String description;
  final String imageUrl; // đã ghép CDN
  final DateTime publishedDate;

  const HotArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedDate,
  });
}
