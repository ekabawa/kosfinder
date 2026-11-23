import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

class MockKosRepository extends KosRepository {
  List<Kos> mockData;

  MockKosRepository({this.mockData = const []});

  @override
  Future<List<Kos>> fetchKos() async {
    return mockData;
  }
}

void main() {
  final sampleKosList = [
    Kos(
      id: '1',
      ownerId: 'owner-1',
      nama: 'Kos Melati Indah',
      alamatArea: 'Jalan Sudirman, Jimbaran',
      hargaPerBulan: 750000,
      deskripsi: 'Kos strategis dekat kampus',
      fasilitas: 'WiFi, Kasur, Kamar Mandi Dalam',
      tipeKos: 'Putri',
      nomorKontak: '0811111111',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    ),
    Kos(
      id: '2',
      ownerId: 'owner-2',
      nama: 'Kos Graha Kampus',
      alamatArea: 'Gang Melati, Bukit Jimbaran',
      hargaPerBulan: 1200000,
      deskripsi: 'Fasilitas lengkap untuk mahasiswa',
      fasilitas: 'AC, WiFi Cepat, Dapur, Parkir',
      tipeKos: 'Putra',
      nomorKontak: '0822222222',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    ),
    Kos(
      id: '3',
      ownerId: 'owner-3',
      nama: 'Pondok Asri Singaraja',
      alamatArea: 'Jalan Udayana, Singaraja',
      hargaPerBulan: 600000,
      deskripsi: 'Suasana tenang dan asri',
      fasilitas: 'Kamar Mandi Luar, Lemari',
      tipeKos: 'Campur',
      nomorKontak: '0833333333',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    ),
  ];

  group('KosProvider Search & Filter Unit Tests (T07)', () {
    late KosProvider provider;

    setUp(() async {
      final repository = MockKosRepository(mockData: sampleKosList);
      provider = KosProvider(repository: repository);
      await provider.loadKos();
    });

    test('1. Uji pencarian berdasarkan nama kos', () {
      provider.setSearchQuery('Melati');

      expect(provider.kosList.length, equals(2));
      expect(provider.kosList.any((k) => k.nama == 'Kos Melati Indah'), isTrue);

      provider.setSearchQuery('Pondok');
      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.nama, equals('Pondok Asri Singaraja'));
    });

    test('2. Uji pencarian berdasarkan alamat/area kos', () {
      provider.setSearchQuery('Singaraja');

      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.alamatArea, contains('Singaraja'));
      expect(provider.kosList.first.nama, equals('Pondok Asri Singaraja'));
    });

    test('3. Uji pencarian bersifat case-insensitive (huruf besar/kecil)', () {
      // Huruf kecil
      provider.setSearchQuery('jimbaran');
      final resultLower = provider.kosList.length;

      // Huruf besar semua
      provider.setSearchQuery('JIMBARAN');
      final resultUpper = provider.kosList.length;

      // Campuran huruf besar dan kecil
      provider.setSearchQuery('JiMbArAn');
      final resultMixed = provider.kosList.length;

      expect(resultLower, equals(2));
      expect(resultUpper, equals(2));
      expect(resultMixed, equals(2));

      // Variasi "KAMPUS"
      provider.setSearchQuery('kampus');
      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.nama, equals('Kos Graha Kampus'));

      provider.setSearchQuery('KAMPUS');
      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.nama, equals('Kos Graha Kampus'));
    });

    test('4. Uji filter harga maksimum (harga_per_bulan <= harga_maksimum)', () {
      // Batas 750.000 -> mengikutsertakan 600.000 dan 750.000, tetapi mengecualikan 1.200.000
      provider.setMaxPrice(750000);

      expect(provider.kosList.length, equals(2));
      expect(provider.kosList.any((k) => k.hargaPerBulan > 750000), isFalse);
      expect(provider.kosList.map((k) => k.hargaPerBulan), containsAll([600000, 750000]));

      // Batas 1.500.000 -> seluruh kos harus masuk
      provider.setMaxPrice(1500000);
      expect(provider.kosList.length, equals(3));

      // Batas 600.000 -> hanya 1 kos termurah
      provider.setMaxPrice(600000);
      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.nama, equals('Pondok Asri Singaraja'));
    });

    test('5. Uji kombinasi pencarian teks dan filter harga maksimum secara bersamaan', () {
      provider.setSearchQuery('Jimbaran');
      provider.setMaxPrice(800000);

      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.nama, equals('Kos Melati Indah'));
      expect(provider.kosList.first.hargaPerBulan, equals(750000));

      provider.setMaxPrice(500000);
      expect(provider.kosList, isEmpty);
      expect(provider.isFilteredEmpty, isTrue);
    });

    test('6. Uji kondisi tanpa hasil (hasil pencarian/filter kosong)', () {
      provider.setSearchQuery('Denpasar Barat');

      expect(provider.kosList, isEmpty);
      expect(provider.isFilteredEmpty, isTrue);
      expect(provider.isEmpty, isFalse);

      provider.setSearchQuery('');
      provider.setMaxPrice(300000);

      expect(provider.kosList, isEmpty);
      expect(provider.isFilteredEmpty, isTrue);
      expect(provider.isEmpty, isFalse);
    });

    test('7. Uji reset filter dengan clearFilters()', () {
      provider.setSearchQuery('Singaraja');
      provider.setMaxPrice(500000);
      expect(provider.kosList, isEmpty);
      expect(provider.isFilterActive, isTrue);

      provider.clearFilters();
      expect(provider.searchQuery, isEmpty);
      expect(provider.maxPrice, isNull);
      expect(provider.isFilterActive, isFalse);
      expect(provider.kosList.length, equals(3));
    });
  });

  group('Debug Banner Configuration Widget Test', () {
    testWidgets('Pastikan debug banner tidak ditampilkan pada MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(find.byType(CheckedModeBanner), findsNothing);
    });
  });
}

