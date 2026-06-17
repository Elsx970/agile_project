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
  // Default user is null on startup to prompt role selection screen
  User? _currentUser;

  bool _isLoading = false;
  String? _errorMessage;

  // Pending registration requests list
  final List<RegistrationRequest> _registrationRequests = [
    // Pre-populate with sample requests for demo
    RegistrationRequest(
      id: 'req_1',
      name: 'Dr. Budi Utomo, M.T.',
      idNumber: '19880415',
      password: 'dosenbudi',
      role: UserRole.dosen,
      requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    RegistrationRequest(
      id: 'req_2',
      name: 'Andi Pratama',
      idNumber: '2217051088',
      password: 'mhsandi',
      role: UserRole.mahasiswa,
      requestedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  // Approved accounts list
  final List<RegistrationRequest> _approvedAccounts = [];

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => false; // Guest access is disabled; students must log in
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
          .from('registrations')
          .select()
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      final List list = response as List;
      _registrationRequests.clear();
      for (var item in list) {
        _registrationRequests.add(RegistrationRequest(
          id: item['id']?.toString() ?? '',
          name: item['name'] ?? '',
          idNumber: item['id_number'] ?? '',
          password: item['password'] ?? '',
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
      try {
        final id = 'req_${DateTime.now().millisecondsSinceEpoch}';
        await Supabase.instance.client.from('registrations').insert({
          'id': id,
          'name': name,
          'id_number': idNumber,
          'password': password,
          'role': role.name,
          'is_approved': false,
          'created_at': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
        notifyListeners();
        return true;
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
        final req = _registrationRequests[idx];
        _approvedAccounts.add(req);
        _registrationRequests.removeAt(idx);
        notifyListeners();
      }
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        await Supabase.instance.client
            .from('registrations')
            .update({'is_approved': true})
            .eq('id', id);

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
        await Supabase.instance.client
            .from('registrations')
            .delete()
            .eq('id', id);

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

      // 1. Verify against default demo credentials
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

      // 2. Verify against approved list
      final approvedIdx = _approvedAccounts.indexWhere(
        (acc) => acc.role == UserRole.mahasiswa && acc.idNumber.trim() == npm.trim() && acc.password == password
      );

      if (approvedIdx != -1) {
        final account = _approvedAccounts[approvedIdx];
        _currentUser = User(
          id: 'mahasiswa_${npm.trim()}',
          name: account.name,
          email: 'mahasiswa@unila.ac.id',
          role: UserRole.mahasiswa,
          token: 'mock_mahasiswa_jwt_token',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 3. Check if account is still pending approval
      final isPending = _registrationRequests.any(
        (r) => r.role == UserRole.mahasiswa && r.idNumber.trim() == npm.trim()
      );

      if (isPending) {
        _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
      } else {
        _errorMessage = 'NPM atau kata sandi mahasiswa salah.';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('registrations')
            .select()
            .eq('id_number', npm.trim())
            .eq('role', 'mahasiswa')
            .maybeSingle();

        if (response == null) {
          if (npm.trim() == '2217051001' && password == 'mhs123') {
            _currentUser = User(
              id: 'mahasiswa_2217051001',
              name: 'Mahasiswa Unila',
              email: 'mahasiswa@unila.ac.id',
              role: UserRole.mahasiswa,
              token: 'supabase_session_token_mhs',
            );
            _isLoading = false;
            notifyListeners();
            return true;
          }
          _errorMessage = 'NPM tidak terdaftar.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final isApproved = response['is_approved'] as bool? ?? false;
        final dbPassword = response['password'] as String? ?? '';
        final name = response['name'] as String? ?? 'Mahasiswa';
        final id = response['id'] as String? ?? '';

        if (dbPassword != password) {
          _errorMessage = 'Kata sandi salah.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (!isApproved) {
          _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = User(
          id: id,
          name: name,
          email: 'mahasiswa_${npm.trim()}@unila.ac.id',
          role: UserRole.mahasiswa,
          token: 'supabase_session_token_$id',
        );
        _isLoading = false;
        notifyListeners();
        return true;
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

      // 1. Verify against default demo credentials
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

      // 2. Verify against approved list
      final approvedIdx = _approvedAccounts.indexWhere(
        (acc) => acc.role == UserRole.dosen && acc.idNumber.trim() == nip.trim() && acc.password == password
      );

      if (approvedIdx != -1) {
        final account = _approvedAccounts[approvedIdx];
        _currentUser = User(
          id: 'dosen_${nip.trim()}',
          name: account.name,
          email: 'dosen@unila.ac.id',
          role: UserRole.dosen,
          token: 'mock_dosen_jwt_token',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 3. Check if account is still pending approval
      final isPending = _registrationRequests.any(
        (r) => r.role == UserRole.dosen && r.idNumber.trim() == nip.trim()
      );

      if (isPending) {
        _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
      } else {
        _errorMessage = 'NIP atau kata sandi dosen salah.';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('registrations')
            .select()
            .eq('id_number', nip.trim())
            .eq('role', 'dosen')
            .maybeSingle();

        if (response == null) {
          if (nip.trim() == '19900101' && password == 'dosen123') {
            _currentUser = User(
              id: 'dosen_19900101',
              name: 'Dosen Unila',
              email: 'dosen@unila.ac.id',
              role: UserRole.dosen,
              token: 'supabase_session_token_dosen',
            );
            _isLoading = false;
            notifyListeners();
            return true;
          }
          _errorMessage = 'NIP tidak terdaftar.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final isApproved = response['is_approved'] as bool? ?? false;
        final dbPassword = response['password'] as String? ?? '';
        final name = response['name'] as String? ?? 'Dosen';
        final id = response['id'] as String? ?? '';

        if (dbPassword != password) {
          _errorMessage = 'Kata sandi salah.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (!isApproved) {
          _errorMessage = 'Akun Anda sedang menunggu persetujuan dari Administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = User(
          id: id,
          name: name,
          email: 'dosen_${nip.trim()}@unila.ac.id',
          role: UserRole.dosen,
          token: 'supabase_session_token_$id',
        );
        _isLoading = false;
        notifyListeners();
        return true;
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
    } else {
      _errorMessage = 'Username atau password admin salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
