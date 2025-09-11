import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static void logViewArticle(int id, String title) {
    _analytics.logEvent(
      name: 'view_article_app',
      parameters: {'id': id, 'title': title},
    );
  }

  static void logLogin(String method) {
    _analytics.logLogin(loginMethod: method);
  }

  // Thêm các hàm log khác tùy app của bạn
}
