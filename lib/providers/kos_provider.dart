import 'package:flutter/foundation.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

/// Provider untuk mengelola state data kos, status pemuatan (loading),
/// penanganan pesan kesalahan (error), serta logika pencarian dan filter harga.
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  List<Kos> _kosList = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;

  String _searchQuery = '';
  int? _maxPrice;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  /// Daftar kos yang telah difilter berdasarkan kata kunci pencarian dan batas harga.
  List<Kos> get kosList {
    final query = _searchQuery.trim().toLowerCase();
    return _kosList.where((kos) {
      // 1. Pencarian case-insensitive berdasarkan nama atau alamat/area
      final matchesQuery = query.isEmpty ||
          kos.nama.toLowerCase().contains(query) ||
          kos.alamatArea.toLowerCase().contains(query);

      // 2. Filter harga maksimum (harga_per_bulan <= harga_maksimum)
      final matchesPrice = _maxPrice == null || kos.hargaPerBulan <= _maxPrice!;

      return matchesQuery && matchesPrice;
    }).toList();
  }

  /// Seluruh daftar kos asli sebelum diterapkan filter atau pencarian.
  List<Kos> get allKos => List.unmodifiable(_kosList);

  /// Kata kunci pencarian yang sedang aktif.
  String get searchQuery => _searchQuery;

  /// Batas harga maksimum yang sedang aktif.
  int? get maxPrice => _maxPrice;

  /// Status apakah pencarian atau filter harga sedang aktif.
  bool get isFilterActive => _searchQuery.trim().isNotEmpty || _maxPrice != null;

  /// Status apakah proses pemuatan data sedang berlangsung.
  bool get isLoading => _isLoading;

  /// Status apakah proses penyimpanan kos baru sedang berlangsung.
  bool get isCreating => _isCreating;

  /// Pesan galat jika terjadi kegagalan pemuatan data.
  String? get errorMessage => _errorMessage;

  /// Apakah saat ini terdapat status error.
  bool get hasError => _errorMessage != null;

  /// Apakah daftar kos di database kosong setelah pemuatan tanpa error.
  bool get isEmpty => !_isLoading && _errorMessage == null && _kosList.isEmpty;

  /// Apakah hasil pencarian / filter kosong meskipun data di database tersedia.
  bool get isFilteredEmpty =>
      !_isLoading && _errorMessage == null && _kosList.isNotEmpty && kosList.isEmpty;

  /// Mengatur kata kunci pencarian (nama atau alamat/area).
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Mengatur batas nominal harga sewa maksimum per bulan.
  void setMaxPrice(int? price) {
    _maxPrice = price;
    notifyListeners();
  }

  /// Menghapus seluruh filter dan kata kunci pencarian.
  void clearFilters() {
    _searchQuery = '';
    _maxPrice = null;
    notifyListeners();
  }

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

  /// Menghapus pesan galat error yang tersimpan.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Menambahkan data kos baru ke database melalui [KosRepository].
  ///
  /// Mengembalikan objek [Kos] jika berhasil disimpan, atau `null` jika terjadi kegagalan.
  /// Menambahkan data baru ke daftar lokal [_kosList] agar langsung tampil.
  Future<Kos?> createKos({
    required String ownerId,
    required String nama,
    required String alamatArea,
    required int hargaPerBulan,
    required String deskripsi,
    required String fasilitas,
    required String tipeKos,
    required String nomorKontak,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newKos = await _repository.createKos(
        ownerId: ownerId,
        nama: nama,
        alamatArea: alamatArea,
        hargaPerBulan: hargaPerBulan,
        deskripsi: deskripsi,
        fasilitas: fasilitas,
        tipeKos: tipeKos,
        nomorKontak: nomorKontak,
      );

      _kosList.insert(0, newKos);
      _errorMessage = null;
      return newKos;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
}
