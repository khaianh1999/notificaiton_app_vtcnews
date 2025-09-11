import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:notification_vtcnews/views/widget_tree.dart';
import 'package:intl/intl.dart';
import 'package:notification_vtcnews/data/repositories/news_repository.dart';
import 'package:notification_vtcnews/data/repositories/home_repository.dart';
import 'package:notification_vtcnews/data/repositories/menu_repository.dart';
import 'package:notification_vtcnews/data/home_cache.dart';
import 'package:notification_vtcnews/data/models/news.dart';
import 'package:notification_vtcnews/data/models/home_zone.dart';
import 'package:notification_vtcnews/data/models/tab_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_vtcnews/notification_service.dart';

class SplashPage extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const SplashPage({super.key, this.initialMessage});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late String _dateString;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateString = _formatVietnameseDate(now);

    _initApp();
  }

  Future<void> _initApp() async {
    await _prefetchHomeData();

    // Check for and handle the initial message before navigating
    if (widget.initialMessage != null) {
      print("➡️ Handling initial message from terminated state");
      // Use the navigation logic from NotificationService
      NotificationService.instance.navigateToArticleDetail(
        widget.initialMessage!.data,
      );
    }

    // After prefetching and handling the message, navigate to the main app
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // No need to pass the initialMessage to WidgetTree anymore
          builder: (context) => const WidgetTree(),
        ),
      );
    }
  }

  Future<void> _prefetchHomeData() async {
    try {
      final results = await Future.wait([
        NewsRepository().getTopNews().catchError((_) => <News>[]),
        HomeRepository().getHomeZones().catchError((_) => <HomeZone>[]),
        MenuRepository().getTabs().catchError((_) => <TabModel>[]),
      ]);

      HomeCache.topNews = results[0] as List<News>;
      HomeCache.zones = results[1] as List<HomeZone>;
      HomeCache.tabs = results[2] as List<TabModel>;
    } catch (e) {
      debugPrint('Prefetch Home error: $e');
    }
  }

  String _formatVietnameseDate(DateTime date) {
    const weekdays = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
    ];
    final weekday = weekdays[date.weekday % 7];

    return '$weekday, ngày ${date.day} tháng ${date.month} năm ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset('assets/lotties/welcome2.json'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification VTC News',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA2171C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hơi thở cuộc sống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _dateString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
