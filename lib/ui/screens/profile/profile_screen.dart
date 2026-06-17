import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/aspiration.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';
import '../aspiration/aspiration_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<AspirationProvider>(context);

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat profil.')),
      );
    }

    final isMahasiswa = auth.isMahasiswa;
    final isDosen = auth.isDosen;
    final isAdmin = auth.isAdmin;

    // Filter aspirations created by this user
    final myAspirations = provider.aspirations
        .where((asp) => asp.userId == currentUser.id)
        .toList();

    final totalUpvotes = myAspirations.fold<int>(0, (sum, item) => sum + item.upvoteCount);
    final totalResolved = myAspirations.where((a) => a.status == AspirationStatus.selesai).length;

    String idNumber = '';
    if (currentUser.email.contains('_') && currentUser.email.contains('@')) {
      idNumber = currentUser.email.split('_').last.split('@').first;
    } else {
      idNumber = currentUser.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin
              ? 'Panel Administrator'
              : (isDosen ? 'Profil Dosen' : 'Profil Mahasiswa'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Info Header Card with Gradient Cover
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Cover Banner
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                ),
                
                // Profile Content Container
                Padding(
                  padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 68, 16, 24),
                      child: Column(
                        children: [
                          Text(
                            currentUser.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isMahasiswa
                                ? 'NPM: $idNumber • ${currentUser.email}'
                                : (isDosen
                                    ? 'NIP: $idNumber • ${currentUser.email}'
                                    : currentUser.email),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isMahasiswa
                                  ? Colors.amber.withOpacity(0.1)
                                  : (isDosen
                                      ? AppTheme.accentColor.withOpacity(0.1)
                                      : AppTheme.dangerColor.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isMahasiswa
                                    ? Colors.amber.withOpacity(0.3)
                                    : (isDosen
                                        ? AppTheme.accentColor.withOpacity(0.3)
                                        : AppTheme.dangerColor.withOpacity(0.3)),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              isMahasiswa
                                  ? 'MAHASISWA'
                                  : (isDosen ? 'DOSEN' : 'ADMINISTRATOR'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                                color: isMahasiswa
                                    ? Colors.amber.shade900
                                    : (isDosen ? AppTheme.accentColor : AppTheme.dangerColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Dynamic statistics grid to avoid "kosongan" screen
                          Row(
                            children: [
                              _buildProfileStatItem(
                                label: isAdmin ? 'Total Aspirasi' : 'Aspirasi',
                                value: isAdmin ? provider.aspirations.length.toString() : myAspirations.length.toString(),
                                icon: Icons.campaign_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              _buildProfileStatItem(
                                label: isAdmin ? 'Persetujuan' : 'Dukungan',
                                value: isAdmin ? auth.registrationRequests.length.toString() : totalUpvotes.toString(),
                                icon: isAdmin ? Icons.people_outline : Icons.thumb_up_alt_outlined,
                                color: isAdmin ? Colors.amber.shade800 : AppTheme.secondaryColor,
                              ),
                              _buildProfileStatItem(
                                label: 'Terselesaikan',
                                value: isAdmin 
                                    ? provider.aspirations.where((a) => a.status == AspirationStatus.selesai).length.toString()
                                    : totalResolved.toString(),
                                icon: Icons.check_circle_outline,
                                color: AppTheme.accentColor,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Logout Sesi Button
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    isAdmin
                                        ? 'Keluar Sesi Admin'
                                        : (isDosen ? 'Keluar Sesi Dosen' : 'Keluar Sesi Mahasiswa'),
                                  ),
                                  content: Text(
                                    isAdmin
                                        ? 'Apakah Anda yakin ingin keluar dari panel admin?'
                                        : (isDosen
                                            ? 'Apakah Anda yakin ingin keluar dari sesi dosen?'
                                            : 'Apakah Anda yakin ingin keluar dari sesi mahasiswa?'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('BATAL'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        auth.logout();
                                      },
                                      child: Text(
                                        'KELUAR',
                                        style: TextStyle(
                                          color: isAdmin
                                              ? AppTheme.dangerColor
                                              : (isDosen ? AppTheme.accentColor : AppTheme.primaryColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            label: Text(
                              isAdmin
                                  ? 'KELUAR ADMINISTRATOR'
                                  : (isDosen ? 'KELUAR DOSEN' : 'KELUAR MAHASISWA'),
                              style: const TextStyle(letterSpacing: 0.5, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isAdmin
                                  ? AppTheme.dangerColor
                                  : (isDosen ? AppTheme.accentColor : AppTheme.primaryColor),
                              minimumSize: const Size(220, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide(
                                color: isAdmin
                                    ? AppTheme.dangerColor.withOpacity(0.5)
                                    : (isDosen ? AppTheme.accentColor.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.5)),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Floating Overlapping Avatar
                Positioned(
                  top: 15,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: isMahasiswa
                          ? Colors.amber.withOpacity(0.08)
                          : (isDosen
                              ? AppTheme.accentColor.withOpacity(0.08)
                              : AppTheme.dangerColor.withOpacity(0.08)),
                      child: Icon(
                        isMahasiswa
                            ? Icons.school_outlined
                            : (isDosen
                                ? Icons.supervised_user_circle_outlined
                                : Icons.admin_panel_settings_outlined),
                        size: 44,
                        color: isMahasiswa
                            ? Colors.amber.shade800
                            : (isDosen
                                ? AppTheme.accentColor
                                : AppTheme.dangerColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // User's own aspirations section (only for Guest/Dosen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAdmin ? 'Statistik Sistem' : 'Aspirasi Saya',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? AppTheme.dangerColor : AppTheme.primaryColor,
                    ),
                  ),
                  if (!isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${myAspirations.length} Kiriman',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            if (!isAdmin) ...[
              myAspirations.isEmpty
                  ? _buildEmptyHistoryPlaceholder()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: myAspirations.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(context, myAspirations[index]);
                      },
                    ),
            ] else ...[
              // Simple admin status cards placeholder on profile
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.security, color: AppTheme.primaryColor),
                        title: Text('Sistem Keamanan Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Anda terhubung ke database simulasi.', style: TextStyle(fontSize: 11)),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.help_center_outlined, color: AppTheme.primaryColor),
                        title: Text('Butuh Bantuan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Hubungi tim IT Universitas Lampung.', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Aspiration asp) {
    final formattedDate = '${asp.createdAt.day}/${asp.createdAt.month}/${asp.createdAt.year}';
    
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          asp.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              asp.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedDate • ${asp.category}',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                _buildStatusMiniBadge(asp.status),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AspirationDetailScreen(aspirationId: asp.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMiniBadge(AspirationStatus status) {
    Color color;
    String text;

    switch (status) {
      case AspirationStatus.pending:
        color = AppTheme.dangerColor;
        text = 'Pending';
        break;
      case AspirationStatus.diperiksa:
        color = Colors.amber.shade800;
        text = 'Diperiksa';
        break;
      case AspirationStatus.selesai:
        color = AppTheme.accentColor;
        text = 'Selesai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Belum ada aspirasi terkirim',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aspirasi yang Anda ajukan akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
