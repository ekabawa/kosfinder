import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/my_kos_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock Repositories untuk Pengujian Fitur Ubah Kos (T13)
// ---------------------------------------------------------------------------

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockError;
  Map<String, dynamic>? lastUpdatedPayload;
  String? lastUpdatedId;
  String? lastUpdatedOwnerId;

  MockKosRepository({this.mockData = const [], this.mockError});

  @override
  Future<List<Kos>> fetchKos() async {
    if (mockError != null) throw mockError!;
    return mockData;
  }

  @override
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
    lastUpdatedId = id;
    lastUpdatedOwnerId = ownerId;
    lastUpdatedPayload = {
      'nama': nama,
      'alamat_area': alamatArea,
      'harga_per_bulan': hargaPerBulan,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'tipe_kos': tipeKos,
      'nomor_kontak': nomorKontak,
    };

    if (mockError != null) throw mockError!;

    final index = mockData.indexWhere((k) => k.id == id);
    final updated = Kos(
      id: id,
      ownerId: ownerId,
      nama: nama,
      alamatArea: alamatArea,
      hargaPerBulan: hargaPerBulan,
      deskripsi: deskripsi,
      fasilitas: fasilitas,
      tipeKos: tipeKos,
      nomorKontak: nomorKontak,
      createdAt: index != -1
          ? mockData[index].createdAt
          : DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.now(),
    );

    if (index != -1) {
      mockData[index] = updated;
    }
    return updated;
  }
}

class MockAuthRepository extends AuthRepository {
  User? mockUser;

  MockAuthRepository({this.mockUser});

  @override
  User? get currentUser => mockUser;

  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

// ---------------------------------------------------------------------------
// Data Helpers
// ---------------------------------------------------------------------------

User buildFakeUser({
  String id = 'owner-uuid-001',
  String email = 'pemilik@kosfinder.com',
}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: email,
  );
}

Kos buildFakeKos({
  String id = 'kos-uuid-101',
  String ownerId = 'owner-uuid-001',
  String nama = 'Kos Asri Bahari',
  String alamatArea = 'Jalan Kampus Jimbaran',
  int hargaPerBulan = 800000,
  String deskripsi = 'Kos bersih, nyaman, dan strategis dekat kampus.',
  String fasilitas = 'WiFi, Kasur, Kamar Mandi Dalam',
  String tipeKos = 'Campur',
  String nomorKontak = '081234567890',
}) {
  return Kos(
    id: id,
    ownerId: ownerId,
    nama: nama,
    alamatArea: alamatArea,
    hargaPerBulan: hargaPerBulan,
    deskripsi: deskripsi,
    fasilitas: fasilitas,
    tipeKos: tipeKos,
    nomorKontak: nomorKontak,
    createdAt: DateTime.parse('2026-11-20T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-20T10:00:00.000Z'),
  );
}

// ---------------------------------------------------------------------------
// Test Suite: Fitur Ubah Kos (T13 / US07)
// ---------------------------------------------------------------------------

void main() {
  group('Fitur Ubah Kos Milik Sendiri (Update) Tests (T13)', () {
    void setupLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Widget createFormTestWidget({
      required KosProvider kosProvider,
      required AuthProvider authProvider,
      Kos? existingKos,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          home: KosFormScreen(kos: existingKos),
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 1 & 2. Form edit terisi otomatis dengan data kos yang dipilih
    // -----------------------------------------------------------------------
    testWidgets(
      '1 & 2. Membuka form edit menampilkan judul Ubah dan seluruh field terisi otomatis',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final initialKos = buildFakeKos();
        final user = buildFakeUser(id: initialKos.ownerId);

        final kosRepo = MockKosRepository(mockData: [initialKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createFormTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
          existingKos: initialKos,
        ));
        await tester.pumpAndSettle();

        // 1. Judul AppBar dalam mode edit
        expect(find.text('Ubah Informasi Kos'), findsOneWidget);
        expect(find.text('Tambah Kos Baru'), findsNothing);

        // 2. Seluruh field terisi dengan data lama
        expect(find.text('Kos Asri Bahari'), findsOneWidget);
        expect(find.text('Jalan Kampus Jimbaran'), findsOneWidget);
        expect(find.text('800000'), findsOneWidget);
        expect(find.text('Kos bersih, nyaman, dan strategis dekat kampus.'), findsOneWidget);
        expect(find.text('WiFi, Kasur, Kamar Mandi Dalam'), findsOneWidget);
        expect(find.text('Campur'), findsOneWidget);
        expect(find.text('081234567890'), findsOneWidget);

        // Label tombol simpan
        expect(find.text('Simpan Perubahan'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 3 & 8. Perubahan data berhasil dikirim dan owner_id tidak berubah
    // -----------------------------------------------------------------------
    testWidgets(
      '3 & 8. Menyimpan perubahan data berhasil memanggil updateKos dan owner_id tidak berubah (US07-AC1)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final initialKos = buildFakeKos();
        final user = buildFakeUser(id: initialKos.ownerId);

        final kosRepo = MockKosRepository(mockData: [initialKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createFormTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
          existingKos: initialKos,
        ));
        await tester.pumpAndSettle();

        // Ubah beberapa field
        final namaFinder = find.byKey(const Key('nama_field'));
        final hargaFinder = find.byKey(const Key('harga_field'));
        final fasilitasFinder = find.byKey(const Key('fasilitas_field'));

        await tester.enterText(namaFinder, 'Kos Asri Bahari VIP');
        await tester.enterText(hargaFinder, '950000');
        await tester.enterText(fasilitasFinder, 'WiFi, AC, Kamar Mandi Dalam');

        // Tekan tombol Simpan Perubahan
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Verifikasi payload yang dikirim ke repository
        expect(kosRepo.lastUpdatedId, equals(initialKos.id));
        expect(kosRepo.lastUpdatedOwnerId, equals(initialKos.ownerId));
        expect(kosRepo.lastUpdatedPayload?['nama'], equals('Kos Asri Bahari VIP'));
        expect(kosRepo.lastUpdatedPayload?['harga_per_bulan'], equals(950000));
        expect(kosRepo.lastUpdatedPayload?['fasilitas'], equals('WiFi, AC, Kamar Mandi Dalam'));

        // Payload tidak boleh memuat atau mengubah owner_id
        expect(kosRepo.lastUpdatedPayload?.containsKey('owner_id'), isFalse);

        // SnackBar sukses tampil
        expect(find.text('Data kos berhasil diperbarui!'), findsOneWidget);

        // Data terupdate langsung tersimpan dan tercermin pada provider
        expect(
          kosProvider.allKos.firstWhere((k) => k.id == initialKos.id).nama,
          equals('Kos Asri Bahari VIP'),
        );
      },
    );

    // -----------------------------------------------------------------------
    // 4. Validasi field wajib kosong dan harga tidak valid pada mode edit
    // -----------------------------------------------------------------------
    testWidgets(
      '4. Menolak update jika field wajib dikosongkan atau harga tidak valid',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final initialKos = buildFakeKos();
        final user = buildFakeUser(id: initialKos.ownerId);

        final kosRepo = MockKosRepository(mockData: [initialKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createFormTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
          existingKos: initialKos,
        ));
        await tester.pumpAndSettle();

        // Kosongkan nama kos
        await tester.enterText(find.byKey(const Key('nama_field')), '');
        // Isi harga dengan teks non-angka
        await tester.enterText(find.byKey(const Key('harga_field')), 'gratis');

        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Pesan validasi muncul
        expect(find.text('Nama kos wajib diisi'), findsOneWidget);
        expect(find.text('Harga harus berupa angka yang valid'), findsOneWidget);

        // Repository tidak dipanggil
        expect(kosRepo.lastUpdatedId, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // 5. Kegagalan jaringan menampilkan pesan error dan mempertahankan input
    // -----------------------------------------------------------------------
    testWidgets(
      '5. Kegagalan jaringan menampilkan error banner dan mempertahankan nilai input form',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final initialKos = buildFakeKos();
        final user = buildFakeUser(id: initialKos.ownerId);

        final kosRepo = MockKosRepository(
          mockData: [initialKos],
          mockError: Exception('Koneksi database terputus saat update'),
        );
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createFormTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
          existingKos: initialKos,
        ));
        await tester.pumpAndSettle();

        // Masukkan data baru
        await tester.enterText(find.byKey(const Key('nama_field')), 'Kos Diperbarui Offline');

        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Error banner tampil
        expect(find.byKey(const Key('kos_form_error_banner')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('kos_form_error_banner')),
            matching: find.textContaining('Koneksi database terputus'),
          ),
          findsOneWidget,
        );

        // Input pengguna tidak hilang
        expect(find.text('Kos Diperbarui Offline'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 6. Tombol Ubah di MyKosScreen membuka form dan memperbarui daftar setelah sukses
    // -----------------------------------------------------------------------
    testWidgets(
      '6. Mengetuk tombol Ubah di MyKosScreen membuka form edit dan memperbarui daftar',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final initialKos = buildFakeKos();
        final user = buildFakeUser(id: initialKos.ownerId);

        final kosRepo = MockKosRepository(mockData: [initialKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ],
            child: const MaterialApp(
              home: MyKosScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ketuk tombol Ubah
        expect(find.byKey(const Key('edit_kos_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('edit_kos_button')));
        await tester.pumpAndSettle();

        // Form edit terbuka
        expect(find.byType(KosFormScreen), findsOneWidget);
        expect(find.text('Ubah Informasi Kos'), findsOneWidget);

        // Ubah nama
        await tester.enterText(find.byKey(const Key('nama_field')), 'Kos Asri Bahari Terupdate');

        // Simpan
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Kembali ke MyKosScreen dan data terupdate
        expect(find.byType(MyKosScreen), findsOneWidget);
        expect(find.text('Kos Asri Bahari Terupdate'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 7. Pengguna tidak dapat mengubah kos milik akun lain (US07-AC2)
    // -----------------------------------------------------------------------
    testWidgets(
      '7. Menolak update jika akun yang login berbeda dengan owner_id data kos (US07-AC2)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        // Kos milik orang lain
        final otherKos = buildFakeKos(ownerId: 'owner-uuid-999');
        // Pengguna aktif yang bukan pemilik kos
        final activeUser = buildFakeUser(id: 'owner-uuid-001');

        final kosRepo = MockKosRepository(mockData: [otherKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: activeUser);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createFormTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
          existingKos: otherKos,
        ));
        await tester.pumpAndSettle();

        // Coba simpan perubahan
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Validasi penolakan muncul dan repository tidak dipanggil
        expect(find.text('Anda tidak memiliki izin untuk mengubah data kos ini.'), findsOneWidget);
        expect(kosRepo.lastUpdatedId, isNull);
      },
    );
  });
}
