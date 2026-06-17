class AppConfig {
  // Toggle this to switch between internal mock data and actual Laravel REST API
  static const bool useMockMode = false;

  // The base URL of the Laravel REST API backend
  // For local development on Android emulator, use http://10.0.2.2:8000/api
  // For other platforms, use http://localhost:8000/api or your host IP
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

  // Supabase Configurations
  static const String supabaseUrl = 'https://vplaaunumxfdkucbyjrn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_q5LwHictWf78sWAXT_d6fg_us7iZOwG';
}
