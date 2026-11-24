import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

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
      nama: 'Kos Melati Cantik',
      alamatArea: 'Jalan Sudirman, Jimbaran',
      hargaPerBulan: 750000,
      deskripsi: 'Kos nyaman dekat kampus',
      fasilitas: 'WiFi, Kamar Mandi Dalam',
      tipeKos: 'Putri',
      nomorKontak: '0811111111',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    ),
    Kos(
      id: '2',
      ownerId: 'owner-2',
      nama: 'Kos Graha Mahasiswa',
      alamatArea: 'Gang Kampus, Bukit Jimbaran',
      hargaPerBulan: 1200000,
      deskripsi: 'Kos eksklusif mahasiswa',
      fasilitas: 'AC, WiFi, Parkir Luas',
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
      deskripsi: 'Suasana tenang',
      fasilitas: 'Kamar Mandi Luar',
      tipeKos: 'Campur',
      nomorKontak: '0833333333',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    ),
  ];

  Widget createTestWidget(KosProvider provider) {
    return ChangeNotifierProvider<KosProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: KosListScreen(),
      ),
    );
  }

  group('KosListScreen Search & Filter Widget Tests (T08)', () {
    testWidgets(
      '1. Mengetikkan kata kunci pada TextField pencarian memperbarui daftar kos (US03-AC1)',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Seluruh kos awal tampil
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);

        // Ketik kata kunci pencarian nama "Melati"
        final searchField = find.byKey(const Key('search_field'));
        expect(searchField, findsOneWidget);
        await tester.enterText(searchField, 'Melati');
        await tester.pumpAndSettle();

        // Hanya Kos Melati Cantik yang tampil
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsNothing);
        expect(find.text('Pondok Asri Singaraja'), findsNothing);

        // Cari berdasarkan area "Singaraja"
        await tester.enterText(searchField, 'Singaraja');
        await tester.pumpAndSettle();

        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
        expect(find.text('Kos Melati Cantik'), findsNothing);
      },
    );

    testWidgets(
      '2. Pencarian kata kunci melalui UI bersifat case-insensitive',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_field'));

        // Huruf kapital "JIMBARAN"
        await tester.enterText(searchField, 'JIMBARAN');
        await tester.pumpAndSettle();

        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsNothing);

        // Huruf kecil "jimbaran"
        await tester.enterText(searchField, 'jimbaran');
        await tester.pumpAndSettle();

        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Memasukkan nilai batas harga sewa maksimum memfilter daftar kos (US04-AC1)',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final priceField = find.byKey(const Key('price_field'));
        expect(priceField, findsOneWidget);

        // Masukkan batas harga 750.000
        await tester.enterText(priceField, '750000');
        await tester.pumpAndSettle();

        // Kos <= 750.000 tampil (600rb & 750rb), kos > 750.000 (1.2jt) disembunyikan
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsNothing);

        // Perketat batas harga menjadi 600.000
        await tester.enterText(priceField, '600000');
        await tester.pumpAndSettle();

        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
        expect(find.text('Kos Melati Cantik'), findsNothing);
      },
    );

    testWidgets(
      '4. Uji kombinasi pencarian kata kunci dan batas harga maksimum secara bersamaan',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_field'));
        final priceField = find.byKey(const Key('price_field'));

        // Cari "Jimbaran" (ada 2 kos: 750rb dan 1.2jt)
        await tester.enterText(searchField, 'Jimbaran');
        await tester.pumpAndSettle();
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);

        // Terapkan batas harga 800.000 -> hanya Kos Melati Cantik yang memenuhi
        await tester.enterText(priceField, '800000');
        await tester.pumpAndSettle();

        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsNothing);
      },
    );

    testWidgets(
      '5. Memverifikasi pesan "Kos Tidak Ditemukan" tampil saat hasil filter kosong (US03-AC2 & US04-AC2)',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_field'));

        // Masukkan kata kunci yang tidak ada pada data
        await tester.enterText(searchField, 'Denpasar Timur');
        await tester.pumpAndSettle();

        // Pesan kosong tampil
        expect(find.text('Kos Tidak Ditemukan'), findsOneWidget);
        expect(
          find.text(
            'Tidak ada kos yang cocok dengan kata kunci atau filter harga yang Anda terapkan.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);

        // Verifikasi tombol Reset Filter pada empty state
        final emptyResetButton = find.text('Reset Filter');
        expect(emptyResetButton, findsOneWidget);

        await tester.tap(emptyResetButton);
        await tester.pumpAndSettle();

        // Setelah di-reset, daftar kos kembali muncul
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Tombol reset filter pada header mengosongkan input dan mengembalikan seluruh kos',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_field'));
        final priceField = find.byKey(const Key('price_field'));

        await tester.enterText(searchField, 'Graha');
        await tester.enterText(priceField, '1500000');
        await tester.pumpAndSettle();

        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Kos Melati Cantik'), findsNothing);

        // Tombol reset filter pada row harga
        final resetIconButton = find.byKey(const Key('reset_filter_button'));
        expect(resetIconButton, findsOneWidget);

        await tester.tap(resetIconButton);
        await tester.pumpAndSettle();

        // Seluruh daftar kos kembali tampil
        expect(find.text('Kos Melati Cantik'), findsOneWidget);
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Navigasi ke Detail Kos tetap berfungsi dari kartu kos hasil pencarian',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: sampleKosList);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_field'));
        await tester.enterText(searchField, 'Singaraja');
        await tester.pumpAndSettle();

        // Ketuk kartu kos hasil pencarian
        await tester.tap(find.text('Pondok Asri Singaraja'));
        await tester.pumpAndSettle();

        // Verifikasi KosDetailScreen terbuka
        expect(find.byType(KosDetailScreen), findsOneWidget);
        expect(find.text('Detail Kos'), findsOneWidget);
        expect(find.text('Pondok Asri Singaraja'), findsOneWidget);
      },
    );
  });
}

