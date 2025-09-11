import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notification_vtcnews/font_size_provider.dart';
import 'package:notification_vtcnews/data/notifiers.dart';
import 'package:notification_vtcnews/data/home_cache.dart';
import 'package:notification_vtcnews/notification_service.dart';

class HomePage extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const HomePage({super.key, this.initialMessage}); // Nhận message

  @override
  State<HomePage> createState() => _HomePageState();
}

class NewsImageCache {
  static const key = 'newsImages';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      // giữ 14 ngày thay vì 7
      stalePeriod: const Duration(days: 14),
      // cho phép nhiều ảnh hơn
      maxNrOfCacheObjects: 500,
    ),
  );
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  static const _red = Color(0xFFA2171C);

  final TextEditingController _emailController = TextEditingController();
  String? _savedEmail;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

    // Nếu app mở từ terminated state bằng notification
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("➡️ Handling initial message from terminated state");
        NotificationService.instance.navigateToArticleDetail(
          widget.initialMessage!.data,
        );
      });
    }
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    if (mounted) {
      setState(() {
        _savedEmail = email;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_email", email);
    setState(() {
      _savedEmail = email;
    });
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email hợp lệ")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ok = await NotificationService.instance.sendTokenToServer(email);

      if (ok) {
        await _saveEmail(email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cập nhật token thành công!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Không tìm thấy người dùng với email này!"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi lưu email: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Provider.of<FontSizeProvider>(context).fontSize;
    super.build(context); // keep-alive

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _savedEmail == null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nhập email để nhận thông báo:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Nhập email của bạn",
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child:
                          _isSubmitting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                              : const Text("Submit"),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Email của bạn:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _savedEmail!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _savedEmail = null;
                              _emailController.text = "";
                            });
                          },
                          child: const Text(
                            "Đổi",
                            style: TextStyle(color: _red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
