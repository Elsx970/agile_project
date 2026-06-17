import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';

class AspirationCreateScreen extends StatefulWidget {
  const AspirationCreateScreen({super.key});

  @override
  State<AspirationCreateScreen> createState() => _AspirationCreateScreenState();
}

class _AspirationCreateScreenState extends State<AspirationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _selectedCategory = 'Akademik';
  UserRole _selectedGuestRole = UserRole.mahasiswa;
  bool _isAnonymous = false;

  final List<String> _categories = ['Akademik', 'Fasilitas', 'Layanan', 'Lainnya'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<AspirationProvider>(context, listen: false);

      // Construct posting user identity
      User postUser;
      if (auth.isGuest) {
        final guestName = _isAnonymous 
            ? 'Anonim' 
            : (_nameController.text.trim().isNotEmpty 
                ? _nameController.text.trim() 
                : 'Tamu Civitas');
        
        postUser = User(
          id: 'guest',
          name: guestName,
          email: 'guest@unila.ac.id',
          role: _selectedGuestRole,
        );
      } else {
        // If logged in as admin
        postUser = auth.currentUser!;
      }

      final success = await provider.createAspiration(
        token: auth.currentUser?.token ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        isAnonymous: _isAnonymous,
        currentUser: postUser,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text('Aspirasi Terkirim'),
              ],
            ),
            content: const Text(
              'Aspirasi Anda berhasil diajukan dan akan ditinjau oleh pihak terkait. Terima kasih telah berpartisipasi!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _resetForm();
                  // Force list refresh to make sure it loads
                  provider.fetchAspirations(auth.currentUser?.token);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal mengirim aspirasi.'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _nameController.clear();
      _selectedCategory = 'Akademik';
      _selectedGuestRole = UserRole.mahasiswa;
      _isAnonymous = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<AspirationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kirim Aspirasi Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guidelines Info Card with premium soft gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.08), AppTheme.secondaryColor.withOpacity(0.03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panduan Aspirasi',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sampaikan aspirasi, saran, atau keluhan Anda secara sopan dan konstruktif untuk kemajuan civitas akademika Universitas Lampung.',
                            style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wrapped fields in a premium Card container
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Judul Aspirasi',
                          hintText: 'Contoh: Kerusakan Lampu di Gedung Kuliah B',
                          prefixIcon: Icon(Icons.title_outlined, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul aspirasi wajib diisi';
                          }
                          if (value.trim().length < 10) {
                            return 'Judul harus minimal 10 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Selector
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Aspirasi',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi / Detail Aspirasi',
                          hintText: 'Jelaskan keluhan dan usulan solusi Anda secara rinci...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Deskripsi wajib diisi';
                          }
                          if (value.trim().length < 20) {
                            return 'Deskripsi harus minimal 20 karakter agar jelas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Anonymous Switch inside styled box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAnonymous 
                              ? AppTheme.primaryColor.withOpacity(0.04) 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isAnonymous 
                                ? AppTheme.primaryColor.withOpacity(0.2) 
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Kirim secara Anonim',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: const Text(
                            'Sembunyikan identitas Anda dari publik di halaman feed.',
                            style: TextStyle(fontSize: 10),
                          ),
                          value: _isAnonymous,
                          onChanged: (val) {
                            setState(() {
                              _isAnonymous = val;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ),

                      // Custom Guest Name & Role Fields (Only if Guest and NOT anonymous)
                      if (auth.isGuest && !_isAnonymous) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Identitas Pengirim',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Anda (Opsional)',
                            hintText: 'Tamu Civitas',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserRole>(
                          value: _selectedGuestRole,
                          decoration: const InputDecoration(
                            labelText: 'Peran Anda',
                            prefixIcon: Icon(Icons.school_outlined, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(value: UserRole.mahasiswa, child: Text('Mahasiswa')),
                            DropdownMenuItem(value: UserRole.dosen, child: Text('Dosen')),
                            DropdownMenuItem(value: UserRole.tendik, child: Text('Tenaga Kependidikan')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGuestRole = val;
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              provider.isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: const Text('KIRIM ASPIRASI'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
