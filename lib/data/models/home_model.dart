class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String link;
  final DateTime createdAt;
  final String titleTask;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.link,
    required this.createdAt,
    required this.titleTask,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // CreatedAt trả về dạng /Date(1747042745987)/ → cần parse số timestamp
    final rawDate = json["CreatedAt"] as String;
    final timestamp =
        int.tryParse(rawDate.replaceAll(RegExp(r'[^0-9]'), "")) ?? 0;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return NotificationItem(
      id: json["ID"] ?? 0,
      title: json["Title"] ?? "",
      message: json["Message"] ?? "",
      link: json["Link"] ?? "",
      createdAt: createdAt,
      titleTask: json["title_task"] ?? "",
    );
  }
}