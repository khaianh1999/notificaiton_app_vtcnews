class NewsSuggestionItem {
  final int id;
  final String title;
  final int categoryId;
  final String imageUrl;
  final String description;
  final String detailUrl;

  NewsSuggestionItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.detailUrl,
  });

  factory NewsSuggestionItem.fromJson(Map<String, dynamic> json) {
    const cdn = 'https://cdn-i.vtcnews.vn';
    final rawImg = json['ImageUrl'] as String? ?? '';
    final fullImg = rawImg.startsWith('http') ? rawImg : '$cdn$rawImg';

    return NewsSuggestionItem(
      id: json['Id'] ?? 0,
      title: json['Title'] ?? '',
      categoryId: json['CategoryId'] ?? 0,
      imageUrl: fullImg,
      description: json['Description'] ?? '',
      detailUrl: json['DetailURL'] ?? '',
    );
  }
}
