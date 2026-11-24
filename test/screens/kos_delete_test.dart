import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/my_kos_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock Repositories untuk Pengujian Fitur Hapus Kos (T14)
// ---------------------------------------------------------------------------

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockDeleteError;
  String? lastDeletedId;
  String? lastDeletedOwnerId;
  int deleteCallCount = 0;

  MockKosRepository({this.mockData = const [], this.mockDeleteError});

  @override
  Future<List<Kos>> fetchKos() async {
    return mockData;
  }

  @override
  Future<void> deleteKos({
    required String id,
    required String ownerId,
  }) async {
    deleteCallCount++;
    lastDeletedId = id;
    lastDeletedOwnerId = ownerId;

    if (mockDeleteError != null) {
      throw mockDeleteError!;
    }

    mockData.removeWhere((k) => k.id == id && k.ownerId == ownerId);
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
// Model Helpers
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
  required String id,
  required String ownerId,
  required String nama,
  int hargaPerBulan = 850000,
  String alamatArea = 'Jimbaran, Kuta Selatan',
  String tipeKos = 'Campur',
  String fasilitas = 'WiFi, Kamar Mandi Dalam',
  String deskripsi = 'Kos nyaman dekat kampus',
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
    createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
  );
}

// ---------------------------------------------------------------------------
// Test Widget Helper
// ---------------------------------------------------------------------------

Widget createTestWidget({
  required KosProvider kosProvider,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: const MaterialApp(
      home: MyKosScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test Suite: Fitur Hapus Kos (T14 / US08)
// ---------------------------------------------------------------------------

void main() {
  group('Fitur Hapus Kos Milik Sendiri (Delete) Tests (T14)', () {
    void setupLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    // -----------------------------------------------------------------------
    // 1. Menampilkan dialog konfirmasi saat tombol Hapus ditekan
    // -----------------------------------------------------------------------
    testWidgets(
      '1. Menekan tombol Hapus memunculkan dialog konfirmasi dengan judul dan pesan yang tepat',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const ownerId = 'owner-uuid-001';
        final user = buildFakeUser(id: ownerId);
        final kos = buildFakeKos(
          id: 'kos-del-01',
          ownerId: ownerId,
          nama: 'Kos Kenanga Indah',
        );

        final kosRepo = MockKosRepository(mockData: [kos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Verifikasi item kos dan tombol Hapus tampil
        expect(find.text('Kos Kenanga Indah'), findsOneWidget);
        expect(find.byKey(const Key('delete_kos_button')), findsOneWidget);

        // Tekan tombol Hapus
        await tester.tap(find.byKey(const Key('delete_kos_button')));
        await tester.pumpAndSettle();

        // Dialog konfirmasi harus muncul
        expect(find.byKey(const Key('delete_confirmation_dialog')), findsOneWidget);
        expect(find.text('Konfirmasi Hapus'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('delete_confirmation_dialog')),
            matching: find.textContaining('Kos Kenanga Indah'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('cancel_delete_button')), findsOneWidget);
        expect(find.byKey(const Key('confirm_delete_button')), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Pembatalan penghapusan (menekan Batal)
    // -----------------------------------------------------------------------
    testWidgets(
      '2. Menekan tombol Batal menutup dialog dan tidak menghapus kos dari daftar',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const ownerId = 'owner-uuid-001';
        final user = buildFakeUser(id: ownerId);
        final kos = buildFakeKos(
          id: 'kos-del-02',
          ownerId: ownerId,
          nama: 'Kos Mawar Jaya',
        );

        final kosRepo = MockKosRepository(mockData: [kos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Buka dialog konfirmasi
        await tester.tap(find.byKey(const Key('delete_kos_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('delete_confirmation_dialog')), findsOneWidget);

        // Tekan tombol Batal
        await tester.tap(find.byKey(const Key('cancel_delete_button')));
        await tester.pumpAndSettle();

        // Dialog tertutup dan item kos tetap ada di daftar
        expect(find.byKey(const Key('delete_confirmation_dialog')), findsNothing);
        expect(find.text('Kos Mawar Jaya'), findsOneWidget);
        expect(kosRepo.deleteCallCount, equals(0));
        expect(kosProvider.allKos.length, equals(1));
      },
    );

    // -----------------------------------------------------------------------
    // 3. Konfirmasi "Ya, Hapus" berhasil menghapus data dari daftar (US08-AC1)
    // -----------------------------------------------------------------------
    testWidgets(
      '3. Menekan Ya, Hapus memanggil deleteKos, menghapus kos dari daftar, dan menampilkan notifikasi sukses (US08-AC1)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const ownerId = 'owner-uuid-001';
        final user = buildFakeUser(id: ownerId);
        final kos1 = buildFakeKos(
          id: 'kos-del-03a',
          ownerId: ownerId,
          nama: 'Kos Anggrek Ungu',
        );
        final kos2 = buildFakeKos(
          id: 'kos-del-03b',
          ownerId: ownerId,
          nama: 'Kos Melati Putih',
        );

        final kosRepo = MockKosRepository(mockData: [kos1, kos2]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Kos Anggrek Ungu'), findsOneWidget);
        expect(find.text('Kos Melati Putih'), findsOneWidget);

        // Hapus kos pertama ('Kos Anggrek Ungu')
        await tester.tap(find.byKey(const Key('delete_kos_button')));
        await tester.pumpAndSettle();

        // Konfirmasi hapus
        await tester.tap(find.byKey(const Key('confirm_delete_button')));
        await tester.pumpAndSettle();

        // Verifikasi pemanggilan ke repository
        expect(kosRepo.deleteCallCount, equals(1));
        expect(kosRepo.lastDeletedId, equals('kos-del-03a'));
        expect(kosRepo.lastDeletedOwnerId, equals(ownerId));

        // Kos Anggrek Ungu hilang dari tampilan, Kos Melati Putih tetap ada
        expect(find.text('Kos Anggrek Ungu'), findsNothing);
        expect(find.text('Kos Melati Putih'), findsOneWidget);

        // State provider terupdate
        expect(kosProvider.allKos.any((k) => k.id == 'kos-del-03a'), isFalse);
        expect(kosProvider.allKos.length, equals(1));

        // SnackBar notifikasi sukses tampil
        expect(find.textContaining('berhasil dihapus!'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Penanganan kesalahan penghapusan (kegagalan jaringan / server)
    // -----------------------------------------------------------------------
    testWidgets(
      '4. Kegagalan jaringan saat menghapus menampilkan pesan kesalahan dan data tetap ada di daftar',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const ownerId = 'owner-uuid-001';
        final user = buildFakeUser(id: ownerId);
        final kos = buildFakeKos(
          id: 'kos-del-04',
          ownerId: ownerId,
          nama: 'Kos Flamboyan Bahari',
        );

        final kosRepo = MockKosRepository(
          mockData: [kos],
          mockDeleteError: Exception('Koneksi database terputus saat menghapus'),
        );
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Buka dialog dan konfirmasi hapus
        await tester.tap(find.byKey(const Key('delete_kos_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_delete_button')));
        await tester.pumpAndSettle();

        // Pesan kesalahan tampil
        expect(find.textContaining('Koneksi database terputus'), findsOneWidget);

        // Kos tetap ada di daftar dan tidak hilang
        expect(find.text('Kos Flamboyan Bahari'), findsOneWidget);
        expect(kosProvider.allKos.length, equals(1));
      },
    );

    // -----------------------------------------------------------------------
    // 5. Pembatasan kepemilikan: penolakan jika akun bukan pemilik kos (US08-AC2)
    // -----------------------------------------------------------------------
    testWidgets(
      '5. Menolak penghapusan jika akun aktif berbeda dengan owner_id data kos (US08-AC2)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        // Kos milik akun lain
        final otherKos = buildFakeKos(
          id: 'kos-milik-orang-lain',
          ownerId: 'owner-uuid-999',
          nama: 'Kos Milik Orang Lain',
        );
        // Akun aktif yang bukan pemilik kos
        final activeUser = buildFakeUser(id: 'owner-uuid-001');

        final kosRepo = MockKosRepository(mockData: [otherKos]);
        final kosProvider = KosProvider(repository: kosRepo);
        await kosProvider.loadKos();
        final authRepo = MockAuthRepository(mockUser: activeUser);
        final authProvider = AuthProvider(repository: authRepo);

        // Untuk mensimulasikan situasi di mana data kos akun lain dirender
        // (misalnya sebelum filter atau modifikasi state), kita render langsung dengan MyKosScreen
        // namun override daftar agar item milik orang lain muncul
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      key: const Key('trigger_unauthorized_delete'),
                      onPressed: () async {
                        // Simulasi pemanggilan deleteKos dengan ownerId aktif yang tidak cocok
                        final success = await context.read<KosProvider>().deleteKos(
                          id: otherKos.id,
                          ownerId: activeUser.id,
                        );
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Anda tidak memiliki izin untuk menghapus kos ini.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Hapus Ilegal'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Panggil trigger
        await tester.tap(find.byKey(const Key('trigger_unauthorized_delete')));
        await tester.pumpAndSettle();

        // Repository deleteKos tidak dipanggil karena ditolak oleh validasi kepemilikan
        expect(kosRepo.deleteCallCount, equals(0));

        // Verifikasi pesan penolakan tampil dan data tetap aman di mockData serta provider
        expect(find.text('Anda tidak memiliki izin untuk menghapus kos ini.'), findsOneWidget);
        expect(kosRepo.mockData.any((k) => k.id == otherKos.id), isTrue);
        expect(kosProvider.allKos.any((k) => k.id == otherKos.id), isTrue);
      },
    );
  });
}

