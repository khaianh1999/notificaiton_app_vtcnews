import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notification_vtcnews/data/models/task_mode.dart';
import 'package:notification_vtcnews/views/widgets/task_detaildialong.dart';
import 'package:notification_vtcnews/views/widgets/task_item_widget.dart';
import 'package:notification_vtcnews/data/repositories/add_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class MyGroup extends StatefulWidget {
  const MyGroup({super.key});

  @override
  State<MyGroup> createState() => _MyGroupState();
}

class _MyGroupState extends State<MyGroup> with TickerProviderStateMixin {
  final List<TaskModel> _tasks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _listKey2 = GlobalKey<AnimatedListState>();
  TaskFilter _filter = TaskFilter.all;
  final ScrollController _filterScrollController = ScrollController();
  int? _selectedMonth;
  int? _selectedYear;
  final TextEditingController _emailController = TextEditingController();
  bool _isCompanyView = false; // false = phòng tôi, true = cơ quan
  String? _savedEmail;
  bool _isLoading = false;
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

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_email", email);
    if (mounted) {
      setState(() {
        _savedEmail = email;
      });
      await _loadTasks();
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng nhập email hợp lệ")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _saveEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu email thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi lưu email: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTasks({bool all = false}) async {
    if (_savedEmail == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      int? departmentId = prefs.getInt("departmentId");
      if (departmentId == null) {
        throw Exception("Không tìm thấy departmentId");
      }
      if (all) {
        departmentId = null;
      }

      final url =
          'https://work.vtcnews.vn/task/GetTasksByDepartment?departmentId=$departmentId&month=$_selectedMonth&year=$_selectedYear';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && mounted) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> tasksList = jsonData['data'];
          setState(() {
            _tasks.clear();
            _tasks.addAll(
              tasksList.map((json) => TaskModel.fromJson(json)).toList(),
            );
          });
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải công việc: $e')));
        setState(() {
          _tasks.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(
        _tasks.map((task) => task.toJson()).toList(),
      );
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  void _addTask(TaskModel task) {
    final insertIndex = 0;
    if (mounted) {
      setState(() {
        _tasks.insert(insertIndex, task);
        _listKey.currentState?.insertItem(
          insertIndex,
          duration: const Duration(milliseconds: 300),
        );
      });
      Future.microtask(_saveTasks);
    }
  }

  void _updateTask(TaskModel updatedTask) {
    if (mounted) {
      setState(() {
        final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _tasks.sort((a, b) => b.date.compareTo(a.date));
        }
      });
      Future.microtask(() async {
        await _saveTasks();
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật công việc'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  void _changeStatus(String taskId, TaskStatus newStatus) {
    if (mounted) {
      setState(() {
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1)
          _tasks[index] = _tasks[index].copyWith(status: newStatus);
      });
      Future.microtask(_saveTasks);
    }
  }

  Widget _buildRemovedItem(TaskModel task, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).chain(CurveTween(curve: Curves.decelerate)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: TaskItem(key: ValueKey(task.id), task: task, onTap: () {}),
        ),
      ),
    );
  }

  void _undoDelete(TaskModel task, int originalIndex) {
    if (mounted) {
      setState(() {
        _tasks.insert(originalIndex, task);
        _listKey.currentState?.insertItem(
          originalIndex,
          duration: const Duration(milliseconds: 300),
        );
      });
      Future.microtask(_saveTasks);
    }
  }

  void _showTaskDetails(TaskModel task) {
    if (!mounted || !context.mounted) return;
    showDialog(
      context: context,
      builder:
          (dialogContext) => TaskDetailDialog(
            task: task,
            onUpdateTask: _updateTask,
            onChangeStatus: (status) => _changeStatus(task.id, status),
          ),
    );
  }

  void _showAddTaskDialog() {
    if (!mounted || !context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(onAddTask: _addTask),
    );
  }

  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> filtered = _tasks;

    switch (_filter) {
      case TaskFilter.all:
        break;
      case TaskFilter.todo:
        filtered =
            filtered.where((task) => task.status == TaskStatus.todo).toList();
        break;
      case TaskFilter.inProgress:
        filtered =
            filtered
                .where((task) => task.status == TaskStatus.inProgress)
                .toList();
        break;
      case TaskFilter.done:
        filtered =
            filtered.where((task) => task.status == TaskStatus.done).toList();
        break;
      case TaskFilter.test:
        filtered =
            filtered.where((task) => task.status == TaskStatus.test).toList();
        break;
      case TaskFilter.completed:
        filtered =
            filtered
                .where((task) => task.status == TaskStatus.completed)
                .toList();
        break;
      case TaskFilter.reject:
        filtered =
            filtered.where((task) => task.status == TaskStatus.reject).toList();
        break;
      case TaskFilter.pending:
        filtered =
            filtered
                .where((task) => task.status == TaskStatus.pending)
                .toList();
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
          // === TOÀN BỘ GIAO DIỆN ===
          Column(
            children: [
              // === PHẦN CỐ ĐỊNH TRÊN CÙNG ===
              Padding(
             padding: const EdgeInsets.symmetric(horizontal: 5.0),

                child: Column(
                  children: [
                    // Chọn tháng/năm
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final selectedMonth = await showDialog<int>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text(
                                        'Chọn tháng',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                              onTap:
                                                  () => Navigator.pop(
                                                    context,
                                                    month,
                                                  ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      month == _selectedMonth
                                                          ? Colors.red
                                                              .withOpacity(0.2)
                                                          : Colors.grey
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red,
                                                    width: 0,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$month',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text(
                                            'Hủy',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (selectedMonth != null && mounted) {
                                setState(() {
                                  _selectedMonth = selectedMonth;
                                  _filter =
                                      TaskFilter.all; // ✅ reset tab về “Tất cả”
                                });
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToSelectedFilter(
                                    TaskFilter.all,
                                  ); // ✅ cuộn về tab “Tất cả”
                                });
                                await _loadTasks(all: _isCompanyView);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.1),
                                    Colors.red.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedMonth != null
                                        ? 'Tháng $_selectedMonth'
                                        : 'Chọn tháng',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final selectedYear = await showDialog<int>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text(
                                        'Chọn năm',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: 300,
                                        height: 200,
                                        child: GridView.count(
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          children: List.generate(5, (index) {
                                            final year =
                                                DateTime.now().year + index;
                                            return GestureDetector(
                                              onTap:
                                                  () => Navigator.pop(
                                                    context,
                                                    year,
                                                  ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      year == _selectedYear
                                                          ? Colors.red
                                                              .withOpacity(0.2)
                                                          : Colors.grey
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$year',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text(
                                            'Hủy',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (selectedYear != null && mounted) {
                                setState(() {
                                  _selectedYear = selectedYear;
                                  _filter =
                                      TaskFilter.all; // ✅ reset tab về “Tất cả”
                                });
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToSelectedFilter(
                                    TaskFilter.all,
                                  ); // ✅ cuộn về tab “Tất cả”
                                });
                                await _loadTasks(all: _isCompanyView);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.1),
                                    Colors.red.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedYear != null
                                        ? 'Năm $_selectedYear'
                                        : 'Chọn năm',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 7 TAB THỐNG KÊ - CUỘN NGANG
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // === Nút Phòng tôi ===
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_isCompanyView) {
                              setState(() => _isCompanyView = false);
                              await _loadTasks(all: false);
                              // if (mounted) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //       content: Text("Đang hiển thị: Phòng tôi"),
                              //     ),
                              //   );
                              // }
                            }
                          },
                          icon: Icon(
                            Icons.group,
                            color:
                                _isCompanyView ? Colors.white70 : Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            "Phòng tôi",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color:
                                  _isCompanyView
                                      ? Colors.white70
                                      : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isCompanyView
                                    ? Colors.grey.shade700
                                    : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            elevation: 0,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // === Nút Cơ quan ===
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (!_isCompanyView) {
                              setState(() => _isCompanyView = true);
                              await _loadTasks(all: true);
                              // if (mounted) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //       content: Text("Đang hiển thị: Cơ quan"),
                              //     ),
                              //   );
                              // }
                            }
                          },
                          icon: Icon(
                            Icons.apartment,
                            color:
                                _isCompanyView ? Colors.white : Colors.white70,
                            size: 18,
                          ),
                          label: Text(
                            "Cơ quan",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color:
                                  _isCompanyView
                                      ? Colors.white
                                      : Colors.white70,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isCompanyView
                                    ? Colors.green
                                    : Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // === PHẦN CUỘN: DANH SÁCH CÔNG VIỆC ===
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

          // === LOADING OVERLAY ===
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
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

  Widget _buildStatCard(
    String title,
    int count,
    Color color,
    TaskFilter filter,
  ) {
    final bool isSelected = _filter == filter;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _filter = filter;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToSelectedFilter(_filter),
            );
          });
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: Card(
          elevation: isSelected ? 3 : 1, // tăng nhẹ độ nổi nếu được chọn
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          color: isSelected ? Colors.green : Colors.white,
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
                    color: isSelected ? Colors.white : color,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
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
}
