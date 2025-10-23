import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_vtcnews/data/models/task_mode.dart';
import 'package:uuid/uuid.dart';

class AddTaskDialog extends StatefulWidget {
  final void Function(TaskModel) onAddTask;

  const AddTaskDialog({super.key, required this.onAddTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TaskStatus _selectedStatus = TaskStatus.pending;
  bool _isSaving = false;

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
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.red),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                ), // Tăng fontSize
              ),
            ),
            child: child!,
          ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập tiêu đề!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description:
          _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
      date: _selectedDate,
      status: _selectedStatus,
    );

    widget.onAddTask(newTask);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã thêm "${newTask.title}"'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicTextColor = isDarkMode ? Colors.white : Colors.black;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextField(
                controller: _titleController,
                autofocus: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề *',
                  labelStyle: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title, size: 30),
                  errorText:
                      _titleController.text.trim().isEmpty ? 'Bắt buộc' : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Date Field
              ListTile(
                title: Text(
                  'Ngày',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    color: dynamicTextColor,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    color: dynamicTextColor,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, size: 28),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextField(
                controller: _descriptionController,
                maxLines: 8,
                minLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  labelStyle: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description, size: 30),
                  hintText: 'Nhập mô tả chi tiết công việc...',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),

              // Status Field
              DropdownButtonFormField<TaskStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  labelStyle: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.info, size: 30),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                items:
                    TaskStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              {
                                TaskStatus.todo: 'Chờ xử lý',
                                TaskStatus.inProgress: 'Đang làm',
                                TaskStatus.done: 'Đã làm',
                                TaskStatus.test: 'Kiểm thử',
                                TaskStatus.completed: 'Hoàn thành',
                                TaskStatus.reject: 'Từ chối',
                                TaskStatus.pending: 'Tạm hoãn',
                              }[status]!,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                color: dynamicTextColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                size: 26,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
              ),
              label: Text(
                'Hủy',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTask,
              icon:
                  _isSaving
                      ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      )
                      : Icon(
                        Icons.save,
                        size: 26,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
              label: Text(
                _isSaving ? 'Đang lưu...' : 'Thêm công việc',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[700]!
                        : Colors.red.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
