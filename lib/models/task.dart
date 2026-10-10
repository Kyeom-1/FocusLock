class Task {
  final String id;
  String title;
  String description;
  String priority;
  int durationMinutes;
  DateTime? startDate;
  DateTime? deadline;
  String verificationType;
  bool completed;

  /// Download URL of the proof photo in Firebase Storage (null until a
  /// photo has been captured and uploaded).
  String? proofImageUrl;
  DateTime? completedAt;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = 'Medium',
    this.durationMinutes = 25,
    this.startDate,
    this.deadline,
    this.verificationType = 'Photo',
    this.completed = false,
    this.proofImageUrl,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'priority': priority,
    'durationMinutes': durationMinutes,
    'startDate': startDate?.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'verificationType': verificationType,
    'completed': completed,
    'proofImageUrl': proofImageUrl,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromMap(String id, Map<String, dynamic> j) => Task(
    id: id,
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    priority: j['priority'] ?? 'Medium',
    durationMinutes: j['durationMinutes'] ?? 25,
    startDate: j['startDate'] == null ? null : DateTime.tryParse(j['startDate']),
    deadline: j['deadline'] == null ? null : DateTime.tryParse(j['deadline']),
    verificationType: j['verificationType'] ?? 'Photo',
    completed: j['completed'] ?? false,
    proofImageUrl: j['proofImageUrl'],
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.tryParse(j['completedAt']),
    createdAt: j['createdAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(j['createdAt']) ?? DateTime.now(),
  );
}
