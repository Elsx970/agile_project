class Comment {
  final String id;
  final String aspirationId;
  final String userId;
  final String userName;
  final String userRole;
  final String content;
  final String? parentId;
  final int likeCount;
  final List<String> likedByUserIds;
  final int dislikeCount;
  final List<String> dislikedByUserIds;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.aspirationId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    this.parentId,
    this.likeCount = 0,
    required this.likedByUserIds,
    this.dislikeCount = 0,
    required this.dislikedByUserIds,
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
      parentId: json['parent_id']?.toString(),
      likeCount: json['like_count'] ?? 0,
      likedByUserIds: List<String>.from(json['liked_by_user_ids'] ?? []),
      dislikeCount: json['dislike_count'] ?? 0,
      dislikedByUserIds: List<String>.from(json['disliked_by_user_ids'] ?? []),
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
      'parent_id': parentId,
      'like_count': likeCount,
      'liked_by_user_ids': likedByUserIds,
      'dislike_count': dislikeCount,
      'disliked_by_user_ids': dislikedByUserIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? aspirationId,
    String? userId,
    String? userName,
    String? userRole,
    String? content,
    String? parentId,
    int? likeCount,
    List<String>? likedByUserIds,
    int? dislikeCount,
    List<String>? dislikedByUserIds,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      aspirationId: aspirationId ?? this.aspirationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      dislikedByUserIds: dislikedByUserIds ?? this.dislikedByUserIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
