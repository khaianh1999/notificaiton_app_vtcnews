import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notification_vtcnews/data/models/task_mode.dart';
import 'package:notification_vtcnews/views/widgets/encryption_helper.dart';
import 'package:notification_vtcnews/views/widgets/task_item_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DepartmentTaskList extends StatefulWidget {
  final int departmentId;
  final String departmentName;
  final int month;
  final int year;

  const DepartmentTaskList({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.month,
    required this.year,
  });

  @override
  State<DepartmentTaskList> createState() => _DepartmentTaskListState();
}

class _DepartmentTaskListState extends State<DepartmentTaskList> {
  bool _loading = true;
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadDepartmentTasks();
  }

  Future<void> _loadDepartmentTasks() async {
    setState(() => _loading = true);

    try {
      final url =
          "https://work.vtcnews.vn/Task/GetTasksByDepartment"
          "?departmentId=${widget.departmentId}"
          "&month=${widget.month}"
          "&year=${widget.year}";

      final rs = await http.get(Uri.parse(url));

      if (rs.statusCode == 200) {
        final jsonData = jsonDecode(rs.body);

        if (jsonData["success"] == true && jsonData["data"] != null) {
          final List list = jsonData["data"];

          setState(() {
            _tasks = list.map((e) => TaskModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải công việc: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
              : _tasks.isEmpty
              ? const Center(child: Text("Không có công việc"))
              : ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskItem(task: task, onTap: () => _openLink(task.id));
                },
              ),
    );
  }

  Future<void> _openLink(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("user_email") ?? '';
      final password = prefs.getString("user_password") ?? '';

      // ✅ Mã hóa email + password (base64 URL-safe)
      final encrypted = EncryptionHelper.encodeCredentials(email, password);
      final encodedData = Uri.encodeComponent(encrypted['vtcnews'] ?? '');

      // ✅ Tạo URL login có redirect và data
      final uri = Uri.parse(
        "https://work.vtcnews.vn/Task/Details/$id?data=$encodedData",
      );

      print("🔗 Final URL: $uri");

      // ✅ Mở URL
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
}
