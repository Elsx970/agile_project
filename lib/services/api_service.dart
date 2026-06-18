import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/config.dart';
import '../models/user.dart';
import '../models/aspiration.dart';
import '../models/comment.dart';

class ApiService {
  // Simulated Local Database for Mock Mode (Empty for Production Setup)
  static final List<User> _mockUsers = [];
  static final List<Aspiration> _mockAspirations = [];
  static final List<Comment> _mockComments = [];


  // --- AUTHENTICATION ---

  static Future<User> login(String email, String password) async {
    // Note: Since multi-role logins are handled in AuthProvider directly,
    // this method is not actively used in the UI, but we keep it compatible.
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate latency
      
      // Fast bypass for testing/demo
      if (email.contains('admin')) {
        return User(
          id: '4',
          name: 'Admin Kelompok 4',
          email: email,
          role: UserRole.admin,
          token: 'mock_admin_jwt_token',
        );
      }
      
      try {
        final mockUser = _mockUsers.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase(),
        );
        return User(
          id: mockUser.id,
          name: mockUser.name,
          email: mockUser.email,
          role: mockUser.role,
          token: 'mock_jwt_token_for_${mockUser.id}',
        );
      } catch (_) {
        // Default new user login simulation if credentials not pre-registered
        return User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
          role: UserRole.mahasiswa,
          token: 'mock_jwt_token_new_user',
        );
      }
    } else {
      // In live Supabase mode, login is handled in AuthProvider using registrations table.
      throw UnimplementedError('Gunakan AuthProvider untuk autentikasi Supabase.');
    }
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        token: 'mock_jwt_token_registered',
      );
      _mockUsers.add(newUser);
      return newUser;
    } else {
      throw UnimplementedError('Gunakan AuthProvider untuk pendaftaran Supabase.');
    }
  }

  // --- ASPIRATIONS ---

  static Future<List<Aspiration>> getAspirations(String? token) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Return a copy of aspirations sorted by newest first
      final sortedList = List<Aspiration>.from(_mockAspirations);
      sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sortedList;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('aspirations')
            .select()
            .order('created_at', ascending: false);
        
        final List list = response as List;
        return list.map((item) => Aspiration.fromJson(item)).toList();
      } catch (e) {
        throw Exception('Gagal memuat daftar aspirasi dari Supabase: $e');
      }
    }
  }

  static Future<Aspiration> createAspiration({
    required String token,
    required String title,
    required String description,
    required String category,
    required bool isAnonymous,
    required User currentUser,
    String? imageUrl,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 700));
      final newAspiration = Aspiration(
        id: 'asp_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        userId: currentUser.id,
        userName: currentUser.name,
        userRole: currentUser.roleDisplayName,
        isAnonymous: isAnonymous,
        upvoteCount: 0,
        upvotedByUserIds: [],
        status: AspirationStatus.pending,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      _mockAspirations.add(newAspiration);
      return newAspiration;
    } else {
      try {
        final newAspiration = Aspiration(
          id: 'asp_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          category: category,
          userId: currentUser.id,
          userName: currentUser.name,
          userRole: currentUser.roleDisplayName,
          isAnonymous: isAnonymous,
          upvoteCount: 0,
          upvotedByUserIds: [],
          status: AspirationStatus.pending,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('aspirations').insert(newAspiration.toJson());
        return newAspiration;
      } catch (e) {
        throw Exception('Gagal mengirimkan aspirasi ke Supabase: $e');
      }
    }
  }

  static Future<Aspiration> toggleUpvote(String token, String aspirationId, String userId) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockAspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        final aspiration = _mockAspirations[index];
        final list = List<String>.from(aspiration.upvotedByUserIds);
        int count = aspiration.upvoteCount;
        
        if (list.contains(userId)) {
          list.remove(userId);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(userId);
          count += 1;
        }
        
        final updated = aspiration.copyWith(
          upvotedByUserIds: list,
          upvoteCount: count,
        );
        _mockAspirations[index] = updated;
        return updated;
      }
      throw Exception('Aspirasi tidak ditemukan.');
    } else {
      try {
        final data = await Supabase.instance.client
            .from('aspirations')
            .select()
            .eq('id', aspirationId)
            .single();
        
        final aspiration = Aspiration.fromJson(data);
        final list = List<String>.from(aspiration.upvotedByUserIds);
        int count = aspiration.upvoteCount;
        
        if (list.contains(userId)) {
          list.remove(userId);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(userId);
          count += 1;
        }
        
        final response = await Supabase.instance.client
            .from('aspirations')
            .update({
              'upvoted_by_user_ids': list,
              'upvote_count': count,
            })
            .eq('id', aspirationId)
            .select()
            .single();
        
        return Aspiration.fromJson(response);
      } catch (e) {
        throw Exception('Gagal mengubah upvote di Supabase: $e');
      }
    }
  }

  static Future<Aspiration> updateStatus(
    String token,
    String aspirationId,
    AspirationStatus status, {
    String? resolvedImageUrl,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _mockAspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        final updated = _mockAspirations[index].copyWith(
          status: status,
          resolvedImageUrl: resolvedImageUrl,
        );
        _mockAspirations[index] = updated;
        return updated;
      }
      throw Exception('Aspirasi tidak ditemukan.');
    } else {
      try {
        final updateData = <String, dynamic>{
          'status': status.name,
        };
        if (resolvedImageUrl != null) {
          updateData['resolved_image_url'] = resolvedImageUrl;
        }

        final response = await Supabase.instance.client
            .from('aspirations')
            .update(updateData)
            .eq('id', aspirationId)
            .select()
            .single();
        
        return Aspiration.fromJson(response);
      } catch (e) {
        throw Exception('Gagal mengubah status di Supabase: $e');
      }
    }
  }

  // --- DISCUSSIONS / COMMENTS ---

  static Future<List<Comment>> getComments(String? token, String aspirationId) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final list = _mockComments.where((c) => c.aspirationId == aspirationId).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest comment first (thread flow)
      return list;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('comments')
            .select()
            .eq('aspiration_id', aspirationId)
            .order('created_at', ascending: true);
        
        final List list = response as List;
        return list.map((item) => Comment.fromJson(item)).toList();
      } catch (e) {
        throw Exception('Gagal memuat diskusi dari Supabase: $e');
      }
    }
  }

  static Future<Comment> addComment({
    required String token,
    required String aspirationId,
    required String content,
    required User currentUser,
    String? parentId,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final newComment = Comment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        aspirationId: aspirationId,
        userId: currentUser.id,
        userName: currentUser.name,
        userRole: currentUser.roleDisplayName,
        content: content,
        parentId: parentId,
        likedByUserIds: [],
        dislikedByUserIds: [],
        createdAt: DateTime.now(),
      );
      _mockComments.add(newComment);
      return newComment;
    } else {
      try {
        final newComment = Comment(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          aspirationId: aspirationId,
          userId: currentUser.id,
          userName: currentUser.name,
          userRole: currentUser.roleDisplayName,
          content: content,
          parentId: parentId,
          likedByUserIds: [],
          dislikedByUserIds: [],
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('comments').insert(newComment.toJson());
        return newComment;
      } catch (e) {
        throw Exception('Gagal menambahkan komentar ke Supabase: $e');
      }
    }
  }

  static Future<Comment> toggleCommentReaction(
    String token,
    String commentId,
    String userId,
    bool isLike,
  ) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockComments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final comment = _mockComments[index];
        List<String> likes = List<String>.from(comment.likedByUserIds);
        List<String> dislikes = List<String>.from(comment.dislikedByUserIds);

        if (isLike) {
          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
            dislikes.remove(userId);
          }
        } else {
          if (dislikes.contains(userId)) {
            dislikes.remove(userId);
          } else {
            dislikes.add(userId);
            likes.remove(userId);
          }
        }

        final updated = comment.copyWith(
          likeCount: likes.length,
          likedByUserIds: likes,
          dislikeCount: dislikes.length,
          dislikedByUserIds: dislikes,
        );
        _mockComments[index] = updated;
        return updated;
      }
      throw Exception('Komentar tidak ditemukan.');
    } else {
      try {
        final data = await Supabase.instance.client
            .from('comments')
            .select()
            .eq('id', commentId)
            .single();

        final comment = Comment.fromJson(data);
        List<String> likes = List<String>.from(comment.likedByUserIds);
        List<String> dislikes = List<String>.from(comment.dislikedByUserIds);

        if (isLike) {
          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
            dislikes.remove(userId);
          }
        } else {
          if (dislikes.contains(userId)) {
            dislikes.remove(userId);
          } else {
            dislikes.add(userId);
            likes.remove(userId);
          }
        }

        final response = await Supabase.instance.client
            .from('comments')
            .update({
              'like_count': likes.length,
              'liked_by_user_ids': likes,
              'dislike_count': dislikes.length,
              'disliked_by_user_ids': dislikes,
            })
            .eq('id', commentId)
            .select()
            .single();

        return Comment.fromJson(response);
      } catch (e) {
        throw Exception('Gagal mengubah reaksi komentar di Supabase: $e');
      }
    }
  }
}

