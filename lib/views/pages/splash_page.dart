import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:notification_vtcnews/views/widget_tree.dart';
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
    _dateString = _formatVietnameseDate(DateTime.now());
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    if (!mounted) return;

    if (widget.initialMessage != null) {
      print("➡️ App mở từ terminated state bằng notification");

      // Điều hướng thẳng sang bài viết (webview)
      NotificationService.instance.navigateToArticleDetail(
        widget.initialMessage!.data,
      );
    } else {
      // Không có notification → vào app bình thường
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WidgetTree()),
      );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
