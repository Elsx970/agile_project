enum AspirationStatus { pending, diperiksa, selesai }

class Aspiration {
  final String id;
  final String title;
  final String description;
  final String category;
  final String userId;
  final String userName;
  final String userRole;
  final bool isAnonymous;
  final int upvoteCount;
  final List<String> upvotedByUserIds;
  final AspirationStatus status;
  final String? imageUrl;
  final String? resolvedImageUrl;
  final DateTime createdAt;

  Aspiration({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.isAnonymous,
    required this.upvoteCount,
    required this.upvotedByUserIds,
    required this.status,
    this.imageUrl,
    this.resolvedImageUrl,
    required this.createdAt,
  });

  factory Aspiration.fromJson(Map<String, dynamic> json) {
    return Aspiration(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Lainnya',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Anonim',
      userRole: json['user_role'] ?? 'Mahasiswa',
      isAnonymous: json['is_anonymous'] == 1 || json['is_anonymous'] == true,
      upvoteCount: json['upvote_count'] ?? 0,
      upvotedByUserIds: List<String>.from(json['upvoted_by_user_ids'] ?? []),
      status: _parseStatus(json['status']),
      imageUrl: json['image_url'],
      resolvedImageUrl: json['resolved_image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'is_anonymous': isAnonymous,
      'upvote_count': upvoteCount,
      'upvoted_by_user_ids': upvotedByUserIds,
      'status': status.name,
      'image_url': imageUrl,
      'resolved_image_url': resolvedImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static AspirationStatus _parseStatus(dynamic status) {
    if (status == null) return AspirationStatus.pending;
    final s = status.toString().toLowerCase();
    if (s == 'diperiksa') return AspirationStatus.diperiksa;
    if (s == 'selesai') return AspirationStatus.selesai;
    return AspirationStatus.pending;
  }

  String get statusDisplayName {
    switch (status) {
      case AspirationStatus.pending:
        return 'Pending';
      case AspirationStatus.diperiksa:
        return 'Diperiksa';
      case AspirationStatus.selesai:
        return 'Selesai';
    }
  }

  Aspiration copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? userId,
    String? userName,
    String? userRole,
    bool? isAnonymous,
    int? upvoteCount,
    List<String>? upvotedByUserIds,
    AspirationStatus? status,
    String? imageUrl,
    String? resolvedImageUrl,
    DateTime? createdAt,
  }) {
    return Aspiration(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      upvotedByUserIds: upvotedByUserIds ?? this.upvotedByUserIds,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      resolvedImageUrl: resolvedImageUrl ?? this.resolvedImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
