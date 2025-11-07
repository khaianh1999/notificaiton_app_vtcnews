import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notification_vtcnews/data/models/task_mode.dart';
import 'package:notification_vtcnews/views/widgets/add_job_detail.dart';
import 'package:notification_vtcnews/views/widgets/task_detaildialong.dart';
import 'package:notification_vtcnews/views/widgets/task_item_widget.dart';
import 'package:notification_vtcnews/data/repositories/add_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum ViewMode { my, department, company }

class MyGroup extends StatefulWidget {
  const MyGroup({super.key});

  @override
  State<MyGroup> createState() => _MyGroupState();
}

class _MyGroupState extends State<MyGroup> with TickerProviderStateMixin {
  final List<TaskModel> _tasks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  TaskFilter _filter = TaskFilter.all;
  final ScrollController _filterScrollController = ScrollController();
  int? _selectedMonth;
  int? _selectedYear;
  final TextEditingController _emailController = TextEditingController();
  String? _savedEmail;
  bool _isLoading = false;
  ViewMode _viewMode = ViewMode.my; // mặc định: của tôi

  static const _red = Color(0xFFA2171C);

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    if (mounted) {
      setState(() {
        _savedEmail = email;
        _emailController.text = email ?? '';
      });
      await _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (_savedEmail == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      int? departmentId = prefs.getInt("departmentId");
      final email = prefs.getString("user_email");
      String url = "";

      if (_viewMode == ViewMode.my) {
        url =
            "https://work.vtcnews.vn/task/GetTasksByDepartment?email=$email&departmentId=$departmentId&month=$_selectedMonth&year=$_selectedYear";
      } else if (_viewMode == ViewMode.department) {
        url =
            "https://work.vtcnews.vn/task/GetTasksByDepartment?departmentId=$departmentId&month=$_selectedMonth&year=$_selectedYear";
      } else {
        url =
            "https://work.vtcnews.vn/task/GetTasksByDepartment?departmentId=&month=$_selectedMonth&year=$_selectedYear";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && mounted) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> tasksList = jsonData['data'];
          setState(() {
            _tasks
              ..clear()
              ..addAll(tasksList.map((json) => TaskModel.fromJson(json)));
          });
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải công việc: $e')));
        setState(() => _tasks.clear());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> filtered = _tasks;
    switch (_filter) {
      case TaskFilter.all:
        break;
      case TaskFilter.todo:
        filtered = filtered.where((t) => t.status == TaskStatus.todo).toList();
        break;
      case TaskFilter.inProgress:
        filtered =
            filtered.where((t) => t.status == TaskStatus.inProgress).toList();
        break;
      case TaskFilter.done:
        filtered = filtered.where((t) => t.status == TaskStatus.done).toList();
        break;
      case TaskFilter.test:
        filtered = filtered.where((t) => t.status == TaskStatus.test).toList();
        break;
      case TaskFilter.completed:
        filtered =
            filtered.where((t) => t.status == TaskStatus.completed).toList();
        break;
      case TaskFilter.reject:
        filtered =
            filtered.where((t) => t.status == TaskStatus.reject).toList();
        break;
      case TaskFilter.pending:
        filtered =
            filtered.where((t) => t.status == TaskStatus.pending).toList();
        break;
    }
    return filtered;
  }

  void _scrollToSelectedFilter(TaskFilter filter) {
    if (_filterScrollController.hasClients) {
      const itemWidth = 90.0;
      final index = TaskFilter.values.indexOf(filter);
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset =
          (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _filterScrollController.animateTo(
        targetOffset.clamp(0, _filterScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.decelerate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Column(
                  children: [
                    // --- CHỌN THÁNG / NĂM ---
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final selectedMonth = await showDialog<int>(
                                context: context,
                                builder: (context) => _buildMonthDialog(),
                              );
                              if (selectedMonth != null && mounted) {
                                setState(() {
                                  _selectedMonth = selectedMonth;
                                  _filter = TaskFilter.all;
                                });
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) =>
                                      _scrollToSelectedFilter(TaskFilter.all),
                                );
                                await _loadTasks();
                              }
                            },
                            child: _buildMonthButton(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final selectedYear = await showDialog<int>(
                                context: context,
                                builder: (context) => _buildYearDialog(),
                              );
                              if (selectedYear != null && mounted) {
                                setState(() {
                                  _selectedYear = selectedYear;
                                  _filter = TaskFilter.all;
                                });
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) =>
                                      _scrollToSelectedFilter(TaskFilter.all),
                                );
                                await _loadTasks();
                              }
                            },
                            child: _buildYearButton(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- FILTER TRẠNG THÁI ---
                    SizedBox(
                      height: 65,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _filterScrollController,
                        child: Row(
                          children: [
                            _buildStatCard(
                              'Tất cả',
                              _tasks.length,
                              Colors.black,
                              TaskFilter.all,
                            ),
                            _buildStatCard(
                              'Chờ',
                              _tasks
                                  .where((t) => t.status == TaskStatus.todo)
                                  .length,
                              Colors.grey.shade600,
                              TaskFilter.todo,
                            ),
                            _buildStatCard(
                              'Đang làm',
                              _tasks
                                  .where(
                                    (t) => t.status == TaskStatus.inProgress,
                                  )
                                  .length,
                              Colors.blue,
                              TaskFilter.inProgress,
                            ),
                            _buildStatCard(
                              'Đã làm',
                              _tasks
                                  .where((t) => t.status == TaskStatus.done)
                                  .length,
                              Colors.green.shade600,
                              TaskFilter.done,
                            ),
                            _buildStatCard(
                              'Kiểm thử',
                              _tasks
                                  .where((t) => t.status == TaskStatus.test)
                                  .length,
                              Colors.purple.shade600,
                              TaskFilter.test,
                            ),
                            _buildStatCard(
                              'Hoàn thành',
                              _tasks
                                  .where(
                                    (t) => t.status == TaskStatus.completed,
                                  )
                                  .length,
                              Colors.green.shade800,
                              TaskFilter.completed,
                            ),
                            _buildStatCard(
                              'Từ chối',
                              _tasks
                                  .where((t) => t.status == TaskStatus.reject)
                                  .length,
                              Colors.red.shade900,
                              TaskFilter.reject,
                            ),
                            _buildStatCard(
                              'Tạm hoãn',
                              _tasks
                                  .where((t) => t.status == TaskStatus.pending)
                                  .length,
                              Colors.orange.shade600,
                              TaskFilter.pending,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- 3 NÚT LỌC DỮ LIỆU ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildViewButton(
                          "Của tôi",
                          Icons.person,
                          ViewMode.my,
                          Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        _buildViewButton(
                          "Phòng tôi",
                          Icons.group,
                          ViewMode.department,
                          Colors.green,
                        ),
                        const SizedBox(width: 10),
                        _buildViewButton(
                          "Cơ quan",
                          Icons.apartment,
                          ViewMode.company,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    filteredTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskItem(
                              key: ValueKey(task.id),
                              task: task,
                              onTap: () => _openLink(task.id),
                            );
                          },
                        ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => showAddTaskSheet(context, _loadTasks),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ==== Các Widget phụ ====

  Widget _buildViewButton(
    String text,
    IconData icon,
    ViewMode mode,
    Color color,
  ) {
    final bool selected = _viewMode == mode;
    return ElevatedButton.icon(
      onPressed: () async {
        if (_viewMode != mode) {
          setState(() => _viewMode = mode);
          await _loadTasks();
        }
      },
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    Color color,
    TaskFilter filter,
  ) {
    final bool selected = _filter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = filter;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToSelectedFilter(_filter),
          );
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Card(
          elevation: selected ? 3 : 1,
          color: selected ? Colors.green : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AlertDialog _buildMonthDialog() {
    return AlertDialog(
      title: const Text(
        'Chọn tháng',
        style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      content: SizedBox(
        width: 300,
        height: 250,
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(12, (index) {
            final month = index + 1;
            return GestureDetector(
              onTap: () => Navigator.pop(context, month),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      month == _selectedMonth
                          ? Colors.red.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Center(
                  child: Text(
                    '$month',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  AlertDialog _buildYearDialog() {
    return AlertDialog(
      title: const Text(
        'Chọn năm',
        style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      content: SizedBox(
        width: 300,
        height: 200,
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(5, (index) {
            final year = DateTime.now().year + index;
            return GestureDetector(
              onTap: () => Navigator.pop(context, year),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      year == _selectedYear
                          ? Colors.red.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Center(
                  child: Text(
                    '$year',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildMonthButton() {
    return _buildSelectorButton(Icons.calendar_month, 'Tháng $_selectedMonth');
  }

  Widget _buildYearButton() {
    return _buildSelectorButton(Icons.calendar_today, 'Năm $_selectedYear');
  }

  Widget _buildSelectorButton(IconData icon, String text) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Chưa có công việc nào',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    final password = prefs.getString("user_password");

    final encodedEmail = Uri.encodeComponent(email ?? '');
    final encodedPassword = Uri.encodeComponent(password ?? '');
    final url =
        "https://work.vtcnews.vn/Task/Details/$id?email=$encodedEmail&password=$encodedPassword";
    print(url);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể mở link: $url")));
    }
  }

  void showAddTaskSheet(
    BuildContext context,
    Future<void> Function() onTaskAdded,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTaskForm(onTaskAdded: onTaskAdded),
    );
  }
}
