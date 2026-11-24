import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk mengelola autentikasi pengguna via Supabase Auth.
///
/// Menyediakan operasi registrasi, login, logout, dan pengecekan sesi aktif.
/// Seluruh akses Supabase Auth dilakukan melalui kelas ini untuk kemudahan pengujian.
class AuthRepository {
  final GoTrueClient? _customAuthClient;

  AuthRepository({GoTrueClient? authClient}) : _customAuthClient = authClient;

  /// Mengambil instance [GoTrueClient] yang tersedia.
  ///
  /// Mengembalikan [_customAuthClient] jika disuplai saat inisialisasi, atau
  /// [Supabase.instance.client.auth] dari instance global yang telah diinisialisasi.
  /// Melempar [Exception] dengan pesan jelas jika Supabase belum diinisialisasi.
  GoTrueClient get _auth {
    if (_customAuthClient != null) {
      return _customAuthClient;
    }
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      throw Exception(
        'Layanan autentikasi Supabase belum diinisialisasi. Pastikan koneksi dan inisialisasi aplikasi telah selesai.',
      );
    }
  }

  /// Mendaftarkan akun pemilik baru menggunakan email dan password.
  ///
  /// Mengembalikan [AuthResponse] yang berisi data sesi dan user jika berhasil.
  /// Melempar [Exception] jika email sudah terdaftar, format tidak valid, atau
  /// terjadi kegagalan jaringan.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Registrasi gagal: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// Melakukan login menggunakan email dan password.
  ///
  /// Mengembalikan [AuthResponse] yang berisi data sesi dan user aktif jika berhasil.
  /// Melempar [Exception] jika kredensial salah, akun belum dikonfirmasi, atau
  /// terjadi kegagalan jaringan.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Login gagal: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// Melakukan logout dari sesi aktif pengguna saat ini.
  ///
  /// Melempar [Exception] jika terjadi kegagalan jaringan.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Logout gagal: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }

  /// Mengambil data user yang sedang aktif (login).
  ///
  /// Mengembalikan [User] jika ada sesi aktif, atau `null` jika tidak ada sesi
  /// atau layanan Supabase belum diinisialisasi.
  User? get currentUser {
    try {
      if (_customAuthClient != null) {
        return _customAuthClient.currentUser;
      }
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }
}

