class Comment {
  final int id;
  final String userName;
  final String content;
  final DateTime createdAt;
  final int parentId;
  final int totalChild;
  List<Comment> children;

  Comment({
    required this.id,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.parentId,
    required this.totalChild,
    this.children = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final timestamp =
        int.tryParse(
          json['CreatedDate'].toString().replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0;

    return Comment(
      id: json['Id'],
      userName: json['CustomerName'] ?? 'Ẩn danh',
      content: json['Content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      parentId: json['ParentId'],
      totalChild: json['TotalChild'],
    );
  }
}
