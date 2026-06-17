import 'package:flutter/material.dart';
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
  }) async {
    _errorMessage = null;
    
    try {
      final newComment = await ApiService.addComment(
        token: token,
        aspirationId: aspirationId,
        content: content,
        currentUser: currentUser,
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
  }) async {
    _errorMessage = null;

    try {
      final updated = await ApiService.updateStatus(token, aspirationId, newStatus);
      
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
}
