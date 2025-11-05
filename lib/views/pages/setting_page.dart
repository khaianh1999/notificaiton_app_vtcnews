import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const _red = Color(0xFFA2171C);

  String? _savedEmail;
  String? _savedPassword;
  bool _showChangePassword = false;
  bool _isSubmitting = false;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedEmail = prefs.getString("user_email");
      _savedPassword = prefs.getString("user_password");
    });
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ mật khẩu cũ và mới"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final url = Uri.parse("https://work.vtcnews.vn/Home/ChangePass");
      final body = {
        "email": _savedEmail,
        "password": oldPassword,
        "password_new": newPassword,
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        if (jsonData["success"] == true) {
          // Lưu lại mật khẩu mới vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_password", newPassword);

          setState(() {
            _savedPassword = newPassword;
            _showChangePassword = false;
            _oldPasswordController.clear();
            _newPasswordController.clear();
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("✅ ${jsonData["message"]}")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ ${jsonData["message"] ?? "Đổi mật khẩu thất bại"}",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi server: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi đổi mật khẩu: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _savedEmail == null
                ? const Center(
                  child: Text(
                    "Bạn chưa đăng nhập. Hãy đăng nhập ở màn Home.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tài khoản: $_savedEmail",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_showChangePassword)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showChangePassword = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text("Đổi mật khẩu"),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _oldPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Nhập mật khẩu cũ",
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Nhập mật khẩu mới",
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _red,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                  child:
                                      _isSubmitting
                                          ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                          : const Text("Xác nhận đổi"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showChangePassword = false;
                                    _oldPasswordController.clear();
                                    _newPasswordController.clear();
                                  });
                                },
                                child: const Text(
                                  "Hủy",
                                  style: TextStyle(color: _red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
      ),
    );
  }
}
