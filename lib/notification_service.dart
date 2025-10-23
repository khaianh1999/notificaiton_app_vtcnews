import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:notification_vtcnews/views/pages/article_detail_page.dart';
import 'package:notification_vtcnews/main.dart'; // << THÊM IMPORT NÀY ĐỂ DÙNG navigatorKey
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Dùng cho thông báo quan trọng',
        importance: Importance.max,
      );

  Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_stat_notification',
    );
    const iosInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      // SỬA LẠI CALLBACK NÀY
      onDidReceiveNotificationResponse: (details) {
        print("📌 onDidReceiveNotificationResponse called");
        print("   -> details: ${details}");
        print("   -> actionId: ${details.actionId}");
        print("   -> payload: ${details.payload}");

        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            print("📬 User tapped local notification with payload: $payload");
            final data = jsonDecode(payload) as Map<String, dynamic>;
            // Gọi hàm điều hướng đã được tái cấu trúc
            navigateToArticleDetail(data);
          } catch (e) {
            print("❌ Lỗi decode payload: $e");
          }
        }
      },
    );

    await _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highChannel);
  }

  Future<void> requestSystemPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // SỬA LẠI HÀM NÀY
  Future<void> configureFirebaseForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true, // Quan trọng: Đặt là false để tránh thông báo kép
          badge: true,
          sound: true,
        );
  }

  Future<void> bindMessageHandlers() async {
    // App đang mở (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      print("📥 Foreground message received: ${msg}");
      print("📥 Foreground message received: ${msg.data}");

      // SỬA LẠI CÁCH LẤY DỮ LIỆU ĐỂ AN TOÀN HƠN
      final title = msg.data['title']?.toString();
      final body = msg.data['body']?.toString();

      // Thêm log để kiểm tra giá trị sau khi lấy
      print("   -> Extracted Title: $title");
      print("   -> Extracted Body: $body");

      // Chỉ hiển thị thông báo nếu có title và body (và không rỗng)
      if (title != null &&
          body != null &&
          title.isNotEmpty &&
          body.isNotEmpty) {
        print("   -> Conditions met. Showing local notification...");
        _fln.show(
          DateTime.now().millisecondsSinceEpoch % 2147483647,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              highChannel.id,
              highChannel.name,
              channelDescription: highChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_stat_notification',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(msg.data),
        );
      } else {
        print(
          "   -> Conditions FAILED. Title or Body is null or empty. Notification not shown.",
        );
      }
    });
    // App chạy nền (background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📬 Notification tapped from background");
      print("📌 onMessageOpenedApp called");
      print("   -> data: ${message.data}");
      print("   -> notification: ${message.notification}");
      // Gọi hàm điều hướng với message.data
      navigateToArticleDetail(message.data);
    });
  }

  void navigateToArticleDetail(Map<String, dynamic> data) async {
    print("➡️ Navigating with data: $data");

    if (data.containsKey('link')) {
      final link = data['link']?.toString() ?? '';
      if (link.isNotEmpty) {
        final uri = Uri.parse(link);
        try {
          final success = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!success) {
            print("❌ Không mở được link (launchUrl trả về false): $link");
          }
        } catch (e) {
          print("❌ Exception khi mở link: $e");
        }
      } else {
        print("⚠️ data['link'] rỗng");
      }
    } else {
      print("⚠️ Không có trường 'link' trong data");
    }
  }

  // Các hàm còn lại giữ nguyên
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
  void listenTokenRefresh(void Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen(onRefresh);
  }

  Future<Map<String, dynamic>?> sendTokenToServer(String email) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print("⚠️ Không lấy được FCM token");
        return null;
      }

      final url = Uri.parse("https://work.vtcnews.vn/User/UpdateTokenDevice");

      final body = {"email": email, "token": fcmToken};

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["success"] == true) {
          print("✅ ${data["message"]}");
          return data;
        } else {
          print("⚠️ ${data["message"]}");
          return null;
        }
      } else {
        print("⚠️ Lỗi HTTP: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception khi gửi email/token: $e");
      return null;
    }
  }
}
