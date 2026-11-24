import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi koneksi Supabase untuk aplikasi KosFinder.
///
/// Mendukung pembacaan dari `flutter_dotenv` (.env) dan `--dart-define` (String.fromEnvironment).
class SupabaseConfig {
  /// URL endpoint project Supabase.
  static String get url {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('SUPABASE_URL') ?? '';
  }

  /// Publishable key publik untuk konektivitas client Supabase.
  static String get anonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) return envKey;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
  }
}
