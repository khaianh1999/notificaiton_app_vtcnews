import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_vtcnews/data/models/task_mode.dart';

class TaskItem extends StatelessWidget {
  final TaskModel task;
  // final void Function(TaskStatus) onChangeStatus; // Thay onToggle thành onChangeStatus
  // final VoidCallback onDelete;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.task,
    // required this.onChangeStatus,
    // required this.onDelete,
    required this.onTap,
  });

  // Hàm ánh xạ trạng thái sang biểu tượng và màu sắc
  Widget _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.all:
        return Icon(Icons.all_inclusive, color: Colors.grey, size: 20);
      case TaskStatus.todo:
        return Icon(Icons.hourglass_empty, color: Colors.grey, size: 20);
      case TaskStatus.inProgress:
        return Icon(Icons.work, color: Colors.blue, size: 20);
      case TaskStatus.done:
        return Icon(Icons.done, color: Colors.green, size: 20);
      case TaskStatus.test:
        return Icon(Icons.bug_report, color: Colors.purple, size: 20);
      case TaskStatus.completed:
        return Icon(Icons.check_circle, color: Colors.green.shade700, size: 20);
      case TaskStatus.reject:
        return Icon(Icons.cancel, color: Colors.red, size: 20);
      case TaskStatus.pending:
        return Icon(Icons.pause, color: Colors.orange, size: 20);
    }
  }

  // Hàm trả về màu tương ứng với trạng thái
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.all:
        return Colors.grey;
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.test:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green.shade700;
      case TaskStatus.reject:
        return Colors.red;
      case TaskStatus.pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (task.status) {
      case TaskStatus.all:
        return 'Tất cả';
      case TaskStatus.todo:
        return 'Chờ xử lý';
      case TaskStatus.inProgress:
        return 'Đang làm';
      case TaskStatus.done:
        return 'Đã làm';
      case TaskStatus.test:
        return 'Kiểm thử';
      case TaskStatus.completed:
        return 'Hoàn thành';
      case TaskStatus.reject:
        return 'Từ chối';
      case TaskStatus.pending:
        return 'Tạm hoãn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 1,
      color: Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              // GestureDetector(
              //   onTap: () => onChangeStatus(task.status == TaskStatus.completed
              //       ? TaskStatus.pending
              //       : TaskStatus.completed), // Chuyển đổi giữa Hoàn thành và Chờ xử lý
              //   child: _getStatusIcon(),
              // ),
              // const SizedBox(width: 8),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        // decoration: task.status == TaskStatus.completed
                        //     ? TextDecoration.lineThrough
                        //     : null,
                        color: Colors.black,
                        // color: task.status == TaskStatus.completed
                        //     ? Colors.black
                        //     : null,
                      ),
                    ),
                    // if (task.description != null &&
                    //     task.description!.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4),
                    //     child: Text(
                    //       task.description!,
                    //       style: TextStyle(
                    //         fontSize: 18,
                    //         color: Colors.grey[600],
                    //       ),
                    //       maxLines: 2,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //   ),

                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Thực hiện : ${task.assignedTo!} ',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Điểm : ${task.point}',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            'Trạng thái: ${_getStatusText()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(task.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Kết thúc: ${DateFormat('dd/MM/yyyy').format(task.date)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          // color: task.status == TaskStatus.completed
                          //     ? Colors.grey[500]
                          //     : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              // if (task.status != TaskStatus.completed)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

              // IconButton(
              //   icon: const Icon(Icons.delete, color: Colors.red),
              //   onPressed: onDelete,
              //   padding: EdgeInsets.zero,
              //   constraints: const BoxConstraints(),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
