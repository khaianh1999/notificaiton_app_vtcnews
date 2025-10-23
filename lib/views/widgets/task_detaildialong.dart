import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:notification_vtcnews/data/models/task_mode.dart';
import 'package:notification_vtcnews/data/services/edit_task_screen.dart';

class TaskDetailDialog extends StatefulWidget {
  final TaskModel task;
  final void Function(TaskModel) onUpdateTask;
  final void Function(TaskStatus) onChangeStatus;
  // final VoidCallback onDeleteTask;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onChangeStatus,
    //required this.onDeleteTask,
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  bool _isEditing = false;
  bool _showDeleteConfirm = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskStatus _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedDate = widget.task.date;
    _selectedStatus = widget.task.status; // Đảm bảo trạng thái luôn hợp lệ
    if (kDebugMode) {
      print("Initial status: $_selectedStatus");
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _saveTask();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Vui lòng nhập tiêu đề!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedTask = widget.task.copyWith(
      title: title,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      date: _selectedDate,
      status: _selectedStatus,
    );

    widget.onUpdateTask(updatedTask);
    
    setState(() => _isEditing = false);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã cập nhật "${updatedTask.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    setState(() => _isSaving = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blue),
        ),
        child: child!,
      ),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmDelete() {
    setState(() => _showDeleteConfirm = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showDeleteConfirm = false);
    });
  }

  // void _handleDelete() {
  //   widget.onDeleteTask();
  //   Navigator.of(context).pop();
  // }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa map với giá trị mặc định
    final statusMap = {
      TaskStatus.pending: 'Chờ xử lý',
      TaskStatus.inProgress: 'Đang làm',
      TaskStatus.done: 'Đã làm',
      TaskStatus.test: 'Kiểm thử',
      TaskStatus.completed: 'Hoàn thành',
      TaskStatus.reject: 'Từ chối',
      TaskStatus.pending: 'Tạm hoãn',
    };

    final iconMap = {
      TaskStatus.pending: Icons.hourglass_empty,
      TaskStatus.inProgress: Icons.work,
      TaskStatus.done: Icons.done,
      TaskStatus.test: Icons.bug_report,
      TaskStatus.completed: Icons.check_circle,
      TaskStatus.reject: Icons.cancel,
      TaskStatus.pending: Icons.pause,
    };

    final colorMap = {
      TaskStatus.todo: Colors.grey,
      TaskStatus.inProgress: Colors.blue,
      TaskStatus.done: Colors.green,
      TaskStatus.test: Colors.purple,
      TaskStatus.completed: Colors.green.shade700,
      TaskStatus.reject: Colors.red,
      TaskStatus.pending: Colors.orange,
    };

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 400, // Đặt chiều rộng tối thiểu cố định
          maxWidth: 500, // Giới hạn chiều rộng tối đa
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  // Container(
                  //   padding: const EdgeInsets.all(8),
                  //   decoration: BoxDecoration(
                  //     color: widget.task.status == TaskStatus.completed ? Colors.green.shade100 : Colors.blue.shade100,
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Icon(
                  //     widget.task.status == TaskStatus.completed ? Icons.check_circle : Icons.task,
                  //     color: widget.task.status == TaskStatus.completed ? Colors.green.shade700 : Colors.blue.shade700,
                  //     size: 28,
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isEditing ? 'Chỉnh sửa task' : widget.task.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          _isEditing
                              ? 'Đang chỉnh sửa'
                              : DateFormat('dd/MM/yyyy HH:mm').format(widget.task.date),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
      await showDialog(
        context: context,
        builder: (context) {
          return Dialog.fullscreen(
            child: TaskEditScreen( // Điều hướng sang chỉnh sửa full màn hình
              task: widget.task,
              onSave: (updatedTask) {
                widget.onUpdateTask(updatedTask);
              },
            ),
          );
        },
        
      );
    },
                      tooltip: 'Chỉnh sửa',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Card(
                elevation: _isEditing ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? TextField(
                          controller: _titleController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Tiêu đề *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.title),
                            errorText: _titleController.text.trim().isEmpty ? 'Bắt buộc' : null,
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.title, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(widget.task.title, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: _isEditing ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? ListTile(
                          title: const Text('Ngày'),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectDate,
                        )
                      : Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    DateFormat('dd/MM/yyyy \'lúc\' HH:mm').format(widget.task.date),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: _isEditing ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Mô tả (tùy chọn)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.description),
                            hintText: 'Nhập mô tả chi tiết...',
                          ),
                          style: const TextStyle(fontSize: 14),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (widget.task.description != null && widget.task.description!.isNotEmpty)
                              Text(
                                widget.task.description!,
                                style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[700]),
                              )
                            else
                              Text(
                                'Không có mô tả',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: _isEditing ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? DropdownButtonFormField<TaskStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Trạng thái',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.info),
                          ),
                          items: TaskStatus.values
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(statusMap[status] ?? 'Không xác định'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        )
                      : Row(
                          children: [
                            Icon(
                              iconMap[widget.task.status] ?? Icons.help,
                              color: colorMap[widget.task.status] ?? Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    statusMap[widget.task.status] ?? 'Không xác định',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorMap[widget.task.status] ?? Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: () {
              setState(() => _isEditing = false);
              _titleController.text = widget.task.title;
              _descriptionController.text = widget.task.description ?? '';
              _selectedDate = widget.task.date;
              _selectedStatus = widget.task.status;
            },
            icon: const Icon(Icons.close),
            label: const Text('Hủy'),
          ),
        if (_isEditing)
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _toggleEditMode,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
          )
        else ...[
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Đóng'),
          ),
          if (widget.task.status != TaskStatus.completed)
            ElevatedButton.icon(
              onPressed: () {
                widget.onChangeStatus(TaskStatus.completed);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Hoàn thành'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            ),
          // _showDeleteConfirm
          //     ? ElevatedButton.icon(
          //         onPressed: _handleDelete,
          //         icon: const Icon(Icons.delete_forever, color: Colors.white),
          //         label: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          //         style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
          //       )
          //     : IconButton(
          //         onPressed: _confirmDelete,
          //         icon: const Icon(Icons.delete, color: Colors.red),
          //         tooltip: 'Xóa task',
          //       ),
        ],
      ],
    );
  }
}