import 'package:notification_vtcnews/data/models/news_suggestion_item.dart';

class NewsSuggestionResponse {
  final List<NewsSuggestionItem> sameCate;
  final List<NewsSuggestionItem> trend;

  NewsSuggestionResponse({required this.sameCate, required this.trend});

  factory NewsSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final detailItem = json['DetailListItemModel'] ?? {};
    final listSameCate =
        (detailItem['ListSameCate']?['ListItem'] as List? ?? []);
    final listTrend = (detailItem['ListTrend']?['ListItem'] as List? ?? []);

    return NewsSuggestionResponse(
      sameCate:
          listSameCate.map((e) => NewsSuggestionItem.fromJson(e)).toList(),
      trend: listTrend.map((e) => NewsSuggestionItem.fromJson(e)).toList(),
    );
  }
}
