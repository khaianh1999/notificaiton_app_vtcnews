class ShortVideo {
  final int id;
  final String title;
  final String description;
  final String videoUrl; // full URL
  final String thumbUrl; // full URL

  ShortVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbUrl,
  });

  factory ShortVideo.fromJson(Map<String, dynamic> j) {
    // API trả đường dẫn tương đối, ghép CDN ở đây cho gọn
    const cdn = 'https://cdn-v.vtcnews.vn';
    const cdnThumb = 'https://cdn-i.vtcnews.vn/resize/me';
    return ShortVideo(
      id: j['Id'] as int,
      title: j['Title'] as String,
      description: j['Description'] as String,
      videoUrl: cdn + (j['VideoURL'] as String),
      thumbUrl: cdnThumb + (j['ThumbURL'] as String),
    );
  }
}
