import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_vtcnews/data/models/task_mode.dart';

class TaskEditScreen extends StatefulWidget {
  final TaskModel task;
  final void Function(TaskModel) onSave;

  const TaskEditScreen({super.key, required this.task, required this.onSave});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskStatus _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description ?? '');
    _selectedDate = widget.task.date;
    _selectedStatus = widget.task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.red),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập tiêu đề!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedTask = widget.task.copyWith(
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      date: _selectedDate,
      status: _selectedStatus,
    );

    widget.onSave(updatedTask);

    // 🟢 Delay nhẹ để đảm bảo lưu xong
    await Future.delayed(const Duration(milliseconds: 300));

    // 🛡️ Kiểm tra nếu widget còn mounted thì mới pop
    if (!mounted) return;

    // 🟢 Đóng cả TaskEditScreen và TaskDetailDialog (về MyTask)
    Navigator.of(context).pop(); // pop TaskEditScreen
    Future.microtask(() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // pop TaskDetailDialog
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final red = Colors.red.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
        centerTitle: true,
        backgroundColor: red,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 18, color: textColor),
              decoration: InputDecoration(
                labelText: 'Tiêu đề *',
                prefixIcon: Icon(Icons.title, color: red),
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              tileColor: cardColor,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(Icons.calendar_today, color: red),
              title: Text(
                'Ngày thực hiện',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: textColor),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: TextStyle(color: textColor.withOpacity(0.8)),
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit_calendar_outlined, color: red),
                onPressed: _selectDate,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 10,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                prefixIcon: Icon(Icons.description_outlined, color: red),
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                alignLabelWithHint: true,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<TaskStatus>(
              value: _selectedStatus,
              dropdownColor: cardColor,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                prefixIcon: Icon(Icons.flag, color: red),
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: red, width: 2),
                ),
              ),
              items: TaskStatus.values.map((status) {
                final map = {
                  TaskStatus.todo: 'Chờ xử lý',
                  TaskStatus.inProgress: 'Đang làm',
                  TaskStatus.done: 'Đã làm',
                  TaskStatus.test: 'Kiểm thử',
                  TaskStatus.completed: 'Hoàn thành',
                  TaskStatus.reject: 'Từ chối',
                  TaskStatus.pending: 'Tạm hoãn',
                };
                return DropdownMenuItem(
                  value: status,
                  child: Text(map[status] ?? status.name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Chỉnh Sửa',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveTask,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
