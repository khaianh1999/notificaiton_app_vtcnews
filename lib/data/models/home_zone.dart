class HomeZone {
  final int idItem;
  final String title;
  final int categoryId;
  final List<NewsBrief> news; // listNews đã parse

  HomeZone({
    required this.idItem,
    required this.title,
    required this.categoryId,
    required this.news,
  });

  factory HomeZone.fromJson(Map<String, dynamic> j) {
    final rawNews = j['ListNews'] as List<dynamic>? ?? [];

    // Lấy categoryId từ DetailUrl bằng regex
    final detailUrl = j['DetailUrl'] as String? ?? '';
    final match = RegExp(r'-(\d+)\.html$').firstMatch(detailUrl);
    final categoryId = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
    return HomeZone(
      idItem: j['IdItem'] as int,
      title: j['Title'] as String? ?? '',
      categoryId: categoryId, // 👈 gán giá trị
      news: rawNews.map((e) => NewsBrief.fromJson(e)).toList(),
    );
  }
}

class NewsBrief {
  final int id;
  final String title;
  final String imageUrl;
  final String detailUrl;
  final String description;

  NewsBrief({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.detailUrl,
    required this.description,
  });

  factory NewsBrief.fromJson(Map<String, dynamic> j) => NewsBrief(
    id: j['Id'] as int,
    title: j['Title'] as String? ?? '',
    imageUrl:
        'https://cdn-i.vtcnews.vn/resize/me${j['ImageUrl'] as String? ?? ''}', // ghép CDN
    detailUrl: j['DetailUrl'] as String? ?? '',
    description: j['Description'] as String? ?? '',
  );
}
