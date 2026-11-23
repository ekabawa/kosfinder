import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/config/supabase_config.dart';

void main() {
  group('SupabaseConfig Tests', () {
    test('Mengembalikan string kosong secara aman jika dotenv belum dimuat', () {
      dotenv.clean();
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.anonKey, isEmpty);
    });

    test('Mengembalikan konfigurasi URL dan AnonKey ketika dotenv telah dimuat', () {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test_anon_key_12345
''');

      expect(SupabaseConfig.url, equals('https://test.supabase.co'));
      expect(SupabaseConfig.anonKey, equals('test_anon_key_12345'));
    });
  });
}
