import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/aspiration.dart';
import '../../../models/comment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';

class AspirationDetailScreen extends StatefulWidget {
  final String aspirationId;

  const AspirationDetailScreen({super.key, required this.aspirationId});

  @override
  State<AspirationDetailScreen> createState() => _AspirationDetailScreenState();
}

class _AspirationDetailScreenState extends State<AspirationDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSendingComment = false;
  Comment? _replyToComment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<AspirationProvider>(context, listen: false);
    provider.fetchComments(auth.currentUser?.token, widget.aspirationId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _postComment(String token, AuthProvider auth, AspirationProvider provider) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSendingComment = true;
    });

    final success = await provider.addComment(
      token: token,
      aspirationId: widget.aspirationId,
      content: text,
      currentUser: auth.currentUser!,
      parentId: _replyToComment?.id,
    );

    setState(() {
      _isSendingComment = false;
    });

    if (success && mounted) {
      _commentController.clear();
      setState(() {
        _replyToComment = null;
      });
      // Scroll to bottom of the comment list
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memposting komentar.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _changeStatus(String token, AspirationProvider provider, AspirationStatus newStatus) async {
    final success = await provider.updateAspirationStatus(
      token: token,
      aspirationId: widget.aspirationId,
      newStatus: newStatus,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status berhasil diubah menjadi "${newStatus.name.toUpperCase()}"'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal mengubah status.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<AspirationProvider>(context);

    // Find aspiration by ID from provider
    Aspiration? asp;
    try {
      asp = provider.aspirations.firstWhere((a) => a.id == widget.aspirationId);
    } catch (_) {
      // Fallback
    }

    if (asp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Aspirasi')),
        body: const Center(child: Text('Aspirasi tidak ditemukan.')),
      );
    }

    final comments = provider.getCommentsForAspiration(widget.aspirationId);
    final mainComments = comments.where((c) => c.parentId == null || c.parentId!.isEmpty).toList();
    final replies = comments.where((c) => c.parentId != null && c.parentId!.isNotEmpty).toList();
    final commentRepliesMap = <String, List<Comment>>{};
    for (final reply in replies) {
      if (reply.parentId != null) {
        commentRepliesMap.putIfAbsent(reply.parentId!, () => []).add(reply);
      }
    }
    
    final hasUpvoted = asp.upvotedByUserIds.contains(auth.currentUser?.id);
    final formattedDate = '${asp.createdAt.day}/${asp.createdAt.month}/${asp.createdAt.year}';
    final displayName = asp.isAnonymous ? 'Pengguna Anonim' : asp.userName;
    final displayRole = asp.isAnonymous ? 'Civitas' : asp.userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Diskusi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadData();
                provider.fetchAspirations(auth.currentUser?.token);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aspiration Details Card
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Row
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: asp.isAnonymous
                                          ? [Colors.grey.shade300, Colors.grey.shade500]
                                          : [AppTheme.primaryColor, AppTheme.secondaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      asp.isAnonymous ? '?' : displayName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$displayRole • $formattedDate',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildCategoryBadge(asp.category),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            
                            // Visual Status Tracker Timeline
                            _buildStatusTimeline(asp.status),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              asp.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              asp.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Attachments Area
                            if (asp.imageUrl != null || asp.resolvedImageUrl != null) ...[
                              const Divider(),
                              const SizedBox(height: 12),
                              const Text(
                                'Lampiran & Bukti Pendukung',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (asp.imageUrl != null) ...[
                                    _buildAttachmentButton(
                                      context,
                                      label: 'Foto Lampiran Awal',
                                      icon: Icons.photo_outlined,
                                      color: Colors.blue.shade600,
                                      imageUrl: asp.imageUrl!,
                                    ),
                                  ],
                                  if (asp.imageUrl != null && asp.resolvedImageUrl != null)
                                    const SizedBox(width: 12),
                                  if (asp.resolvedImageUrl != null) ...[
                                    _buildAttachmentButton(
                                      context,
                                      label: 'Bukti Perbaikan',
                                      icon: Icons.check_circle_outline,
                                      color: AppTheme.accentColor,
                                      imageUrl: asp.resolvedImageUrl!,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 20),

                            // Footer: Upvotes, Comments, Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    provider.toggleUpvote(
                                      auth.currentUser?.token ?? '',
                                      asp!.id,
                                      auth.currentUser!,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: hasUpvoted 
                                          ? AppTheme.primaryColor.withOpacity(0.1) 
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: hasUpvoted ? AppTheme.primaryColor : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasUpvoted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                          size: 16,
                                          color: hasUpvoted ? AppTheme.primaryColor : Colors.black54,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${asp.upvoteCount} Dukungan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: hasUpvoted ? AppTheme.primaryColor : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(asp.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Admin Moderation Panel
                    if (auth.isAdmin) ...[
                      _buildAdminModerationPanel(auth.currentUser?.token ?? '', provider, asp),
                      const SizedBox(height: 16),
                    ],

                    // Discussion Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Diskusi Civitas (${comments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Comments List
                    provider.isLoadingComments
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ))
                        : comments.isEmpty
                            ? _buildEmptyCommentsPlaceholder()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: mainComments.length,
                                itemBuilder: (context, index) {
                                  final mainComment = mainComments[index];
                                  final commentReplies = commentRepliesMap[mainComment.id] ?? [];
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCommentCard(
                                        mainComment,
                                        auth.currentUser?.id,
                                        provider,
                                        auth.currentUser?.token ?? '',
                                        isReply: false,
                                      ),
                                      if (commentReplies.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 8.0),
                                          child: Column(
                                            children: commentReplies.map((reply) {
                                              return IntrinsicHeight(
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    // Visual connector line
                                                    Container(
                                                      width: 2,
                                                      margin: const EdgeInsets.only(right: 12, top: 0, bottom: 12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade300,
                                                        borderRadius: BorderRadius.circular(1),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: _buildCommentCard(
                                                          reply,
                                                          auth.currentUser?.id,
                                                          provider,
                                                          auth.currentUser?.token ?? '',
                                                          isReply: true,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ),

          // Message Input Field
          _buildCommentInput(auth.currentUser?.token ?? '', auth, provider),
        ],
      ),
    );
  }

  Widget _buildAdminModerationPanel(String token, AspirationProvider provider, Aspiration asp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Panel Moderasi Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ubah status aspirasi untuk menindaklanjuti:',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModerationButton(
                  label: 'Pending',
                  icon: Icons.hourglass_empty,
                  color: AppTheme.dangerColor,
                  isActive: asp.status == AspirationStatus.pending,
                  onPressed: () => _changeStatus(token, provider, AspirationStatus.pending),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModerationButton(
                  label: 'Diperiksa',
                  icon: Icons.search,
                  color: Colors.amber.shade800,
                  isActive: asp.status == AspirationStatus.diperiksa,
                  onPressed: () => _changeStatus(token, provider, AspirationStatus.diperiksa),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModerationButton(
                  label: 'Selesai',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.accentColor,
                  isActive: asp.status == AspirationStatus.selesai,
                  onPressed: () => _showResolveDialog(token, provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModerationButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : Colors.white,
        foregroundColor: isActive ? Colors.white : color,
        elevation: isActive ? 1 : 0,
        side: BorderSide(color: color, width: 1),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCommentCard(
    Comment comment,
    String? currentUserId,
    AspirationProvider provider,
    String token, {
    required bool isReply,
  }) {
    final isMe = comment.userId == currentUserId;
    final formattedDate = '${comment.createdAt.day}/${comment.createdAt.month} ${comment.createdAt.hour.toString().padLeft(2, '0')}:${comment.createdAt.minute.toString().padLeft(2, '0')}';
    
    // Highlight admin comments
    final isAdminComment = comment.userRole == 'Administrator';
    final hasLiked = currentUserId != null && comment.likedByUserIds.contains(currentUserId);
    final hasDisliked = currentUserId != null && comment.dislikedByUserIds.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAdminComment 
            ? AppTheme.primaryColor.withOpacity(0.06) 
            : isMe 
                ? Colors.blue.shade50 
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdminComment 
              ? AppTheme.primaryColor.withOpacity(0.15) 
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdminComment 
                          ? AppTheme.primaryColor 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      comment.userRole,
                      style: TextStyle(
                        fontSize: 9,
                        color: isAdminComment ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Like Button
              _buildReactionButton(
                icon: hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                color: hasLiked ? AppTheme.primaryColor : Colors.grey.shade600,
                count: comment.likeCount,
                onPressed: () {
                  if (currentUserId == null) return;
                  provider.toggleCommentReaction(
                    token: token,
                    commentId: comment.id,
                    aspirationId: widget.aspirationId,
                    userId: currentUserId,
                    isLike: true,
                  );
                },
              ),
              const SizedBox(width: 16),
              // Dislike Button
              _buildReactionButton(
                icon: hasDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                color: hasDisliked ? AppTheme.dangerColor : Colors.grey.shade600,
                count: comment.dislikeCount,
                onPressed: () {
                  if (currentUserId == null) return;
                  provider.toggleCommentReaction(
                    token: token,
                    commentId: comment.id,
                    aspirationId: widget.aspirationId,
                    userId: currentUserId,
                    isLike: false,
                  );
                },
              ),
              if (!isReply) ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _replyToComment = comment;
                    });
                  },
                  icon: const Icon(Icons.reply_rounded, size: 14, color: AppTheme.primaryColor),
                  label: const Text(
                    'Balas',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(String token, AuthProvider auth, AspirationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_replyToComment != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'Membalas '),
                          TextSpan(
                            text: '@${_replyToComment!.userName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          TextSpan(text: ': "${_replyToComment!.content}"'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _replyToComment = null;
                      });
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyToComment != null ? 'Tulis balasan Anda...' : 'Tulis komentar atau diskusi...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              _isSendingComment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: () => _postComment(token, auth, provider),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    switch (category) {
      case 'Akademik':
        color = Colors.blue.shade700;
        break;
      case 'Fasilitas':
        color = Colors.orange.shade700;
        break;
      case 'Layanan':
        color = Colors.teal.shade700;
        break;
      default:
        color = Colors.purple.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AspirationStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case AspirationStatus.pending:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Pending';
        break;
      case AspirationStatus.diperiksa:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'Diperiksa';
        break;
      case AspirationStatus.selesai:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Selesai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text(
              'Belum ada komentar',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mulai diskusi dengan menuliskan tanggapan Anda di bawah.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(AspirationStatus status) {
    int activeIndex = 0;
    if (status == AspirationStatus.diperiksa) activeIndex = 1;
    if (status == AspirationStatus.selesai) activeIndex = 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        children: [
          _buildTimelineStep(0, 'Diajukan', activeIndex >= 0, activeIndex == 0),
          _buildTimelineLine(activeIndex >= 1),
          _buildTimelineStep(1, 'Diperiksa', activeIndex >= 1, activeIndex == 1),
          _buildTimelineLine(activeIndex >= 2),
          _buildTimelineStep(2, 'Selesai', activeIndex >= 2, activeIndex == 2),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(int index, String label, bool isCompleted, bool isActive) {
    final color = isActive
        ? AppTheme.primaryColor
        : (isCompleted ? AppTheme.accentColor : Colors.grey.shade400);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : Colors.white,
              border: Border.all(
                color: color,
                width: isActive ? 6 : 2,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: isCompleted && !isActive
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
              color: isActive || isCompleted ? Colors.black87 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isCompleted ? AppTheme.accentColor : Colors.grey.shade300,
    );
  }

  // --- IMAGE AND ATTACHMENT MODAL POPUPS ---

  Widget _buildAttachmentButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String imageUrl,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showImagePopup(context, label, imageUrl),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showImagePopup(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('Gagal memuat gambar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResolveDialog(String token, AspirationProvider provider) {
    XFile? pickedImage;
    Uint8List? imageBytes;
    bool isUploading = false;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              try {
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setState(() {
                    pickedImage = image;
                    imageBytes = bytes;
                  });
                }
              } catch (e) {
                debugPrint('Error picking image: $e');
              }
            }

            Future<void> submitResolution() async {
              if (pickedImage == null) return;
              setState(() {
                isUploading = true;
              });

              try {
                final url = await provider.uploadImage(pickedImage);
                if (url != null) {
                  final success = await provider.updateAspirationStatus(
                    token: token,
                    aspirationId: widget.aspirationId,
                    newStatus: AspirationStatus.selesai,
                    resolvedImageUrl: url,
                  );
                  if (success && mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aspirasi telah berhasil diselesaikan dengan melampirkan bukti.'),
                        backgroundColor: AppTheme.accentColor,
                      ),
                    );
                  } else {
                    setState(() {
                      isUploading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? 'Gagal mengubah status.'),
                        backgroundColor: AppTheme.dangerColor,
                      ),
                    );
                  }
                }
              } catch (e) {
                setState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengunggah bukti perbaikan: $e'),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.accentColor),
                  SizedBox(width: 8),
                  Text('Selesaikan Aspirasi'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Anda wajib mengunggah bukti perbaikan (gambar/foto) untuk menandai aspirasi ini sebagai SELESAI agar transparan bagi mahasiswa & dosen.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  pickedImage == null
                      ? InkWell(
                          onTap: isUploading ? null : pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryColor, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'Pilih Bukti Gambar (Wajib)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.memory(
                                    imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (!isUploading)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          pickedImage = null;
                                          imageBytes = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.delete, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: (pickedImage == null || isUploading) ? null : submitResolution,
                  child: isUploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kirim & Selesaikan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
