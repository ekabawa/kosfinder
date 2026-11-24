import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/screens/my_kos_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock Repositories
// ---------------------------------------------------------------------------

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockError;
  int fetchKosCallCount = 0;

  MockKosRepository({this.mockData = const [], this.mockError});

  @override
  Future<List<Kos>> fetchKos() async {
    fetchKosCallCount++;
    if (mockError != null) throw mockError!;
    return mockData;
  }
}

class MockAuthRepository extends AuthRepository {
  User? mockUser;
  bool signOutCalled = false;
  Exception? mockSignOutError;

  MockAuthRepository({this.mockUser, this.mockSignOutError});

  @override
  User? get currentUser => mockUser;

  @override
  Future<void> signOut() async {
    if (mockSignOutError != null) throw mockSignOutError!;
    signOutCalled = true;
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
// Test Suite: MyKosScreenTest (T12)
// ---------------------------------------------------------------------------

void main() {
  group('MyKosScreen Widget Tests (T12)', () {
    void setupLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    // -----------------------------------------------------------------------
    // 1. Menampilkan daftar kos milik pengguna yang aktif
    // -----------------------------------------------------------------------
    testWidgets(
      '1. Menampilkan daftar kos yang dimiliki oleh pengguna aktif',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const currentUserId = 'owner-uuid-001';
        final user = buildFakeUser(id: currentUserId);

        final kosList = [
          buildFakeKos(
            id: 'kos-1',
            ownerId: currentUserId,
            nama: 'Kos Mawar Indah',
            hargaPerBulan: 750000,
            alamatArea: 'Jimbaran',
            tipeKos: 'Putri',
          ),
          buildFakeKos(
            id: 'kos-2',
            ownerId: currentUserId,
            nama: 'Kos Garuda Perkasa',
            hargaPerBulan: 900000,
            alamatArea: 'Bukit Jimbaran',
            tipeKos: 'Putra',
          ),
        ];

        final kosRepo = MockKosRepository(mockData: kosList);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Verifikasi list kos tampil
        expect(find.byKey(const Key('my_kos_list')), findsOneWidget);
        expect(find.text('Kos Mawar Indah'), findsOneWidget);
        expect(find.text('Kos Garuda Perkasa'), findsOneWidget);
        expect(find.text('Rp 750.000 / bulan'), findsOneWidget);
        expect(find.text('Rp 900.000 / bulan'), findsOneWidget);
        expect(find.text('Putri'), findsOneWidget);
        expect(find.text('Putra'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Kos milik pengguna lain tidak ditampilkan
    // -----------------------------------------------------------------------
    testWidgets(
      '2. Menyaring dan tidak menampilkan kos milik pengguna lain',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const myUserId = 'owner-uuid-001';
        const otherUserId = 'owner-uuid-999';
        final user = buildFakeUser(id: myUserId);

        final mixedKosList = [
          buildFakeKos(
            id: 'kos-milik-saya',
            ownerId: myUserId,
            nama: 'Kos Milik Sendiri',
          ),
          buildFakeKos(
            id: 'kos-milik-orang-1',
            ownerId: otherUserId,
            nama: 'Kos Milik Orang Lain A',
          ),
          buildFakeKos(
            id: 'kos-milik-orang-2',
            ownerId: otherUserId,
            nama: 'Kos Milik Orang Lain B',
          ),
        ];

        final kosRepo = MockKosRepository(mockData: mixedKosList);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Hanya kos milik saya yang tampil
        expect(find.text('Kos Milik Sendiri'), findsOneWidget);
        expect(find.text('Kos Milik Orang Lain A'), findsNothing);
        expect(find.text('Kos Milik Orang Lain B'), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Menampilkan empty state ketika pemilik belum memiliki kos
    // -----------------------------------------------------------------------
    testWidgets(
      '3. Menampilkan empty state saat pemilik belum memiliki kos',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final user = buildFakeUser(id: 'owner-uuid-baru');

        // Database berisi kos milik orang lain, tetapi tidak ada kos milik user ini
        final otherKosList = [
          buildFakeKos(
            id: 'kos-other',
            ownerId: 'different-owner',
            nama: 'Kos Lain',
          ),
        ];

        final kosRepo = MockKosRepository(mockData: otherKosList);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Verifikasi empty state tampil
        expect(find.byKey(const Key('my_kos_empty_state')), findsOneWidget);
        expect(find.text('Belum Ada Kos Terdaftar'), findsOneWidget);
        expect(find.byKey(const Key('empty_tambah_kos_button')), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Loading dan error state ditangani dengan baik
    // -----------------------------------------------------------------------
    testWidgets(
      '4. Menampilkan pesan error dan tombol coba lagi saat gagal memuat data',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final user = buildFakeUser();
        final kosRepo = MockKosRepository(
          mockError: Exception('Koneksi internet bermasalah'),
        );
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Verifikasi pesan error dan tombol coba lagi tampil
        expect(find.byKey(const Key('my_kos_error_message')), findsOneWidget);
        expect(find.textContaining('Koneksi internet bermasalah'), findsOneWidget);
        expect(find.byKey(const Key('my_kos_retry_button')), findsOneWidget);

        // Simulasi tombol Coba Lagi setelah koneksi pulih
        kosRepo.mockError = null;
        kosRepo.mockData = [
          buildFakeKos(
            id: 'kos-recovered',
            ownerId: user.id,
            nama: 'Kos Pulih Kembali',
          ),
        ];

        await tester.tap(find.byKey(const Key('my_kos_retry_button')));
        await tester.pumpAndSettle();

        // Data berhasil ditampilkan setelah retry
        expect(find.text('Kos Pulih Kembali'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 5. Tombol Tambah Kos tersedia dan mengarahkan ke KosFormScreen
    // -----------------------------------------------------------------------
    testWidgets(
      '5. Tombol Tambah Kos tersedia dan membuka KosFormScreen saat ditekan',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final user = buildFakeUser();
        final kosRepo = MockKosRepository(mockData: []);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Tombol Tambah Kos (FAB dan AppBar) tersedia
        expect(find.byKey(const Key('tambah_kos_button')), findsOneWidget);
        expect(find.byKey(const Key('tambah_kos_appbar_button')), findsOneWidget);

        // Tekan FAB Tambah Kos
        await tester.tap(find.byKey(const Key('tambah_kos_button')));
        await tester.pumpAndSettle();

        // Layar KosFormScreen terbuka
        expect(find.byType(KosFormScreen), findsOneWidget);
        expect(find.text('Tambah Kos Baru'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 6. Tombol Ubah dan Hapus tersedia pada setiap item kos
    // -----------------------------------------------------------------------
    testWidgets(
      '6. Tombol Ubah dan Hapus tersedia pada item kos dan memberikan feedback informasi',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        const currentUserId = 'owner-uuid-001';
        final user = buildFakeUser(id: currentUserId);

        final kosList = [
          buildFakeKos(
            id: 'kos-test-action',
            ownerId: currentUserId,
            nama: 'Kos Flamboyan',
          ),
        ];

        final kosRepo = MockKosRepository(mockData: kosList);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Verifikasi tombol Ubah dan Hapus ada
        expect(find.byKey(const Key('edit_kos_button')), findsOneWidget);
        expect(find.byKey(const Key('delete_kos_button')), findsOneWidget);

        // Tekan tombol Ubah -> membuka KosFormScreen dalam mode edit
        await tester.tap(find.byKey(const Key('edit_kos_button')));
        await tester.pumpAndSettle();
        expect(find.byType(KosFormScreen), findsOneWidget);
        expect(find.text('Ubah Informasi Kos'), findsOneWidget);
        expect(find.text('Kos Flamboyan'), findsOneWidget);

        // Kembali ke MyKosScreen
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Tekan tombol Hapus -> memunculkan dialog konfirmasi hapus
        await tester.tap(find.byKey(const Key('delete_kos_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('delete_confirmation_dialog')), findsOneWidget);
        expect(find.text('Konfirmasi Hapus'), findsOneWidget);

        // Tekan tombol Batal -> memastikan dialog tertutup
        await tester.tap(find.byKey(const Key('cancel_delete_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('delete_confirmation_dialog')), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // 7. Tombol Logout memanggil mekanisme logout dan kembali ke Home
    // -----------------------------------------------------------------------
    testWidgets(
      '7. Tombol Logout memanggil signOut() dan mengarahkan kembali ke KosListScreen',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final user = buildFakeUser();
        final kosRepo = MockKosRepository(mockData: []);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(createTestWidget(
          kosProvider: kosProvider,
          authProvider: authProvider,
        ));
        await tester.pumpAndSettle();

        // Tombol Logout tersedia di AppBar
        expect(find.byKey(const Key('logout_button')), findsOneWidget);

        // Tekan tombol Logout
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        // Verifikasi signOut dipanggil di AuthRepository
        expect(authRepo.signOutCalled, isTrue);
        expect(authProvider.isAuthenticated, isFalse);

        // Pengguna diarahkan kembali ke halaman utama publik (KosListScreen)
        expect(find.byType(KosListScreen), findsOneWidget);
        expect(find.text('KosFinder'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 8. Navigasi dari KosListScreen ke MyKosScreen jika sudah login
    // -----------------------------------------------------------------------
    testWidgets(
      '8. Mengetuk tombol akun di KosListScreen membuka MyKosScreen saat sudah login',
      (WidgetTester tester) async {
        setupLargeViewport(tester);

        final user = buildFakeUser();
        final kosRepo = MockKosRepository(mockData: []);
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: user);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ],
            child: const MaterialApp(
              home: KosListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tombol akun terdeteksi login
        expect(find.byKey(const Key('auth_button')), findsOneWidget);

        // Tekan tombol akun
        await tester.tap(find.byKey(const Key('auth_button')));
        await tester.pumpAndSettle();

        // MyKosScreen terbuka
        expect(find.byType(MyKosScreen), findsOneWidget);
        expect(find.text('Kos Saya'), findsOneWidget);
      },
    );
  });
}

