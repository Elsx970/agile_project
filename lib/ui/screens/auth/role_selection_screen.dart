import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';

enum LoginView { selection, mahasiswaLogin, dosenLogin, adminLogin, mahasiswaRegister, dosenRegister }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  LoginView _currentView = LoginView.selection;
  
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userInputController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _userInputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setView(LoginView view) {
    setState(() {
      _currentView = view;
      _nameController.clear();
      _userInputController.clear();
      _passwordController.clear();
      _obscurePassword = true;
    });
  }

  void _submitLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final userInput = _userInputController.text.trim();
    final password = _passwordController.text;

    bool success = false;
    if (_currentView == LoginView.mahasiswaLogin) {
      success = await auth.loginMahasiswa(userInput, password);
    } else if (_currentView == LoginView.dosenLogin) {
      success = await auth.loginDosen(userInput, password);
    } else if (_currentView == LoginView.adminLogin) {
      success = await auth.loginAdmin(userInput, password);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Selamat datang kembali, ${auth.currentUser?.name}!'),
            ],
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.errorMessage ?? 'Gagal masuk. Periksa kembali input Anda.')),
            ],
          ),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with subtle pattern decoration
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
            ),
          ),
          
          // Decorative circles in background for premium feel
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Main content container
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand / Logo Section
                    Hero(
                      tag: 'app_logo',
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18.0),
                        child: Image.asset(
                          'image/Aspiranila Logo Text.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Suara Civitas Akademika Universitas Lampung',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Dynamic Content View based on state
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildCurrentView(auth, isDesktop),
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      '© 2026 Kelompok 4 - Penjaminan Mutu & Aspirasi',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(AuthProvider auth, bool isDesktop) {
    switch (_currentView) {
      case LoginView.selection:
        return _buildRoleSelection(auth, isDesktop);
      case LoginView.mahasiswaLogin:
        return _buildLoginForm(
          auth: auth,
          roleName: 'Mahasiswa',
          idFieldName: 'NPM',
          hintText: 'Masukkan NPM Anda',
          isNumericId: true,
          icon: Icons.school_outlined,
        );
      case LoginView.dosenLogin:
        return _buildLoginForm(
          auth: auth,
          roleName: 'Dosen',
          idFieldName: 'NIP',
          hintText: 'Masukkan NIP Anda',
          isNumericId: true,
          icon: Icons.badge_outlined,
        );
      case LoginView.adminLogin:
        return _buildLoginForm(
          auth: auth,
          roleName: 'Administrator',
          idFieldName: 'Username',
          hintText: 'Masukkan Username Admin',
          isNumericId: false,
          icon: Icons.person_outline,
        );
      case LoginView.mahasiswaRegister:
        return _buildRegisterForm(
          auth: auth,
          roleName: 'Mahasiswa',
          idFieldName: 'NPM',
          hintText: 'Masukkan NPM Baru Anda',
          isNumericId: true,
          icon: Icons.school_outlined,
          role: UserRole.mahasiswa,
        );
      case LoginView.dosenRegister:
        return _buildRegisterForm(
          auth: auth,
          roleName: 'Dosen',
          idFieldName: 'NIP',
          hintText: 'Masukkan NIP Baru Anda',
          isNumericId: true,
          icon: Icons.badge_outlined,
          role: UserRole.dosen,
        );
    }
  }

  Widget _buildRoleSelection(AuthProvider auth, bool isDesktop) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PILIH PERAN MASUK',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan pilih akses masuk sesuai dengan peran Anda di Universitas Lampung',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          
          _buildPremiumRoleCard(
            label: 'Mahasiswa',
            description: 'Sampaikan aspirasi dan ikuti diskusi kampus',
            icon: Icons.school_rounded,
            color: Colors.amber.shade800,
            onPressed: () => _setView(LoginView.mahasiswaLogin),
          ),
          const SizedBox(height: 16),
          _buildPremiumRoleCard(
            label: 'Dosen',
            description: 'Tanggapi aspirasi & beri evaluasi akademis',
            icon: Icons.supervised_user_circle_rounded,
            color: AppTheme.accentColor,
            onPressed: () => _setView(LoginView.dosenLogin),
          ),
          const SizedBox(height: 16),
          _buildPremiumRoleCard(
            label: 'Administrator',
            description: 'Kelola verifikasi akun dan moderasi aspirasi',
            icon: Icons.admin_panel_settings_rounded,
            color: AppTheme.dangerColor,
            onPressed: () => _setView(LoginView.adminLogin),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRoleCard({
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({
    required AuthProvider auth,
    required String roleName,
    required String idFieldName,
    required String hintText,
    required bool isNumericId,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _setView(LoginView.selection),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                  tooltip: 'Kembali',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Masuk $roleName',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Identity Field (NPM / NIP / Username)
            TextFormField(
              controller: _userInputController,
              keyboardType: isNumericId ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: idFieldName,
                hintText: hintText,
                prefixIcon: Icon(
                  icon,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$idFieldName wajib diisi';
                }
                if (isNumericId) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return '$idFieldName harus berupa angka';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                hintText: 'Masukkan kata sandi Anda',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kata sandi wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit Button
            auth.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _submitLogin(auth),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'MASUK',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _setView(LoginView.selection),
              child: Text(
                'Batal & Kembali',
                style: GoogleFonts.montserrat(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (roleName != 'Administrator') ...[
              const SizedBox(height: 12),
              const Divider(height: 20),
              TextButton(
                onPressed: () {
                  _setView(roleName == 'Mahasiswa'
                      ? LoginView.mahasiswaRegister
                      : LoginView.dosenRegister);
                },
                child: Text(
                  'Belum punya akun? Daftar di sini',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm({
    required AuthProvider auth,
    required String roleName,
    required String idFieldName,
    required String hintText,
    required bool isNumericId,
    required IconData icon,
    required UserRole role,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _setView(roleName == 'Mahasiswa'
                      ? LoginView.mahasiswaLogin
                      : LoginView.dosenLogin),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                  tooltip: 'Kembali',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daftar $roleName',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Register Tip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pendaftaran memerlukan persetujuan Administrator sebelum akun dapat digunakan.',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Name Input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap Anda',
                prefixIcon: Icon(
                  Icons.person_outline,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama lengkap wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Identity ID Input (NPM / NIP)
            TextFormField(
              controller: _userInputController,
              keyboardType: isNumericId ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: idFieldName,
                hintText: hintText,
                prefixIcon: Icon(
                  icon,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$idFieldName wajib diisi';
                }
                if (isNumericId) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return '$idFieldName harus berupa angka';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Input
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Baru',
                hintText: 'Masukkan kata sandi baru Anda',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kata sandi wajib diisi';
                }
                if (value.length < 6) {
                  return 'Kata sandi minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit Button
            auth.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final name = _nameController.text.trim();
                        final idNumber = _userInputController.text.trim();
                        final password = _passwordController.text;
                        
                        final success = await auth.registerAccount(
                          name: name,
                          idNumber: idNumber,
                          password: password,
                          role: role,
                        );

                        if (success && mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppTheme.accentColor),
                                  SizedBox(width: 8),
                                  Text('Pengajuan Terkirim'),
                                ],
                              ),
                              content: Text(
                                'Pendaftaran akun atas nama $name ($idFieldName: $idNumber) berhasil diajukan.\n\nSilakan tunggu persetujuan dari Administrator.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    _setView(role == UserRole.mahasiswa 
                                        ? LoginView.mahasiswaLogin 
                                        : LoginView.dosenLogin);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(auth.errorMessage ?? 'Gagal mendaftarkan akun. NPM/NIP mungkin sudah terdaftar.')),
                                ],
                              ),
                              backgroundColor: AppTheme.dangerColor,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'DAFTAR AKUN',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _setView(role == UserRole.mahasiswa 
                  ? LoginView.mahasiswaLogin 
                  : LoginView.dosenLogin),
              child: Text(
                'Batal & Kembali',
                style: GoogleFonts.montserrat(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
