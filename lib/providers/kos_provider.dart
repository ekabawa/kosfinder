import 'package:flutter/foundation.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

/// Provider untuk mengelola state data kos, status pemuatan (loading),
/// dan penanganan pesan kesalahan (error).
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  List<Kos> _kosList = [];
  bool _isLoading = false;
  String? _errorMessage;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  /// Daftar kos yang berhasil dimuat.
  List<Kos> get kosList => List.unmodifiable(_kosList);

  /// Status apakah proses pemuatan data sedang berlangsung.
  bool get isLoading => _isLoading;

  /// Pesan galat jika terjadi kegagalan pemuatan data.
  String? get errorMessage => _errorMessage;

  /// Apakah saat ini terdapat status error.
  bool get hasError => _errorMessage != null;

  /// Apakah daftar kos dalam keadaan kosong setelah selesai dimuat tanpa error.
  bool get isEmpty => !_isLoading && _errorMessage == null && _kosList.isEmpty;

  /// Memuat daftar kos dari repository.
  ///
  /// Mengatur [_isLoading] menjadi true sebelum request dan memberitahu listeners.
  /// Menangkap kesalahan jaringan/database dan menyimpannya di [_errorMessage].
  Future<void> loadKos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = await _repository.fetchKos();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _kosList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memuat ulang data kos (refresh).
  Future<void> refresh() => loadKos();
}

