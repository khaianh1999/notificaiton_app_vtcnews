class TabModel {
  final String name;
  final int id;

  TabModel({required this.name, required this.id});

  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(name: json['Name'] ?? '', id: json['CateId'] ?? 0);
  }
}
