class Comment {
  final String id;
  final String aspirationId;
  final String userId;
  final String userName;
  final String userRole;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.aspirationId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      aspirationId: json['aspiration_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Pengguna',
      userRole: json['user_role'] ?? 'Mahasiswa',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aspiration_id': aspirationId,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
