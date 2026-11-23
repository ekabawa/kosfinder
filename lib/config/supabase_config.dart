import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi koneksi Supabase untuk aplikasi KosFinder yang dimuat via `flutter_dotenv`.
class SupabaseConfig {
  /// URL endpoint project Supabase.
  static String get url {
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('SUPABASE_URL') ?? '';
  }

  /// Publishable key publik untuk konektivitas client Supabase.
  static String get anonKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
  }
}
