import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockError;

  MockKosRepository({this.mockData = const [], this.mockError});

  @override
  Future<List<Kos>> fetchKos() async {
    if (mockError != null) {
      throw mockError!;
    }
    return mockData;
  }
}

void main() {
  group('KosProvider Unit Tests', () {
    final dummyKosList = [
      Kos(
        id: '1',
        ownerId: 'owner-1',
        nama: 'Kos Anggrek',
        alamatArea: 'Jimbaran',
        hargaPerBulan: 800000,
        deskripsi: 'Dekat kampus',
        fasilitas: 'Wi-Fi, AC',
        tipeKos: 'Campur',
        nomorKontak: '0811111111',
        createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      ),
      Kos(
        id: '2',
        ownerId: 'owner-2',
        nama: 'Kos Melati',
        alamatArea: 'Bukit',
        hargaPerBulan: 650000,
        deskripsi: 'Lingkungan asri',
        fasilitas: 'Wi-Fi, Kasur',
        tipeKos: 'Putri',
        nomorKontak: '0822222222',
        createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      ),
    ];

    test('Status awal provider adalah kosong dan tidak loading', () {
      final repository = MockKosRepository(mockData: []);
      final provider = KosProvider(repository: repository);

      expect(provider.kosList, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.hasError, isFalse);
      expect(provider.isEmpty, isTrue);
    });

    test('loadKos berhasil memuat data kos dan memperbarui state dengan benar', () async {
      final repository = MockKosRepository(mockData: dummyKosList);
      final provider = KosProvider(repository: repository);

      final loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      await provider.loadKos();

      // Memverifikasi transisi state loading: true kemudian false
      expect(loadingStates, contains(true));
      expect(provider.isLoading, isFalse);
      expect(provider.kosList.length, equals(2));
      expect(provider.kosList.first.nama, equals('Kos Anggrek'));
      expect(provider.hasError, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.isEmpty, isFalse);
    });

    test('loadKos menangani kondisi data kosong dari Supabase (empty state)', () async {
      final repository = MockKosRepository(mockData: []);
      final provider = KosProvider(repository: repository);

      await provider.loadKos();

      expect(provider.isLoading, isFalse);
      expect(provider.kosList, isEmpty);
      expect(provider.hasError, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.isEmpty, isTrue);
    });

    test('loadKos menangani kegagalan jaringan atau server tanpa crash', () async {
      final repository = MockKosRepository(
        mockError: Exception('Koneksi internet terputus atau server tidak merespon'),
      );
      final provider = KosProvider(repository: repository);

      await provider.loadKos();

      expect(provider.isLoading, isFalse);
      expect(provider.kosList, isEmpty);
      expect(provider.hasError, isTrue);
      expect(
        provider.errorMessage,
        equals('Koneksi internet terputus atau server tidak merespon'),
      );
      expect(provider.isEmpty, isFalse);
    });

    test('refresh memicu pemuatan ulang data pada repository', () async {
      final repository = MockKosRepository(mockData: [dummyKosList.first]);
      final provider = KosProvider(repository: repository);

      await provider.loadKos();
      expect(provider.kosList.length, equals(1));

      // Ubah data mock dan panggil refresh
      repository.mockData = dummyKosList;
      await provider.refresh();

      expect(provider.kosList.length, equals(2));
    });
  });
}

