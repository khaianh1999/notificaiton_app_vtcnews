enum TaskFilter {
  all,
  todo,
  inProgress,
  done,
  test,
  completed,
  reject,
  pending
}


enum TaskStatus {
  all,
  todo,
  inProgress,
  done,
  test,
  completed,
  reject,
  pending
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TaskStatus status;
  final String? assignedTo;
  final String? createdBy;
  final int? point;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.status,
    this.assignedTo,
    this.createdBy,
    this.point,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TaskStatus? status,
    String? assignedTo,
    String? createdBy,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      point: point ?? this.point,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'status': status.toString(),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'point': point,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['EndDate'] as String;
    final milliseconds = int.parse(dateStr.replaceAll(RegExp(r'[^0-9]'), ''));

    final statusMap = {
      0: TaskStatus.todo,
      1: TaskStatus.inProgress,
      2: TaskStatus.done,
      3: TaskStatus.test,
      4: TaskStatus.completed,
      5: TaskStatus.reject,
      6: TaskStatus.pending,
    };
    final status = statusMap[json['Status']] ?? TaskStatus.pending;

    return TaskModel(
      id: json['ID'].toString(),
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(milliseconds),
      status: status,
      assignedTo: json['AssignedTo'] ?? '',
      createdBy: json['CreatedByName'] ?? '',
      point: json['Point'] ?? '',
    );
  }
}