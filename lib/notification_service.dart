import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:notification_vtcnews/views/pages/article_detail_page.dart';
import 'package:notification_vtcnews/main.dart'; // << THÊM IMPORT NÀY ĐỂ DÙNG navigatorKey
import 'package:shared_preferences/shared_preferences.dart';
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
    // App đang foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      print("📥 Foreground message received: ${msg.data}");

      // Lấy title + body ưu tiên msg.notification, fallback msg.data
      final title =
          msg.notification?.title ??
          msg.data['title']?.toString() ??
          'Thông báo';
      final body = msg.notification?.body ?? msg.data['body']?.toString() ?? '';

      if (title.isNotEmpty && body.isNotEmpty) {
        await _fln.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
        print("⚠️ Không có title/body, notification không được show");
      }
    });

    // Khi user tap thông báo (background hoặc terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📬 onMessageOpenedApp: ${message.data}");
      navigateToArticleDetail(message.data);
    });
  }

  void navigateToArticleDetail(Map<String, dynamic> data) async {
    print("➡️ Navigating with data: $data");

    // Kiểm tra dữ liệu
    if (!data.containsKey('link')) {
      print("⚠️ Không có key 'link' trong data");
      return;
    }

    final rawLink = data['link']?.toString() ?? '';
    if (rawLink.isEmpty) {
      print("⚠️ Link rỗng");
      return;
    }

    try {
      // Lấy email và password lưu trong SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("user_email") ?? '';
      final password = prefs.getString("user_password") ?? '';

      // ✅ Mã hóa Base64 URL Safe
      final credentials = "$email:$password";
      final encodedData = base64Url.encode(utf8.encode(credentials));

      // ✅ Tạo URL gốc (chuẩn hóa để tránh lỗi 10229)
      final link =
          rawLink.startsWith('http')
              ? rawLink
              : 'https://work.vtcnews.vn$rawLink';

      // ✅ Ghép query param data
      Uri uri;
      uri = Uri.parse('$link?data=$encodedData');

      print("🔗 Final URL: $uri");

      // ✅ Kiểm tra và mở liên kết
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!success) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      print("❌ Lỗi khi mở link: $e");
    }
  }

  // Các hàm còn lại giữ nguyên
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
  void listenTokenRefresh(void Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen(onRefresh);
  }

  Future<Map<String, dynamic>?> sendTokenToServer(
    String email,
    String password,
  ) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print("⚠️ Không lấy được FCM token");
        return null;
      }
      if (password.isEmpty) {
        print("⚠️ Vui lòng nhập mật khẩu");
        return null;
      }

      final url = Uri.parse("https://work.vtcnews.vn/User/UpdateTokenDevice");

      final body = {"email": email, "token": fcmToken, "password": password};

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
