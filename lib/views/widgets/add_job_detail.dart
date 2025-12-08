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
  bool _isLoadingUsers = false;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;

  int selectedStatus = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  String? email = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadSavedEmail();
    await _fetchUsers();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString("user_email") ?? "";
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(
        Uri.parse('https://work.vtcnews.vn/User/GetUser'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      } else {
        debugPrint('Lỗi tải danh sách người dùng: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách người dùng: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final DateTime now = DateTime.now();

    // --- Xác định các mốc giới hạn ---
    DateTime initialDate =
        (isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now));

    DateTime firstDate =
        isStart ? DateTime(2020) : (_startDate ?? DateTime(2020));

    DateTime lastDate = DateTime(2030);

    // --- Nếu initialDate < firstDate => gán lại để tránh crash ---
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.red,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // 👇 Nếu startDate > endDate => reset endDate
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  bool _validateBeforeSubmit() {
    if (_selectedUser == null) {
      _showSnack('Vui lòng chọn người thực hiện');
      return false;
    }
    if (_startDate == null) {
      _showSnack('Vui lòng chọn ngày bắt đầu');
      return false;
    }
    if (_endDate == null) {
      _showSnack('Vui lòng chọn ngày kết thúc');
      return false;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showSnack('Ngày kết thúc phải sau ngày bắt đầu');
      return false;
    }
    if (email == null || email!.isEmpty) {
      _showSnack('Không tìm thấy email người tạo');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addTask() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (!_validateBeforeSubmit()) return;

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('https://work.vtcnews.vn/Task/CreateTask').replace(
        queryParameters: {
          'email': email,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'userId': _selectedUser!["UserId"].toString(),
          'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
          'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
          'point': pointCtrl.text.trim(),
          'status': selectedStatus.toString(),
          'type': '1',
        },
      );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            _showSnack('Thêm công việc thành công');
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
      if (mounted) _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const statusLabels = ['Chờ', 'Đang làm', 'Đã làm', 'Kiểm thử'];
    const statusValues = [0, 1, 2, 3];

    // 👇 Bọc toàn bộ trong GestureDetector để bấm ra ngoài input ẩn bàn phím
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        reverse: true, // giúp cuộn tự động khi bàn phím mở
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 8,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header + nút đóng ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thêm công việc mới',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                decoration: _inputDecoration('Tiêu đề công việc'),
                textInputAction: TextInputAction.next,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
              ),
              const SizedBox(height: 16),

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

              _buildDateField('Ngày bắt đầu', _startDate, true),
              const SizedBox(height: 16),
              _buildDateField('Ngày kết thúc', _endDate, false),
              const SizedBox(height: 16),

              if (_isLoadingUsers)
                const Center(child: CircularProgressIndicator())
              else
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
                      (user) =>
                          '${user["UserName"]} - ${user["DepartmentName"]}',
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: _inputDecoration(
                      'Người thực hiện',
                    ),
                  ),
                  selectedItem: _selectedUser,
                  validator:
                      (val) =>
                          val == null ? 'Vui lòng chọn người thực hiện' : null,
                  onChanged: (val) => setState(() => _selectedUser = val),
                ),
              const SizedBox(height: 16),

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
                    onSelected:
                        (_) => setState(
                          () => selectedStatus = statusValues[index],
                        ),
                    selectedColor: Colors.redAccent,
                    backgroundColor: Colors.grey[200],
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected ? Colors.redAccent : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (email != null && email!.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _addTask,
                        icon:
                            _isSaving
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : const Icon(Icons.add),
                        label: Text(
                          _isSaving ? 'Đang thêm...' : 'Thêm công việc',
                        ),
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
                    ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(isStart: isStart),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: _inputDecoration(label).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.redAccent,
            ),
          ),
          controller: TextEditingController(
            text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
          ),
          validator: (v) => (date == null) ? 'Vui lòng chọn $label' : null,
          readOnly: true,
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
