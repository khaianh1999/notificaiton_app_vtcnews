class News {
  final String title;
  final String desc;
  final String img;
  final int id;

  News({
    required this.title,
    required this.desc,
    required this.img,
    required this.id,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
    id: json['Id'] as int,
    title: json['Title'] as String,
    desc: json['Description'] as String,
    img: json['ImageUrl'] as String,
  );
}
