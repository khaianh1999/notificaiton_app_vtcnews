import '../models/news_suggestion_response.dart';
import '../services/news_suggestion_service.dart';

class NewsSuggestionRepository {
  final _service = NewsSuggestionService();

  Future<NewsSuggestionResponse> fetchSuggestions({
    required int parentCateId,
    required int categoryId,
    required int articleId,
  }) {
    return _service.getSuggestions(
      parentCateId: parentCateId,
      categoryId: categoryId,
      articleId: articleId,
    );
  }
}
