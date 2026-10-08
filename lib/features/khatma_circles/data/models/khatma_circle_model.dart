class KhatmaCircleJuz {
  final String circleId;
  final int juzNumber;
  final String assignedTo;
  final String status; // 'available', 'in_progress', 'completed'
  final DateTime? completedAt;

  const KhatmaCircleJuz({
    required this.circleId,
    required this.juzNumber,
    this.assignedTo = '',
    this.status = 'available',
    this.completedAt,
  });

  bool get isAvailable => status == 'available';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  KhatmaCircleJuz copyWith({
    String? assignedTo,
    String? status,
    DateTime? completedAt,
  }) {
    return KhatmaCircleJuz(
      circleId: circleId,
      juzNumber: juzNumber,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circle_id': circleId,
      'juz_number': juzNumber,
      'assigned_to': assignedTo,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory KhatmaCircleJuz.fromMap(Map<String, dynamic> map) {
    return KhatmaCircleJuz(
      circleId: map['circle_id'] as String,
      juzNumber: map['juz_number'] as int,
      assignedTo: (map['assigned_to'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'available',
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );
  }
}

class KhatmaCircle {
  final String id;
  final String title;
  final String description;
  final String? targetDate;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<KhatmaCircleJuz> juzList;

  const KhatmaCircle({
    required this.id,
    required this.title,
    this.description = '',
    this.targetDate,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.juzList = const [],
  });

  int get completedJuzCount => juzList.where((j) => j.isCompleted).length;
  int get inProgressJuzCount => juzList.where((j) => j.isInProgress).length;
  int get availableJuzCount => juzList.where((j) => j.isAvailable).length;
  double get progressPercentage => juzList.isEmpty ? 0.0 : completedJuzCount / 30.0;

  KhatmaCircle copyWith({
    String? title,
    String? description,
    String? targetDate,
    bool? isCompleted,
    DateTime? completedAt,
    List<KhatmaCircleJuz>? juzList,
  }) {
    return KhatmaCircle(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      juzList: juzList ?? this.juzList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDate,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory KhatmaCircle.fromMap(Map<String, dynamic> map, [List<KhatmaCircleJuz> juzList = const []]) {
    return KhatmaCircle(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      targetDate: map['target_date'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      juzList: juzList,
    );
  }
}
