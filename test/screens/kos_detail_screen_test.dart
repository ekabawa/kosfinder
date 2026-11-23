import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

class MockKosRepository extends KosRepository {
  final List<Kos> mockData;

  MockKosRepository({this.mockData = const []});

  @override
  Future<List<Kos>> fetchKos() async {
    return mockData;
  }
}

void main() {
  final dummyKos1 = Kos(
    id: 'kos-1',
    ownerId: 'owner-1',
    nama: 'Kos Melati Cantik',
    alamatArea: 'Jalan Sudirman No. 12, Singaraja',
    hargaPerBulan: 850000,
    deskripsi: 'Kos bersih, nyaman, dan tenang dekat dengan kampus.',
    fasilitas: 'WiFi, Kasur, Kamar Mandi Dalam, Lemari',
    tipeKos: 'Putri',
    nomorKontak: '081234567890',
    createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
  );

  final dummyKos2 = Kos(
    id: 'kos-2',
    ownerId: 'owner-2',
    nama: 'Kos Graha Mahasiswa',
    alamatArea: 'Jalan Udayana, Jimbaran',
    hargaPerBulan: 1200000,
    deskripsi: 'Lokasi strategis hanya 5 menit jalan kaki ke kampus.',
    fasilitas: 'AC, WiFi Cepat, Parkir Luas, Dapur Bersama',
    tipeKos: 'Putra',
    nomorKontak: '089876543210',
    createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
  );

  group('KosDetailScreen Widget Tests', () {
    Widget createDetailWidget(Kos kos) {
      return MaterialApp(
        home: KosDetailScreen(kos: kos),
      );
    }

    testWidgets(
      'Menampilkan seluruh informasi detail kos secara lengkap (US02-AC1)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createDetailWidget(dummyKos1));
        await tester.pumpAndSettle();

        // 1. Verifikasi Judul AppBar
        expect(find.text('Detail Kos'), findsOneWidget);

        // 2. Verifikasi Nama Kos
        expect(find.text('Kos Melati Cantik'), findsOneWidget);

        // 3. Verifikasi Tipe Kos
        expect(find.text('Putri'), findsOneWidget);

        // 4. Verifikasi Harga Sewa
        expect(find.text('Rp 850.000 / bulan'), findsOneWidget);

        // 5. Verifikasi Alamat / Area
        expect(find.text('Jalan Sudirman No. 12, Singaraja'), findsOneWidget);

        // 6. Verifikasi Fasilitas
        expect(
          find.text('WiFi, Kasur, Kamar Mandi Dalam, Lemari'),
          findsOneWidget,
        );

        // 7. Verifikasi Deskripsi
        expect(
          find.text('Kos bersih, nyaman, dan tenang dekat dengan kampus.'),
          findsOneWidget,
        );

        // 8. Verifikasi Nomor Kontak Pemilik (Teks)
        expect(find.text('081234567890'), findsOneWidget);
        expect(
          find.text('Kontak Pemilik (WhatsApp / Telepon)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Memastikan data yang ditampilkan sesuai objek Kos yang diterima (bukan hardcode)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createDetailWidget(dummyKos2));
        await tester.pumpAndSettle();

        // Data Kos 2 harus tampil
        expect(find.text('Kos Graha Mahasiswa'), findsOneWidget);
        expect(find.text('Putra'), findsOneWidget);
        expect(find.text('Rp 1.200.000 / bulan'), findsOneWidget);
        expect(find.text('Jalan Udayana, Jimbaran'), findsOneWidget);
        expect(
          find.text('AC, WiFi Cepat, Parkir Luas, Dapur Bersama'),
          findsOneWidget,
        );
        expect(
          find.text('Lokasi strategis hanya 5 menit jalan kaki ke kampus.'),
          findsOneWidget,
        );
        expect(find.text('089876543210'), findsOneWidget);

        // Data Kos 1 TIDAK boleh tampil
        expect(find.text('Kos Melati Cantik'), findsNothing);
        expect(find.text('081234567890'), findsNothing);
      },
    );

    testWidgets(
      'Navigasi dari kartu kos pada KosListScreen ke KosDetailScreen dan kembali',
      (WidgetTester tester) async {
        final repository = MockKosRepository(mockData: [dummyKos1, dummyKos2]);
        final provider = KosProvider(repository: repository);

        await tester.pumpWidget(
          ChangeNotifierProvider<KosProvider>.value(
            value: provider,
            child: const MaterialApp(
              home: KosListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi berada di halaman daftar kos
        expect(find.byType(KosListScreen), findsOneWidget);
        expect(find.text('Kos Melati Cantik'), findsOneWidget);

        // Ketuk kartu kos pertama (Kos Melati Cantik)
        await tester.tap(find.text('Kos Melati Cantik'));
        await tester.pumpAndSettle();

        // Verifikasi layar berpindah ke KosDetailScreen
        expect(find.byType(KosDetailScreen), findsOneWidget);
        expect(find.text('Detail Kos'), findsOneWidget);
        expect(
          find.text('Kos bersih, nyaman, dan tenang dekat dengan kampus.'),
          findsOneWidget,
        );
        expect(find.text('081234567890'), findsOneWidget);

        // Ketuk tombol kembali (Back button pada AppBar)
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verifikasi kembali ke KosListScreen
        expect(find.byType(KosDetailScreen), findsNothing);
        expect(find.byType(KosListScreen), findsOneWidget);
      },
    );
  });
}

