import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/aspiration.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';
import '../aspiration/aspiration_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchRegistrationRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<AspirationProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Admin',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Aspirasi'),
              Tab(icon: Icon(Icons.people_outline), text: 'Persetujuan Akun'),
            ],
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAspirationsTab(context, auth, provider),
            _buildApprovalsTab(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildAspirationsTab(BuildContext context, AuthProvider auth, AspirationProvider provider) {
    // Calculate quick stats
    final total = provider.aspirations.length;
    final pending = provider.aspirations.where((a) => a.status == AspirationStatus.pending).length;
    final diperiksa = provider.aspirations.where((a) => a.status == AspirationStatus.diperiksa).length;
    final selesai = provider.aspirations.where((a) => a.status == AspirationStatus.selesai).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid Section
          const Text(
            'Statistik Aspirasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildStatCard('Total Aspirasi', total.toString(), AppTheme.primaryColor, Icons.assessment_outlined),
              _buildStatCard('Pending', pending.toString(), AppTheme.dangerColor, Icons.hourglass_top_outlined),
              _buildStatCard('Sedang Diperiksa', diperiksa.toString(), Colors.amber.shade800, Icons.find_in_page_outlined),
              _buildStatCard('Telah Selesai', selesai.toString(), AppTheme.accentColor, Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 24),

          // Moderation Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Tindak Lanjut',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              Text(
                'Admin Mode',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Aspirations List with quick actions
          provider.aspirations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Belum ada data aspirasi masuk.', style: TextStyle(color: Colors.black54)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.aspirations.length,
                  itemBuilder: (context, index) {
                    return _buildModerationCard(context, provider.aspirations[index], auth.currentUser?.token ?? '', provider);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab(BuildContext context, AuthProvider auth) {
    final requests = auth.registrationRequests;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permintaan Pendaftaran Tertunda',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Setujui pendaftaran civitas untuk mengizinkan mereka masuk ke sistem.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          requests.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Pendaftaran Tertunda',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Semua pengajuan pendaftaran mahasiswa & dosen telah diproses.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final displayDate = '${req.requestedAt.day}/${req.requestedAt.month}/${req.requestedAt.year}';
                    final isMhs = req.role == UserRole.mahasiswa;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isMhs 
                                          ? Colors.amber.withOpacity(0.1) 
                                          : AppTheme.accentColor.withOpacity(0.1),
                                      child: Icon(
                                        isMhs ? Icons.school_outlined : Icons.badge_outlined,
                                        size: 18,
                                        color: isMhs ? Colors.amber.shade800 : AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          isMhs ? 'Peran: Mahasiswa' : 'Peran: Dosen',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200, width: 0.5),
                                  ),
                                  child: Text(
                                    'Menunggu',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMhs ? 'NPM: ${req.idNumber}' : 'NIP: ${req.idNumber}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Diajukan: $displayDate',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.dangerColor,
                                        side: const BorderSide(color: AppTheme.dangerColor, width: 1.2),
                                        minimumSize: const Size(80, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () {
                                        auth.rejectRequest(req.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Pendaftaran akun ditolak.'),
                                            backgroundColor: AppTheme.dangerColor,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.close_rounded, size: 12),
                                      label: const Text('TOLAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentColor,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(90, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () {
                                        auth.approveRequest(req.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Akun ${req.name} telah disetujui.'),
                                            backgroundColor: AppTheme.accentColor,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 12),
                                      label: const Text('SETUJUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationCard(BuildContext context, Aspiration asp, String token, AspirationProvider provider) {
    final displayName = asp.isAnonymous ? '${asp.userName} (Anonim)' : asp.userName;
    final displayDate = '${asp.createdAt.day}/${asp.createdAt.month}/${asp.createdAt.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    asp.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusMiniBadge(asp.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Oleh $displayName • $displayDate',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 30),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AspirationDetailScreen(aspirationId: asp.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Detail & Diskusi', style: TextStyle(fontSize: 11)),
                ),
                
                // Quick transition buttons
                Row(
                  children: [
                    if (asp.status == AspirationStatus.pending) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          minimumSize: const Size(70, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => provider.updateAspirationStatus(
                          token: token,
                          aspirationId: asp.id,
                          newStatus: AspirationStatus.diperiksa,
                        ),
                        child: const Text('PERIKSA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (asp.status != AspirationStatus.selesai) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          minimumSize: const Size(70, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => provider.updateAspirationStatus(
                          token: token,
                          aspirationId: asp.id,
                          newStatus: AspirationStatus.selesai,
                        ),
                        child: const Text('SELESAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ] else
                      const Text(
                        'Sudah Selesai',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
}
