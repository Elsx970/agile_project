import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, FileOptions;
import '../core/config.dart';
import '../models/aspiration.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AspirationProvider extends ChangeNotifier {
  List<Aspiration> _aspirations = [];
  final Map<String, List<Comment>> _commentsByAspirationId = {};
  
  bool _isLoadingList = false;
  bool _isLoadingComments = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Aspiration> get aspirations => _aspirations;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingComments => _isLoadingComments;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch all aspirations
  Future<void> fetchAspirations(String? token) async {
    _isLoadingList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _aspirations = await ApiService.getAspirations(token);
      _isLoadingList = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoadingList = false;
      notifyListeners();
    }
  }

  // Create new aspiration
  Future<bool> createAspiration({
    required String token,
    required String title,
    required String description,
    required String category,
    required bool isAnonymous,
    required User currentUser,
    String? imageUrl,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newAspiration = await ApiService.createAspiration(
        token: token,
        title: title,
        description: description,
        category: category,
        isAnonymous: isAnonymous,
        currentUser: currentUser,
        imageUrl: imageUrl,
      );
      
      // Add to local list at the beginning (newest first)
      _aspirations.insert(0, newAspiration);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle upvote/support
  Future<void> toggleUpvote(String token, String aspirationId, User currentUser) async {
    try {
      // Optimistic Update for instant visual responsiveness (micro-interaction)
      final index = _aspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        final aspiration = _aspirations[index];
        final list = List<String>.from(aspiration.upvotedByUserIds);
        int count = aspiration.upvoteCount;
        
        if (list.contains(currentUser.id)) {
          list.remove(currentUser.id);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(currentUser.id);
          count += 1;
        }
        
        _aspirations[index] = aspiration.copyWith(
          upvotedByUserIds: list,
          upvoteCount: count,
        );
        notifyListeners();
      }

      // Real network call
      final updated = await ApiService.toggleUpvote(token, aspirationId, currentUser.id);
      
      // Sync with response
      final idx = _aspirations.indexWhere((a) => a.id == aspirationId);
      if (idx != -1) {
        _aspirations[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Fetch comments for an aspiration
  List<Comment> getCommentsForAspiration(String aspirationId) {
    return _commentsByAspirationId[aspirationId] ?? [];
  }

  Future<void> fetchComments(String? token, String aspirationId) async {
    _isLoadingComments = true;
    notifyListeners();

    try {
      final comments = await ApiService.getComments(token, aspirationId);
      _commentsByAspirationId[aspirationId] = comments;
      _isLoadingComments = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  // Add comment/discussion post
  Future<bool> addComment({
    required String token,
    required String aspirationId,
    required String content,
    required User currentUser,
    String? parentId,
  }) async {
    _errorMessage = null;
    
    try {
      final newComment = await ApiService.addComment(
        token: token,
        aspirationId: aspirationId,
        content: content,
        currentUser: currentUser,
        parentId: parentId,
      );

      final list = _commentsByAspirationId[aspirationId] ?? [];
      list.add(newComment);
      _commentsByAspirationId[aspirationId] = list;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update status (Admin)
  Future<bool> updateAspirationStatus({
    required String token,
    required String aspirationId,
    required AspirationStatus newStatus,
    String? resolvedImageUrl,
  }) async {
    _errorMessage = null;

    try {
      final updated = await ApiService.updateStatus(
        token,
        aspirationId,
        newStatus,
        resolvedImageUrl: resolvedImageUrl,
      );
      
      // Update in our local lists
      final index = _aspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        _aspirations[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Upload image to Supabase Storage and return public URL
  Future<String?> uploadImage(dynamic pickedFile) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80';
    }

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileName = 'asp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await Supabase.instance.client.storage
          .from('aspirations')
          .uploadBinary(
            fileName, 
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
          
      final publicUrl = Supabase.instance.client.storage
          .from('aspirations')
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Gagal mengunggah berkas: $e');
    }
  }

  // Toggle comment reaction (like/dislike)
  Future<void> toggleCommentReaction({
    required String token,
    required String commentId,
    required String aspirationId,
    required String userId,
    required bool isLike,
  }) async {
    try {
      // Optimistic UI Update for instant feedback
      final list = _commentsByAspirationId[aspirationId] ?? [];
      final index = list.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final comment = list[index];
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

        list[index] = comment.copyWith(
          likeCount: likes.length,
          likedByUserIds: likes,
          dislikeCount: dislikes.length,
          dislikedByUserIds: dislikes,
        );
        notifyListeners();
      }

      // Real network call
      final updatedComment = await ApiService.toggleCommentReaction(
        token,
        commentId,
        userId,
        isLike,
      );

      // Sync local list with network response
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        list[idx] = updatedComment;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
