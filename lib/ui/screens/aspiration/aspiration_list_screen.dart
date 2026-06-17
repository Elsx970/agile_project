import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/aspiration.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';
import 'aspiration_detail_screen.dart';

class AspirationListScreen extends StatefulWidget {
  const AspirationListScreen({super.key});

  @override
  State<AspirationListScreen> createState() => _AspirationListScreenState();
}

class _AspirationListScreenState extends State<AspirationListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _selectedStatus = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = ['Semua', 'Akademik', 'Fasilitas', 'Layanan', 'Lainnya'];
  final List<String> _statuses = ['Semua', 'Pending', 'Diperiksa', 'Selesai'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<AspirationProvider>(context);

    // Apply filtering client-side for immediate responsive performance
    final filteredAspirations = provider.aspirations.where((asp) {
      final matchesSearch = asp.title.toLowerCase().contains(_searchQuery) ||
          asp.description.toLowerCase().contains(_searchQuery);
      
      final matchesCategory = _selectedCategory == 'Semua' || asp.category == _selectedCategory;
      
      final matchesStatus = _selectedStatus == 'Semua' || 
          asp.statusDisplayName.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aspirasi Civitas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAspirations(auth.currentUser?.token),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari aspirasi...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    fillColor: Colors.grey.shade50,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 14),
                
                // Categories row
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                          backgroundColor: Colors.grey.shade50,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Status Segment Control Selector
          Container(
            color: Colors.white,
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Main Feed
          Expanded(
            child: provider.isLoadingList
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? _buildErrorPlaceholder(provider.errorMessage!)
                    : filteredAspirations.isEmpty
                        ? _buildEmptyPlaceholder()
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchAspirations(auth.currentUser?.token),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredAspirations.length,
                              itemBuilder: (context, index) {
                                return _buildAspirationCard(filteredAspirations[index], auth);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  Widget _buildAspirationCard(Aspiration asp, AuthProvider auth) {
    final hasUpvoted = asp.upvotedByUserIds.contains(auth.currentUser?.id);
    final formattedDate = '${asp.createdAt.day}/${asp.createdAt.month}/${asp.createdAt.year}';
    final displayName = asp.isAnonymous ? 'Pengguna Anonim' : asp.userName;
    final displayRole = asp.isAnonymous ? 'Civitas' : asp.userRole;

    Color statusStripColor;
    switch (asp.status) {
      case AspirationStatus.pending:
        statusStripColor = AppTheme.dangerColor;
        break;
      case AspirationStatus.diperiksa:
        statusStripColor = Colors.amber.shade800;
        break;
      case AspirationStatus.selesai:
        statusStripColor = Colors.green.shade700;
        break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Accent Strip
            Container(
              width: 5,
              color: statusStripColor,
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AspirationDetailScreen(aspirationId: asp.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Profile, Date & Category Tag
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$displayRole • $formattedDate',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          _buildCategoryBadge(asp.category),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        asp.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        asp.description,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      // Footer: Upvotes, Comments, Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Upvote/Dukung Button
                              InkWell(
                                onTap: () {
                                  Provider.of<AspirationProvider>(context, listen: false)
                                      .toggleUpvote(auth.currentUser?.token ?? '', asp.id, auth.currentUser!);
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasUpvoted 
                                        ? AppTheme.primaryColor.withOpacity(0.08) 
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: hasUpvoted ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade200,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        hasUpvoted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                        size: 12,
                                        color: hasUpvoted ? AppTheme.primaryColor : Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${asp.upvoteCount} Dukung',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: hasUpvoted ? AppTheme.primaryColor : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Comments Icon Indicator as pill button too
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AspirationDetailScreen(aspirationId: asp.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.forum_outlined, size: 12, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Diskusi',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Status tag
                          _buildStatusBadge(asp.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speaker_notes_off_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aspirasi Tidak Ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada aspirasi dengan kriteria tersebut. Jadilah yang pertama menyuarakan!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.dangerColor),
            const SizedBox(height: 16),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
