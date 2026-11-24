import 'package:kosfinder/models/kos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk mengelola akses data kos dari database Supabase.
class KosRepository {
  final SupabaseClient? _customClient;

  KosRepository({SupabaseClient? client}) : _customClient = client;

  /// Mengambil instance [SupabaseClient] yang tersedia.
  ///
  /// Mengembalikan [_customClient] jika disuplai saat inisialisasi, atau
  /// [Supabase.instance.client] dari instance global yang telah diinisialisasi.
  /// Melempar [Exception] dengan pesan jelas jika Supabase belum diinisialisasi.
  SupabaseClient get client {
    if (_customClient != null) {
      return _customClient;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception(
        'Layanan Supabase belum diinisialisasi. Pastikan koneksi dan inisialisasi aplikasi telah selesai.',
      );
    }
  }

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

  /// Menambahkan data kos baru ke tabel `public.kos` di database Supabase.
  ///
  /// Mengembalikan objek [Kos] yang berhasil dibuat dari respon database.
  /// Melempar [Exception] jika terjadi kegagalan jaringan atau penolakan RLS.
  Future<Kos> createKos({
    required String ownerId,
    required String nama,
    required String alamatArea,
    required int hargaPerBulan,
    required String deskripsi,
    required String fasilitas,
    required String tipeKos,
    required String nomorKontak,
  }) async {
    try {
      final payload = {
        'owner_id': ownerId,
        'nama': nama,
        'alamat_area': alamatArea,
        'harga_per_bulan': hargaPerBulan,
        'deskripsi': deskripsi,
        'fasilitas': fasilitas,
        'tipe_kos': tipeKos,
        'nomor_kontak': nomorKontak,
      };

      final response =
          await client.from('kos').insert(payload).select().single();

      return Kos.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menambahkan kos: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// Memperbarui data kos yang ada pada tabel `public.kos` di database Supabase.
  ///
  /// Hanya dapat memperbarui unit kos dengan [id] dan [ownerId] yang sesuai (RLS).
  /// Kolom `owner_id` tidak dapat diubah melalui metode ini untuk menjaga integritas data.
  /// Mengembalikan objek [Kos] yang telah diperbarui dari database.
  /// Melempar [Exception] jika terjadi kegagalan jaringan atau penolakan RLS.
  Future<Kos> updateKos({
    required String id,
    required String ownerId,
    required String nama,
    required String alamatArea,
    required int hargaPerBulan,
    required String deskripsi,
    required String fasilitas,
    required String tipeKos,
    required String nomorKontak,
  }) async {
    try {
      final payload = {
        'nama': nama,
        'alamat_area': alamatArea,
        'harga_per_bulan': hargaPerBulan,
        'deskripsi': deskripsi,
        'fasilitas': fasilitas,
        'tipe_kos': tipeKos,
        'nomor_kontak': nomorKontak,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('kos')
          .update(payload)
          .eq('id', id)
          .eq('owner_id', ownerId)
          .select()
          .single();

      return Kos.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui kos: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// Menghapus data kos dari tabel `public.kos` di database Supabase.
  ///
  /// Hanya dapat menghapus unit kos dengan [id] dan [ownerId] yang sesuai (RLS).
  /// Melempar [Exception] jika terjadi kegagalan jaringan atau penolakan RLS.
  Future<void> deleteKos({
    required String id,
    required String ownerId,
  }) async {
    try {
      await client
          .from('kos')
          .delete()
          .eq('id', id)
          .eq('owner_id', ownerId);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus kos: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }
}

