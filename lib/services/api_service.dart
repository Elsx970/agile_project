import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/config.dart';
import '../models/user.dart';
import '../models/aspiration.dart';
import '../models/comment.dart';

class ApiService {
  // Simulated Local Database for Mock Mode
  static final List<User> _mockUsers = [
    User(id: '1', name: 'M. Anazky Putra Irwansya', email: 'anazky@unila.ac.id', role: UserRole.mahasiswa),
    User(id: '2', name: 'Dr. Ir. Dyvta Avryansyah, M.T.', email: 'dyvta@unila.ac.id', role: UserRole.dosen),
    User(id: '3', name: 'Talitha Dalilah Difa, S.Kom.', email: 'talitha@unila.ac.id', role: UserRole.tendik),
    User(id: '4', name: 'Admin Kelompok 4', email: 'admin@unila.ac.id', role: UserRole.admin),
  ];

  static final List<Aspiration> _mockAspirations = [
    Aspiration(
      id: 'asp_1',
      title: 'Fasilitas Lab Komputer Rusak',
      description: 'AC di Lab Komputer 3 Gedung H Jurusan Teknik Elektro mati sejak 2 minggu lalu. Mahasiswa merasa sangat gerah saat praktikum, dan beberapa komputer mengalami overheat.',
      category: 'Fasilitas',
      userId: '1',
      userName: 'M. Anazky Putra Irwansya',
      userRole: 'Mahasiswa',
      isAnonymous: false,
      upvoteCount: 42,
      upvotedByUserIds: ['2', '3'],
      status: AspirationStatus.diperiksa,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Aspiration(
      id: 'asp_2',
      title: 'Keterlambatan Input Nilai KHS',
      description: 'Mohon untuk para dosen agar segera menginput nilai semester ganjil. Batas waktu KRS semester berikutnya sudah dekat, tapi nilai mata kuliah Pemrograman Mobile belum keluar.',
      category: 'Akademik',
      userId: '1',
      userName: 'M. Anazky Putra Irwansya',
      userRole: 'Mahasiswa',
      isAnonymous: true,
      upvoteCount: 15,
      upvotedByUserIds: ['3'],
      status: AspirationStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Aspiration(
      id: 'asp_3',
      title: 'Pelayanan Administrasi Jurusan Kurang Ramah',
      description: 'Staf administrasi di loket pelayanan dekanat kurang ramah dan sering meninggalkan loket sebelum jam istirahat. Mohon dilakukan pembinaan.',
      category: 'Layanan',
      userId: '3',
      userName: 'Talitha Dalilah Difa, S.Kom.',
      userRole: 'Tenaga Kependidikan',
      isAnonymous: false,
      upvoteCount: 29,
      upvotedByUserIds: ['1', '2'],
      status: AspirationStatus.selesai,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final List<Comment> _mockComments = [
    Comment(
      id: 'c_1',
      aspirationId: 'asp_1',
      userId: '2',
      userName: 'Dr. Ir. Dyvta Avryansyah, M.T.',
      userRole: 'Dosen',
      content: 'Saya setuju, hal ini sudah saya sampaikan juga ke bagian prasarana fakultas. Semoga segera ditindaklanjuti.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Comment(
      id: 'c_2',
      aspirationId: 'asp_1',
      userId: '4',
      userName: 'Admin Kelompok 4',
      userRole: 'Administrator',
      content: 'Aspirasi telah diterima dan saat ini statusnya diubah menjadi DI PERIKSA. Tim teknisi akan memeriksa AC Lab 3 besok pagi.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Comment(
      id: 'c_3',
      aspirationId: 'asp_3',
      userId: '4',
      userName: 'Admin Kelompok 4',
      userRole: 'Administrator',
      content: 'Terima kasih atas masukannya. Bagian kepegawaian telah menegur staf yang bersangkutan dan pelayanan akan terus kami tingkatkan.',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];


  // --- AUTHENTICATION ---

  static Future<User> login(String email, String password) async {
    // Note: Since multi-role logins are handled in AuthProvider directly,
    // this method is not actively used in the UI, but we keep it compatible.
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate latency
      
      // Fast bypass for testing/demo
      if (email.contains('admin')) {
        return User(
          id: '4',
          name: 'Admin Kelompok 4',
          email: email,
          role: UserRole.admin,
          token: 'mock_admin_jwt_token',
        );
      }
      
      try {
        final mockUser = _mockUsers.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase(),
        );
        return User(
          id: mockUser.id,
          name: mockUser.name,
          email: mockUser.email,
          role: mockUser.role,
          token: 'mock_jwt_token_for_${mockUser.id}',
        );
      } catch (_) {
        // Default new user login simulation if credentials not pre-registered
        return User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
          role: UserRole.mahasiswa,
          token: 'mock_jwt_token_new_user',
        );
      }
    } else {
      // In live Supabase mode, login is handled in AuthProvider using registrations table.
      throw UnimplementedError('Gunakan AuthProvider untuk autentikasi Supabase.');
    }
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        token: 'mock_jwt_token_registered',
      );
      _mockUsers.add(newUser);
      return newUser;
    } else {
      throw UnimplementedError('Gunakan AuthProvider untuk pendaftaran Supabase.');
    }
  }

  // --- ASPIRATIONS ---

  static Future<List<Aspiration>> getAspirations(String? token) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Return a copy of aspirations sorted by newest first
      final sortedList = List<Aspiration>.from(_mockAspirations);
      sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sortedList;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('aspirations')
            .select()
            .order('created_at', ascending: false);
        
        final List list = response as List;
        return list.map((item) => Aspiration.fromJson(item)).toList();
      } catch (e) {
        throw Exception('Gagal memuat daftar aspirasi dari Supabase: $e');
      }
    }
  }

  static Future<Aspiration> createAspiration({
    required String token,
    required String title,
    required String description,
    required String category,
    required bool isAnonymous,
    required User currentUser,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 700));
      final newAspiration = Aspiration(
        id: 'asp_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        userId: currentUser.id,
        userName: currentUser.name,
        userRole: currentUser.roleDisplayName,
        isAnonymous: isAnonymous,
        upvoteCount: 0,
        upvotedByUserIds: [],
        status: AspirationStatus.pending,
        createdAt: DateTime.now(),
      );
      _mockAspirations.add(newAspiration);
      return newAspiration;
    } else {
      try {
        final newAspiration = Aspiration(
          id: 'asp_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          category: category,
          userId: currentUser.id,
          userName: currentUser.name,
          userRole: currentUser.roleDisplayName,
          isAnonymous: isAnonymous,
          upvoteCount: 0,
          upvotedByUserIds: [],
          status: AspirationStatus.pending,
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('aspirations').insert(newAspiration.toJson());
        return newAspiration;
      } catch (e) {
        throw Exception('Gagal mengirimkan aspirasi ke Supabase: $e');
      }
    }
  }

  static Future<Aspiration> toggleUpvote(String token, String aspirationId, String userId) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockAspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        final aspiration = _mockAspirations[index];
        final list = List<String>.from(aspiration.upvotedByUserIds);
        int count = aspiration.upvoteCount;
        
        if (list.contains(userId)) {
          list.remove(userId);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(userId);
          count += 1;
        }
        
        final updated = aspiration.copyWith(
          upvotedByUserIds: list,
          upvoteCount: count,
        );
        _mockAspirations[index] = updated;
        return updated;
      }
      throw Exception('Aspirasi tidak ditemukan.');
    } else {
      try {
        final data = await Supabase.instance.client
            .from('aspirations')
            .select()
            .eq('id', aspirationId)
            .single();
        
        final aspiration = Aspiration.fromJson(data);
        final list = List<String>.from(aspiration.upvotedByUserIds);
        int count = aspiration.upvoteCount;
        
        if (list.contains(userId)) {
          list.remove(userId);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(userId);
          count += 1;
        }
        
        final response = await Supabase.instance.client
            .from('aspirations')
            .update({
              'upvoted_by_user_ids': list,
              'upvote_count': count,
            })
            .eq('id', aspirationId)
            .select()
            .single();
        
        return Aspiration.fromJson(response);
      } catch (e) {
        throw Exception('Gagal mengubah upvote di Supabase: $e');
      }
    }
  }

  static Future<Aspiration> updateStatus(
    String token,
    String aspirationId,
    AspirationStatus status,
  ) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _mockAspirations.indexWhere((a) => a.id == aspirationId);
      if (index != -1) {
        final updated = _mockAspirations[index].copyWith(status: status);
        _mockAspirations[index] = updated;
        return updated;
      }
      throw Exception('Aspirasi tidak ditemukan.');
    } else {
      try {
        final response = await Supabase.instance.client
            .from('aspirations')
            .update({
              'status': status.name,
            })
            .eq('id', aspirationId)
            .select()
            .single();
        
        return Aspiration.fromJson(response);
      } catch (e) {
        throw Exception('Gagal mengubah status di Supabase: $e');
      }
    }
  }

  // --- DISCUSSIONS / COMMENTS ---

  static Future<List<Comment>> getComments(String? token, String aspirationId) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final list = _mockComments.where((c) => c.aspirationId == aspirationId).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest comment first (thread flow)
      return list;
    } else {
      try {
        final response = await Supabase.instance.client
            .from('comments')
            .select()
            .eq('aspiration_id', aspirationId)
            .order('created_at', ascending: true);
        
        final List list = response as List;
        return list.map((item) => Comment.fromJson(item)).toList();
      } catch (e) {
        throw Exception('Gagal memuat diskusi dari Supabase: $e');
      }
    }
  }

  static Future<Comment> addComment({
    required String token,
    required String aspirationId,
    required String content,
    required User currentUser,
  }) async {
    if (AppConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final newComment = Comment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        aspirationId: aspirationId,
        userId: currentUser.id,
        userName: currentUser.name,
        userRole: currentUser.roleDisplayName,
        content: content,
        createdAt: DateTime.now(),
      );
      _mockComments.add(newComment);
      return newComment;
    } else {
      try {
        final newComment = Comment(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          aspirationId: aspirationId,
          userId: currentUser.id,
          userName: currentUser.name,
          userRole: currentUser.roleDisplayName,
          content: content,
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('comments').insert(newComment.toJson());
        return newComment;
      } catch (e) {
        throw Exception('Gagal menambahkan komentar ke Supabase: $e');
      }
    }
  }
}

