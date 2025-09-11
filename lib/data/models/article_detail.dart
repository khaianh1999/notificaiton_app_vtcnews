// lib/models/article_detail.dart
class ArticleDetail {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime publishedDate;
  final String content;
  final String author;
  final String categoryName;
  final int categoryId;
  final int categoryCode;

  const ArticleDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedDate,
    required this.content,
    required this.author,
    required this.categoryName,
    required this.categoryId,
    required this.categoryCode,
  });
}
