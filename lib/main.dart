import 'package:flutter/material.dart';
import 'package:notification_vtcnews/data/notifiers.dart';
import 'package:notification_vtcnews/views/widget_tree.dart';
import 'package:notification_vtcnews/views/pages/splash_page.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:notification_vtcnews/font_size_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point') // 👈 bắt buộc để Android AOT không tối ưu mất hàm này
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Optional: handle data in the background
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // This part is for WebView and should be kept
    // WebView.platform = SurfaceAndroidWebView();
  }

  final fontSizeProvider = FontSizeProvider();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Get the initial message when the app is launched from a terminated state
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  await Future.wait([
    fontSizeProvider.loadFontSize(),
    NotificationService.instance.initLocalNotifications(),
    NotificationService.instance.requestSystemPermissions(),
    NotificationService.instance.configureFirebaseForegroundPresentation(),
    NotificationService.instance.bindMessageHandlers(),
  ]);
  NotificationService.instance.getToken().then((token) {
    if (token != null) {
      print("🔑 FCM Token: $token");
      FirebaseMessaging.instance.subscribeToTopic("notification_work");
    }
    NotificationService.instance.listenTokenRefresh((t) async {
      await FirebaseMessaging.instance.subscribeToTopic("notification_work");

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("user_email");

      if (email != null && email.isNotEmpty) {
        print("🔄 Token refresh → update server for $email");
        await NotificationService.instance.sendTokenToServer(email);
      } else {
        print("ℹ️ Token refresh but no saved email");
      }
    });
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => fontSizeProvider,
      // Pass the initial message to MyApp
      child: MyApp(initialMessage: initialMessage),
    ),
  );
}

class MyApp extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const MyApp({super.key, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkModeNotifier, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Vtcnews',
          theme: ThemeData(
            brightness: isDarkModeNotifier ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.blue,
          ),
          // Pass the initial message to the SplashPage
          home: SplashPage(initialMessage: widget.initialMessage),
        );
      },
    );
  }
}
