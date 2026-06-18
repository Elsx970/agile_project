import 'package:supabase/supabase.dart';
import 'package:agile_project/core/config.dart';

class MyCustomStorage extends GotrueAsyncStorage {
  final Map<String, String> _storage = {}; 

  @override
  Future<String?> getItem({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }
}

void main() async {
  print('Initializing SupabaseClient...');
  final client = SupabaseClient(
    AppConfig.supabaseUrl,
    AppConfig.supabaseAnonKey,
    authOptions: AuthClientOptions(
      pkceAsyncStorage: MyCustomStorage(),
    ),
  );

  print('Attempting to sign up admin@unila.ac.id...');
  try {
    final response = await client.auth.signUp(
      email: 'admin@unila.ac.id',
      password: 'admin123',
      data: {
        'full_name': 'Admin Kelompok 4',
        'employee_id': 'admin',
        'role': 'admin',
      },
    );

    if (response.user != null) {
      print('SUCCESS: Admin user created successfully via SDK!');
      print('User ID: ${response.user!.id}');
    } else {
      print('FAILED: User response is null.');
    }
  } catch (e, stackTrace) {
    print('ERROR registering admin: $e');
    if (e.toString().contains('already registered') || e.toString().contains('already exists')) {
      print('Admin user already exists. That is fine.');
    } else {
      print('Registration failed: $e');
    }
  }

  print('Attempting to sign in admin@unila.ac.id...');
  try {
    final signInResponse = await client.auth.signInWithPassword(
      email: 'admin@unila.ac.id',
      password: 'admin123',
    );
    if (signInResponse.user != null) {
      print('SUCCESS: Admin user can log in successfully!');
    } else {
      print('FAILED: Login response is null.');
    }
  } catch (e) {
    print('ERROR logging in admin: $e');
  }

  print('Querying profiles for admin...');
  try {
    final profile = await client
        .from('profiles')
        .select()
        .eq('email', 'admin@unila.ac.id')
        .maybeSingle();
    print('Profile: $profile');
  } catch (e) {
    print('ERROR querying profile: $e');
  }
}

