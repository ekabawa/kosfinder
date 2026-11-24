import 'package:flutter/foundation.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk mengelola state autentikasi pemilik kos.
///
/// Menyediakan state user aktif, status loading, dan pesan error,
/// serta meneruskan operasi autentikasi ke [AuthRepository].
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    // Inisialisasi state user dari sesi yang sudah ada
    _currentUser = _repository.currentUser;
  }

  /// User yang sedang aktif (login). `null` jika tidak ada sesi.
  User? get currentUser => _currentUser;

  /// Apakah user sedang dalam status login.
  bool get isAuthenticated => _currentUser != null;

  /// Apakah proses autentikasi sedang berlangsung.
  bool get isLoading => _isLoading;

  /// Pesan galat jika terjadi kegagalan autentikasi. `null` jika tidak ada error.
  String? get errorMessage => _errorMessage;

  /// Apakah terdapat error autentikasi.
  bool get hasError => _errorMessage != null;

  /// Mendaftarkan akun pemilik baru menggunakan email dan password.
  ///
  /// Mengatur [isLoading] menjadi `true` selama proses berlangsung.
  /// Memperbarui [currentUser] jika registrasi berhasil.
  /// Menyimpan pesan error di [errorMessage] jika gagal.
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Melakukan login menggunakan email dan password.
  ///
  /// Mengatur [isLoading] menjadi `true` selama proses berlangsung.
  /// Memperbarui [currentUser] dengan data sesi aktif jika login berhasil.
  /// Menyimpan pesan error di [errorMessage] jika gagal.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.signInWithPassword(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Melakukan logout dari sesi aktif.
  ///
  /// Membersihkan seluruh state sesi: [currentUser], [errorMessage].
  /// Menyimpan pesan error di [errorMessage] jika logout gagal.
  Future<bool> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
      _currentUser = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menghapus pesan error yang tersimpan.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

