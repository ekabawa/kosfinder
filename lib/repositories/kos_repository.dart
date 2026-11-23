import 'package:kosfinder/models/kos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk mengelola akses data kos dari database Supabase.
class KosRepository {
  final SupabaseClient? _customClient;

  KosRepository({SupabaseClient? client}) : _customClient = client;

  /// Mengambil instance [SupabaseClient] yang tersedia.
  SupabaseClient get client => _customClient ?? Supabase.instance.client;

  /// Mengambil seluruh daftar kos dari tabel `public.kos` di Supabase.
  ///
  /// Data diurutkan berdasarkan `created_at` secara menurun (terbaru dahulu).
  /// Melempar [Exception] jika terjadi kesalahan jaringan atau database.
  Future<List<Kos>> fetchKos() async {
    try {
      final response = await client
          .from('kos')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => Kos.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data dari database: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }
}

