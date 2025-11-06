import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTaskForm extends StatefulWidget {
  final Future<void> Function() onTaskAdded;

  const AddTaskForm({super.key, required this.onTaskAdded});

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final pointCtrl = TextEditingController();
  bool _isSaving = false;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;

  int selectedStatus = 1;

  DateTime? _startDate;
  DateTime? _endDate;
  String? email = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString("user_email");
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://work.vtcnews.vn/User/GetUser'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách người dùng: $e');
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _addTask() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người phụ trách')),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final uri = Uri.parse('https://work.vtcnews.vn/Task/CreateTask').replace(
        queryParameters: {
          'email': email,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'userId': _selectedUser!["UserId"].toString(),
          'startDate':
              _startDate != null
                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                  : '',
          'endDate':
              _endDate != null
                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                  : '',
          'point': pointCtrl.text.trim(),
          'status': selectedStatus.toString(),
          'type': '1',
        },
      );

      final response = await http.post(uri);
      print(uri);
      print(response.statusCode);
      print(jsonDecode(response.body));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm công việc thành công')),
            );
            await widget.onTaskAdded();
            Navigator.pop(context);
          }
        } else {
          throw Exception(data['message'] ?? 'Thêm thất bại');
        }
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách trạng thái
    const List<String> statusLabels = [
      'Chờ',
      'Đang làm',
      'Đã làm',
      'Kiểm thử',
      'Hoàn thành',
      'Từ chối',
      'Tạm hoãn',
    ];
    const List<int> statusValues = [1, 2, 3, 4, 5, 6, 7];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Thêm công việc mới',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // TIÊU ĐỀ
              TextFormField(
                controller: titleCtrl,
                decoration: _inputDecoration('Tiêu đề công việc'),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
              ),
              const SizedBox(height: 16),

              // MÔ TẢ
              TextFormField(
                controller: descCtrl,
                decoration: _inputDecoration('Mô tả công việc'),
                maxLines: 3,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập mô tả'
                            : null,
              ),
              const SizedBox(height: 16),

              // ĐIỂM
              TextFormField(
                controller: pointCtrl,
                decoration: _inputDecoration('Điểm'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập điểm'
                            : null,
              ),
              const SizedBox(height: 16),

              // NGÀY BẮT ĐẦU
              GestureDetector(
                onTap: () => _selectStartDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration('Ngày bắt đầu').copyWith(
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.red,
                      ),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          _startDate != null
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NGÀY KẾT THÚC
              GestureDetector(
                onTap: () => _selectEndDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration('Ngày kết thúc').copyWith(
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.red,
                      ),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          _endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NGƯỜI PHỤ TRÁCH
              DropdownSearch<Map<String, dynamic>>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Tìm tên hoặc phòng ban...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                items: _users,
                itemAsString:
                    (user) => '${user["UserName"]} - ${user["DepartmentName"]}',
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: _inputDecoration('Người phụ trách'),
                ),
                selectedItem: _selectedUser,
                onChanged: (val) => setState(() => _selectedUser = val),
                dropdownBuilder: (context, selectedItem) {
                  if (selectedItem == null)
                    return const Text('Chọn người phụ trách');
                  return Text(
                    '${selectedItem["UserName"]} - ${selectedItem["DepartmentName"]}',
                    style: const TextStyle(color: Colors.black87),
                  );
                },
              ),
              const SizedBox(height: 16),

              // TRẠNG THÁI - ĐẸP HƠN, MƯỢT HƠN
              // === THAY TỪ ĐÂY ===
              const Text(
                'Trạng thái công việc',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(statusLabels.length, (index) {
                  final bool isSelected = selectedStatus == statusValues[index];
                  return ChoiceChip(
                    label: Text(
                      statusLabels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedStatus = statusValues[index];
                      });
                    },
                    selectedColor: Colors.red,
                    backgroundColor: Colors.grey[200],
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.red : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }),
              ),

              const SizedBox(height: 20),

              // === ĐẾN ĐÂY ===
              const SizedBox(height: 24),

              // NÚT THÊM
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addTask,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.add),
                label: Text(_isSaving ? 'Đang thêm...' : 'Thêm công việc'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
