import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/about_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockError;
  int fetchCallCount = 0;

  MockKosRepository({this.mockData = const [], this.mockError});

  @override
  Future<List<Kos>> fetchKos() async {
    fetchCallCount++;
    if (mockError != null) throw mockError!;
    return mockData;
  }
}

void main() {
  group('KosListScreen Widget Tests', () {
    final dummyKosList = [
      Kos(
        id: 'kos-1',
        ownerId: 'owner-1',
        nama: 'Kos Melati Cantik',
        alamatArea: 'Jimbaran',
        hargaPerBulan: 800000,
        deskripsi: 'Kos nyaman untuk mahasiswa',
        fasilitas: 'Wi-Fi, Kasur, AC',
        tipeKos: 'Putri',
        nomorKontak: '081234567890',
        createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      ),
      Kos(
        id: 'kos-2',
        ownerId: 'owner-2',
        nama: 'Kos Mawar Indah',
        alamatArea: 'Bukit Jimbaran',
        hargaPerBulan: 950000,
        deskripsi: 'Dekat dengan kampus',
        fasilitas: 'Wi-Fi, Kamar Mandi Dalam',
        tipeKos: 'Campur',
        nomorKontak: '089876543210',
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

    testWidgets('Menampilkan kartu kos ketika data kos tersedia (US01-AC1)', (WidgetTester tester) async {
      final repository = MockKosRepository(mockData: dummyKosList);
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(createTestWidget(provider));
      // Tunggu hingga post frame callback & async load selesai
      await tester.pumpAndSettle();

      // Verifikasi kartu kos terender
      expect(find.text('Kos Melati Cantik'), findsOneWidget);
      expect(find.text('Kos Mawar Indah'), findsOneWidget);
      expect(find.text('Putri'), findsOneWidget);
      expect(find.text('Campur'), findsOneWidget);
      expect(find.text('Jimbaran'), findsOneWidget);
      expect(find.text('Bukit Jimbaran'), findsOneWidget);
      expect(find.text('Wi-Fi, Kasur, AC'), findsOneWidget);
      expect(find.text('Rp 800.000 / bulan'), findsOneWidget);
      expect(find.text('Rp 950.000 / bulan'), findsOneWidget);
    });

    testWidgets('Menampilkan pesan informatif ketika data kos kosong (US01-AC2)', (WidgetTester tester) async {
      final repository = MockKosRepository(mockData: []);
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      // Verifikasi tampilan empty state
      expect(find.text('Belum Ada Kos Tersedia'), findsOneWidget);
      expect(find.text('Daftar kos saat ini masih kosong.'), findsOneWidget);
      expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);
    });

    testWidgets('Menampilkan pesan error dan tombol coba lagi saat koneksi gagal (US01-AC3)', (WidgetTester tester) async {
      final repository = MockKosRepository(
        mockError: Exception('Koneksi internet terputus'),
      );
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      // Verifikasi tampilan error state
      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Koneksi internet terputus'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      final retryButton = find.text('Coba Lagi');
      expect(retryButton, findsOneWidget);

      // Uji tombol coba lagi: ubah mock data dan tekan tombol
      repository.mockError = null;
      repository.mockData = dummyKosList;

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Verifikasi setelah coba lagi data berhasil tampil
      expect(find.text('Kos Melati Cantik'), findsOneWidget);
      expect(find.text('Gagal Memuat Data'), findsNothing);
    });

    testWidgets('Navigasi ke halaman About tetap berfungsi melalui tombol info di AppBar', (WidgetTester tester) async {
      final repository = MockKosRepository(mockData: dummyKosList);
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // Memverifikasi halaman About terbuka dan menampilkan identitas
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('2415051008'), findsOneWidget);
      expect(find.text('I Putu Eka Bawa Utama'), findsOneWidget);
    });
  });
}

