import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TaskStatisticsScreen extends StatefulWidget {
  const TaskStatisticsScreen({super.key});

  @override
  State<TaskStatisticsScreen> createState() => _TaskStatisticsScreenState();
}

class _TaskStatisticsScreenState extends State<TaskStatisticsScreen> {
  bool _isLoading = false; // trạng thái đang tải dữ liệu
  int _selectedMonth = DateTime.now().month; // tháng hiện tại
  int _selectedYear = DateTime.now().year; // năm hiện tại
  List<dynamic> _departments = []; // danh sách phòng ban từ API

  @override
  void initState() {
    super.initState();
    _loadStatistics(); // khi mở màn hình -> gọi API thống kê
  }

  /// 🧩 Hàm gọi API thống kê công việc theo phòng ban
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      // URL API có truyền tham số tháng & năm
      final url =
          'https://work.vtcnews.vn/Task/GetTaskStatisticsByDepartment?month=$_selectedMonth&year=$_selectedYear';
      final response = await http.get(Uri.parse(url));

      // Nếu trả về thành công
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Kiểm tra dữ liệu có hợp lệ không
        if (jsonData["success"] == true && jsonData["data"] != null) {
          setState(() {
            _departments = jsonData["data"]; // lưu danh sách phòng ban
          });
        } else {
          throw Exception("API trả về success = false hoặc data trống");
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      // Hiển thị lỗi khi gọi API thất bại
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
      }
    } finally {
      // Kết thúc tải -> ẩn loading
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thanh tiêu đề trên cùng
      appBar: AppBar(
        title: const Text(
          "Thống kê công việc",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),

      // Nội dung chính của trang
      body: Column(
        children: [
          _buildMonthYearPicker(), // khu vực chọn tháng/năm
          Expanded(
            child: _isLoading
                // Hiển thị vòng tròn loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red))
                // Nếu không có dữ liệu
                : _departments.isEmpty
                    ? const Center(
                        child: Text(
                          "Không có dữ liệu thống kê",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      )
                    // Nếu có dữ liệu -> hiển thị dạng lưới
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _departments.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              2, // mỗi hàng có 2 phòng ban hiển thị song song
                          crossAxisSpacing: 12, // khoảng cách ngang giữa 2 cột
                          mainAxisSpacing: 12, // khoảng cách dọc
                          mainAxisExtent: 350, // chiều cao mỗi thẻ
                        ),
                        itemBuilder: (context, index) {
                          final dept = _departments[index];
                          return _buildDepartmentCard(dept);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 🏢 Xây dựng 1 card hiển thị thống kê của 1 phòng ban
  Widget _buildDepartmentCard(dynamic dept) {
    final String name = dept["DepartmentName"] ?? "Không rõ phòng";
    final int total = dept["TotalTasks"] ?? 0;
    final int todo = dept["todo"] ?? 0;
    final int inProgress = dept["inProgress"] ?? 0;
    final int done = dept["done"] ?? 0;
    final int test = dept["test"] ?? 0;
    final int completed = dept["completed"] ?? 0;
    final int reject = dept["reject"] ?? 0;
    final int pending = dept["pending"] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // bo tròn góc
        boxShadow: [
          // đổ bóng nhẹ cho đẹp
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên phòng ban
          SizedBox(
            height: 20 * 1.2 * 2, // fontSize * lineHeight * số dòng
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.red,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Các dòng thống kê chi tiết
          _buildStatLine("Tổng công việc", total, Icons.all_inclusive, Colors.black87),
          _buildStatLine("Chờ", todo, Icons.hourglass_empty, Colors.grey),
          _buildStatLine("Đang làm", inProgress, Icons.work, Colors.blue),
          _buildStatLine("Đã làm xong", done, Icons.done, Colors.green),
          _buildStatLine("Kiểm thử", test, Icons.bug_report, Colors.purple),
          _buildStatLine("Hoàn thành", completed, Icons.check_circle, Colors.teal),
          _buildStatLine("Từ chối", reject, Icons.cancel, Colors.red),
          _buildStatLine("Tạm dừng", pending, Icons.pause_circle, Colors.orange),
        ],
      ),
    );
    
  }
  Future<void> _openLink(String id) async {
    final url = "https://work.vtcnews.vn/Task/Details/$id";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể mở link: $url")));
    }
  }

  /// 📊 Xây dựng 1 dòng thống kê (label + icon + số lượng)
  Widget _buildStatLine(String label, int value, IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        // Cụm icon + nhãn (chiếm hết phần còn lại bên trái)
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis, // nếu quá dài thì "..."
                  ),
                ),
              ),
            ],
          ),
        ),

        // Số lượng bên phải — luôn canh phải
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    ),
  );
}


  /// 📅 Thanh chọn tháng / năm
  Widget _buildMonthYearPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Nút chọn tháng
          Expanded(
            flex: 1,
            child: _buildSelectButton(
              label: "Tháng $_selectedMonth",
              icon: Icons.calendar_month,
              onTap: () async {
                final selected = await _selectMonth();
                if (selected != null) {
                  setState(() => _selectedMonth = selected);
                  await _loadStatistics(); // tải lại dữ liệu sau khi chọn
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Nút chọn năm
          Expanded(
            flex: 1,
            child: _buildSelectButton(
              label: "Năm $_selectedYear",
              icon: Icons.calendar_today,
              onTap: () async {
                final selected = await _selectYear();
                if (selected != null) {
                  setState(() => _selectedYear = selected);
                  await _loadStatistics();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔘 Widget nút chọn tháng / năm có icon và hiệu ứng
  Widget _buildSelectButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔽 Popup chọn tháng
  Future<int?> _selectMonth() async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn tháng"),
        content: SizedBox(
          width: 300,
          height: 250,
          child: GridView.count(
            crossAxisCount: 4,
            children: List.generate(12, (i) {
              final m = i + 1;
              return GestureDetector(
                onTap: () => Navigator.pop(context, m),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: m == _selectedMonth
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Center(
                    child: Text(
                      "$m",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// 🔽 Popup chọn năm
  Future<int?> _selectYear() async {
    final now = DateTime.now().year;
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn năm"),
        content: SizedBox(
          width: 300,
          height: 180,
          child: GridView.count(
            crossAxisCount: 4,
            children: List.generate(6, (i) {
              final y = now - 2 + i; // hiển thị 5 năm gần nhất
              return GestureDetector(
                onTap: () => Navigator.pop(context, y),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: y == _selectedYear
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Center(
                    child: Text(
                      "$y",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
