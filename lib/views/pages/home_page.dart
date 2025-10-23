import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notification_vtcnews/data/models/home_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:notification_vtcnews/font_size_provider.dart';
import 'package:notification_vtcnews/data/notifiers.dart';
import 'package:notification_vtcnews/notification_service.dart';

class HomePage extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const HomePage({super.key, this.initialMessage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class NewsImageCache {
  static const key = 'newsImages';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 500,
    ),
  );
}

/// Model cho notification item


class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  static const _red = Color(0xFFA2171C);

  final TextEditingController _emailController = TextEditingController();
  String? _savedEmail;
  bool _isSubmitting = false;

  // Danh sách thông báo
  List<NotificationItem> _notifications = [];
  int _currentPage = 1;
  bool _isLoading = false;
  int _total = 0; // tổng số bản ghi từ API

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
      if (email != null) {
        _fetchNotifications(reset: true);
      }
    }
  }

  Future<void> _saveEmail(String email, int departmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_email", email);
    await prefs.setInt("departmentId", departmentId);
    setState(() {
      _savedEmail = email;
    });
    _fetchNotifications(reset: true);
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
      final data = await NotificationService.instance.sendTokenToServer(email);

      if (data != null && data["success"] == true) {
        await _saveEmail(email, data["departmentId"]);
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

  /// Hàm gọi API lấy danh sách thông báo
  Future<void> _fetchNotifications({bool reset = false}) async {
    if (_savedEmail == null) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = reset ? 1 : _currentPage;
      final url =
          "https://work.vtcnews.vn/Notification/GetUserNotifications?email=$_savedEmail&page=$page";
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);

        if (jsonData["success"] == true) {
          final List data = jsonData["data"] ?? [];
          final items = data.map((e) => NotificationItem.fromJson(e)).toList();

          setState(() {
            if (reset) {
              _notifications = List<NotificationItem>.from(items);
              _currentPage = 1;
            } else {
              _notifications.addAll(List<NotificationItem>.from(items));
            }

            _total = jsonData["total"] ?? _total;
            if (items.isNotEmpty) _currentPage++;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Hàm mở link bằng trình duyệt
  Future<void> _openLink(String link) async {
    final url = "https://work.vtcnews.vn$link";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể mở link: $url")));
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
                ? _buildEmailInput()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmailDisplay(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildNotificationList()),
                    if (_notifications.length < _total)
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : () => _fetchNotifications(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                  : const Text("Xem thêm"),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  /// Widget nhập email khi chưa có
  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nhập email để nhận thông báo:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  /// Widget hiển thị email hiện tại + nút đổi
  Widget _buildEmailDisplay() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Email: $_savedEmail",
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _savedEmail = null;
              _emailController.text = "";
              _notifications.clear();
              _total = 0;
            });
          },
          child: const Text("Đổi", style: TextStyle(color: _red)),
        ),
      ],
    );
  }

  /// Widget hiển thị danh sách thông báo
  Widget _buildNotificationList() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text("Không có thông báo nào"));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchNotifications(reset: true),
      child: Stack(
        children: [
          ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final item = _notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.message),
                      Text(
                        "Task: ${item.titleTask}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Ngày: ${item.createdAt}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _openLink(item.link),
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: FloatingActionButton.small(
              heroTag: "refreshBtn",
              backgroundColor: Colors.white,
              onPressed: () => _fetchNotifications(reset: true),
              child: const Icon(Icons.refresh, color: Colors.black54, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
