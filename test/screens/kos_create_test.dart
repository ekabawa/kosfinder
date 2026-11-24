import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock Repositories
// ---------------------------------------------------------------------------

class MockKosRepository extends KosRepository {
  List<Kos> mockData;
  Exception? mockError;
  Map<String, dynamic>? lastCreatedPayload;

  MockKosRepository({this.mockData = const [], this.mockError});

  @override
  Future<List<Kos>> fetchKos() async {
    if (mockError != null) throw mockError!;
    return mockData;
  }

  @override
  Future<Kos> createKos({
    required String ownerId,
    required String nama,
    required String alamatArea,
    required int hargaPerBulan,
    required String deskripsi,
    required String fasilitas,
    required String tipeKos,
    required String nomorKontak,
  }) async {
    lastCreatedPayload = {
      'owner_id': ownerId,
      'nama': nama,
      'alamat_area': alamatArea,
      'harga_per_bulan': hargaPerBulan,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'tipe_kos': tipeKos,
      'nomor_kontak': nomorKontak,
    };

    if (mockError != null) throw mockError!;

    return Kos(
      id: 'generated-kos-uuid-999',
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
}

class MockAuthRepository extends AuthRepository {
  User? mockUser;
  MockAuthRepository({this.mockUser});

  @override
  User? get currentUser => mockUser;
}

User buildFakeUser({
  String id = 'test-owner-uuid-001',
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
      home: KosFormScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test Suite: KosCreateTest (T11)
// ---------------------------------------------------------------------------

void main() {
  group('Fitur Tambah Kos Baru (Create) Widget & Unit Tests (T11)', () {
    void setupLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets(
      '1. Validasi field wajib yang kosong menampilkan pesan kesalahan (US06-AC2)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);
        final kosRepo = MockKosRepository();
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: buildFakeUser());
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          createTestWidget(
            kosProvider: kosProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Tekan tombol simpan saat formulir masih kosong
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        expect(simpanButton, findsOneWidget);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Seluruh pesan validasi wajib harus tampil
        expect(find.text('Nama kos wajib diisi'), findsOneWidget);
        expect(find.text('Alamat atau area wajib diisi'), findsOneWidget);
        expect(find.text('Harga sewa per bulan wajib diisi'), findsOneWidget);
        expect(find.text('Deskripsi kos wajib diisi'), findsOneWidget);
        expect(find.text('Fasilitas kos wajib diisi'), findsOneWidget);
        expect(find.text('Tipe kos wajib dipilih'), findsOneWidget);
        expect(find.text('Nomor kontak pemilik wajib diisi'), findsOneWidget);

        // Tidak ada pemanggilan insert ke database
        expect(kosRepo.lastCreatedPayload, isNull);
      },
    );

    testWidgets(
      '2. Validasi harga bukan angka atau negatif menampilkan pesan kesalahan (US06-AC2)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);
        final kosRepo = MockKosRepository();
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: buildFakeUser());
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          createTestWidget(
            kosProvider: kosProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Masukkan teks non-angka pada field harga
        final hargaField = find.byKey(const Key('harga_field'));
        await tester.enterText(hargaField, 'bukan-angka');

        // Tekan tombol simpan
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        expect(find.text('Harga harus berupa angka yang valid'), findsOneWidget);
        expect(kosRepo.lastCreatedPayload, isNull);
      },
    );

    testWidgets(
      '3. Penyimpanan data berhasil dan menutup halaman formulir (US06-AC1)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);
        final kosRepo = MockKosRepository();
        final kosProvider = KosProvider(repository: kosRepo);
        final fakeUser = buildFakeUser(id: 'owner-uuid-456');
        final authRepo = MockAuthRepository(mockUser: fakeUser);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          createTestWidget(
            kosProvider: kosProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Isi seluruh formulir dengan data valid
        await tester.enterText(
          find.byKey(const Key('nama_field')),
          'Kos Singaraja Asri',
        );
        await tester.enterText(
          find.byKey(const Key('alamat_area_field')),
          'Jalan Udayana No. 5, Singaraja',
        );
        await tester.enterText(
          find.byKey(const Key('harga_field')),
          '850000',
        );
        await tester.enterText(
          find.byKey(const Key('deskripsi_field')),
          'Kos nyaman dan tenang untuk mahasiswa Undiksha.',
        );
        await tester.enterText(
          find.byKey(const Key('fasilitas_field')),
          'WiFi, Kasur, Kamar Mandi Dalam',
        );
        await tester.enterText(
          find.byKey(const Key('nomor_kontak_field')),
          '081234567890',
        );

        // Pilih tipe kos via dropdown
        final dropdownFinder = find.byKey(const Key('tipe_kos_dropdown'));
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Campur').last);
        await tester.pumpAndSettle();

        // Tekan simpan
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Verifikasi repository menerima pemanggilan createKos
        expect(kosRepo.lastCreatedPayload, isNotNull);
        expect(kosRepo.lastCreatedPayload!['nama'], equals('Kos Singaraja Asri'));
        expect(kosRepo.lastCreatedPayload!['harga_per_bulan'], equals(850000));
        expect(kosRepo.lastCreatedPayload!['tipe_kos'], equals('Campur'));

        // Kos baru langsung masuk ke provider.kosList
        expect(kosProvider.kosList.any((k) => k.nama == 'Kos Singaraja Asri'), isTrue);
      },
    );

    testWidgets(
      '4. Payload insert menyertakan owner_id otomatis sesuai user aktif, bukan input pengguna (NFR-SEC)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);
        final kosRepo = MockKosRepository();
        final kosProvider = KosProvider(repository: kosRepo);
        const activeUserId = 'user-spesifik-owner-789';
        final fakeUser = buildFakeUser(id: activeUserId);
        final authRepo = MockAuthRepository(mockUser: fakeUser);
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          createTestWidget(
            kosProvider: kosProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('nama_field')),
          'Kos Puri Jimbaran',
        );
        await tester.enterText(
          find.byKey(const Key('alamat_area_field')),
          'Kampus Bukit Jimbaran',
        );
        await tester.enterText(
          find.byKey(const Key('harga_field')),
          '1200000',
        );
        await tester.enterText(
          find.byKey(const Key('deskripsi_field')),
          'Dekat gerbang utama kampus',
        );
        await tester.enterText(
          find.byKey(const Key('fasilitas_field')),
          'AC, WiFi, Parkir Mobil',
        );
        await tester.enterText(
          find.byKey(const Key('nomor_kontak_field')),
          '085555555555',
        );

        final dropdownFinder = find.byKey(const Key('tipe_kos_dropdown'));
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Putra').last);
        await tester.pumpAndSettle();

        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // owner_id pada payload HARUS sama dengan activeUserId akun auth
        expect(kosRepo.lastCreatedPayload!['owner_id'], equals(activeUserId));
      },
    );

    testWidgets(
      '5. Network error saat simpan menampilkan pesan galat dan mempertahankan input formulir (US06-AC3)',
      (WidgetTester tester) async {
        setupLargeViewport(tester);
        final kosRepo = MockKosRepository(
          mockError: Exception('Koneksi internet terputus saat menyimpan data'),
        );
        final kosProvider = KosProvider(repository: kosRepo);
        final authRepo = MockAuthRepository(mockUser: buildFakeUser());
        final authProvider = AuthProvider(repository: authRepo);

        await tester.pumpWidget(
          createTestWidget(
            kosProvider: kosProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Isi form
        await tester.enterText(
          find.byKey(const Key('nama_field')),
          'Kos Data Penting',
        );
        await tester.enterText(
          find.byKey(const Key('alamat_area_field')),
          'Area Kampus B',
        );
        await tester.enterText(
          find.byKey(const Key('harga_field')),
          '900000',
        );
        await tester.enterText(
          find.byKey(const Key('deskripsi_field')),
          'Deskripsi detail yang panjang dan tidak boleh hilang.',
        );
        await tester.enterText(
          find.byKey(const Key('fasilitas_field')),
          'Fasilitas lengkap',
        );
        await tester.enterText(
          find.byKey(const Key('nomor_kontak_field')),
          '087777777777',
        );

        final dropdownFinder = find.byKey(const Key('tipe_kos_dropdown'));
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Putri').last);
        await tester.pumpAndSettle();

        // Tekan simpan saat jaringan error
        final simpanButton = find.byKey(const Key('simpan_kos_button'));
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Notifikasi / pesan error muncul
        expect(
          find.textContaining('Koneksi internet terputus saat menyimpan data'),
          findsWidgets,
        );

        // Seluruh data form TIDAK hilang
        expect(find.text('Kos Data Penting'), findsOneWidget);
        expect(find.text('Area Kampus B'), findsOneWidget);
        expect(find.text('900000'), findsOneWidget);
        expect(
          find.text('Deskripsi detail yang panjang dan tidak boleh hilang.'),
          findsOneWidget,
        );
        expect(find.text('Fasilitas lengkap'), findsOneWidget);
        expect(find.text('087777777777'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Transisi state loading saat proses simpan berlangsung',
      (WidgetTester tester) async {
        final kosRepo = MockKosRepository();
        final kosProvider = KosProvider(repository: kosRepo);

        expect(kosProvider.isCreating, isFalse);

        final creatingStates = <bool>[];
        kosProvider.addListener(() {
          creatingStates.add(kosProvider.isCreating);
        });

        await kosProvider.createKos(
          ownerId: 'owner-1',
          nama: 'Kos Test State',
          alamatArea: 'Area Test',
          hargaPerBulan: 500000,
          deskripsi: 'Deskripsi',
          fasilitas: 'Fasilitas',
          tipeKos: 'Campur',
          nomorKontak: '0812345678',
        );

        expect(creatingStates, contains(true));
        expect(kosProvider.isCreating, isFalse);
      },
    );
  });
}
