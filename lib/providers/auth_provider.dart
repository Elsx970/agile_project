import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/config.dart';
import '../models/user.dart';

class RegistrationRequest {
  final String id;
  final String name;
  final String idNumber;
  final String password;
  final UserRole role;
  final DateTime requestedAt;

  RegistrationRequest({
    required this.id,
    required this.name,
    required this.idNumber,
    required this.password,
    required this.role,
    required this.requestedAt,
  });
}

class AuthProvider extends ChangeNotifier {
  // Current logged in user profile
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Pending registration requests list
  final List<RegistrationRequest> _registrationRequests = [];

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (AppConfig.useMockMode) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session != null && user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        final isActive = profile['is_active'] as bool? ?? false;
        if (isActive) {
          _currentUser = User(
            id: profile['id'],
            name: profile['full_name'],
            email: profile['email'] ?? user.email ?? '',
            role: _parseRole(profile['role']),
            token: session.accessToken,
          );
          notifyListeners();
        } else {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
      // Clear stale/invalid session from storage to prevent repeated errors
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      _currentUser = null;
      notifyListeners();
    }
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isDosen => _currentUser?.role == UserRole.dosen;
  bool get isMahasiswa => _currentUser?.role == UserRole.mahasiswa;

  List<RegistrationRequest> get registrationRequests => _registrationRequests;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchRegistrationRequests() async {
    if (AppConfig.useMockMode) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('is_active', false)
          .order('created_at', ascending: false);

      final List list = response as List;
      _registrationRequests.clear();
      for (var item in list) {
        _registrationRequests.add(RegistrationRequest(
          id: item['id']?.toString() ?? '',
          name: item['full_name'] ?? '',
          idNumber: item['employee_id'] ?? '',
          password: '', // Secure: do not retrieve or store passwords in plaintext
          role: _parseRole(item['role']),
          requestedAt: item['created_at'] != null
              ? DateTime.parse(item['created_at'])
              : DateTime.now(),
        ));
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.mahasiswa;
    final r = role.toString().toLowerCase();
    if (r == 'admin') return UserRole.admin;
    if (r == 'dosen') return UserRole.dosen;
    if (r == 'tendik') return UserRole.tendik;
    return UserRole.mahasiswa;
  }

  Future<bool> registerAccount({
    required String name,
    required String idNumber,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      _registrationRequests.add(RegistrationRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        idNumber: idNumber,
        password: password,
        role: role,
        requestedAt: DateTime.now(),
      ));
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      // Map role and ID numbers to standard student/lecturer emails
      String email;
      if (role == UserRole.mahasiswa) {
        email = '$idNumber@student.unila.ac.id';
      } else if (role == UserRole.dosen) {
        email = '$idNumber@dosen.unila.ac.id';
      } else if (role == UserRole.tendik) {
        email = '$idNumber@tendik.unila.ac.id';
      } else {
        email = '$idNumber@admin.unila.ac.id';
      }

      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'employee_id': idNumber,
            'role': role.name,
          },
        );
        _isLoading = false;
        notifyListeners();
        return response.user != null;
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<void> approveRequest(String id) async {
    if (AppConfig.useMockMode) {
      final idx = _registrationRequests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _registrationRequests.removeAt(idx);
        notifyListeners();
      }
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        // Execute the RPC function which activates the profile and confirms the user's email
        await Supabase.instance.client.rpc('approve_user', params: {
          'target_user_id': id,
        });

        _registrationRequests.removeWhere((r) => r.id == id);
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> rejectRequest(String id) async {
    if (AppConfig.useMockMode) {
      _registrationRequests.removeWhere((r) => r.id == id);
      notifyListeners();
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        // Execute the RPC function which deletes the user from auth.users (cascades to profiles)
        await Supabase.instance.client.rpc('reject_user', params: {
          'target_user_id': id,
        });

        _registrationRequests.removeWhere((r) => r.id == id);
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> loginMahasiswa(String npm, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));

      if (npm.trim() == '2217051001' && password == 'mhs123') {
        _currentUser = User(
          id: 'mahasiswa_2217051001',
          name: 'Mahasiswa Unila',
          email: 'mahasiswa@unila.ac.id',
          role: UserRole.mahasiswa,
          token: 'mock_mahasiswa_jwt_token',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'NPM atau kata sandi mahasiswa salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    } else {
      try {
        final email = '${npm.trim()}@student.unila.ac.id';
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        // Fetch user profile from database
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        final isActive = profile['is_active'] as bool? ?? false;
        if (!isActive) {
          // Immediately sign out since account is not approved
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
          _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = User(
          id: profile['id'],
          name: profile['full_name'],
          email: profile['email'] ?? email,
          role: _parseRole(profile['role']),
          token: authResponse.session?.accessToken ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        if (e.message.contains('Invalid login credentials') || e.code == 'invalid_credentials') {
          _errorMessage = 'NPM atau kata sandi salah, atau akun belum terdaftar.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> loginDosen(String nip, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));

      if (nip.trim() == '19900101' && password == 'dosen123') {
        _currentUser = User(
          id: 'dosen_19900101',
          name: 'Dosen Unila',
          email: 'dosen@unila.ac.id',
          role: UserRole.dosen,
          token: 'mock_dosen_jwt_token',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'NIP atau kata sandi dosen salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    } else {
      try {
        final email = '${nip.trim()}@dosen.unila.ac.id';
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        final isActive = profile['is_active'] as bool? ?? false;
        if (!isActive) {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
          _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = User(
          id: profile['id'],
          name: profile['full_name'],
          email: profile['email'] ?? email,
          role: _parseRole(profile['role']),
          token: authResponse.session?.accessToken ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        if (e.message.contains('Invalid login credentials') || e.code == 'invalid_credentials') {
          _errorMessage = 'NIP atau kata sandi salah, atau akun belum terdaftar.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> loginAdmin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));

      if (username.trim() == 'admin' && password == 'admin123') {
        _currentUser = User(
          id: 'admin',
          name: 'Admin Kelompok 4',
          email: 'admin@unila.ac.id',
          role: UserRole.admin,
          token: 'mock_admin_jwt_token',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Username atau password admin salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    } else {
      try {
        String email = username.trim();
        if (email == 'admin') {
          email = 'admin@unila.ac.id';
        } else if (!email.contains('@')) {
          email = '$email@admin.unila.ac.id';
        }

        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        final role = profile['role'] as String? ?? '';
        final isActive = profile['is_active'] as bool? ?? false;

        if (role != 'admin') {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
          _errorMessage = 'Akun ini bukan Administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (!isActive) {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
          _errorMessage = 'Akun Administrator Anda belum diaktifkan.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = User(
          id: profile['id'],
          name: profile['full_name'],
          email: profile['email'] ?? email,
          role: UserRole.admin,
          token: authResponse.session?.accessToken ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        if (e.message.contains('Invalid login credentials') || e.code == 'invalid_credentials') {
          _errorMessage = 'Username atau kata sandi salah, atau akun belum terdaftar.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  void logout() async {
    if (!AppConfig.useMockMode) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
