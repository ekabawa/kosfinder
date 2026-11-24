// ==============================================================================
// Pengujian Integrasi dan Otorisasi Row Level Security (RLS) Antar-Akun (Task T15)
// Aplikasi: KosFinder
//
// DESKRIPSI:
// Pengujian integrasi ini memverifikasi aturan keamanan Supabase Row Level Security (RLS)
// pada tabel `public.kos` secara nyata terhadap backend Supabase:
//   1. SELECT publik: Pengguna anonim tanpa login dapat membaca data kos.
//   2. UPDATE lintas akun: Akun B tidak dapat mengubah data kos milik Akun A.
//   3. DELETE lintas akun: Akun B tidak dapat menghapus data kos milik Akun A.
//
// KEAMANAN:
// - Menggunakan hanya publishable `anonKey`. Dilarang menggunakan `service_role`.
// - Kredensial dibaca secara dinamis dari environment variable / .env / --dart-define.
// - Data sementara dibuat dengan timestamp unik oleh Akun A dan dibersihkan pada tearDownAll.
//
// CARA MENJALANKAN SECARA MANDIRI:
//
// Opsi A: Menggunakan file .env
// Pastikan file `.env` di root proyek memiliki variabel berikut:
//   RUN_SUPABASE_INTEGRATION_TESTS=true
//   SUPABASE_URL=https://your-project.supabase.co
//   SUPABASE_ANON_KEY=your-anon-key
//   TEST_USER_A_EMAIL=user_a@example.com
//   TEST_USER_A_PASSWORD=password_a
//   TEST_USER_B_EMAIL=user_b@example.com
//   TEST_USER_B_PASSWORD=password_b
//
// Jalankan perintah:
//   flutter test test/integration/rls_authorization_test.dart
//
// Opsi B: Menggunakan flag --dart-define pada terminal
//   flutter test test/integration/rls_authorization_test.dart \
//     --dart-define=RUN_SUPABASE_INTEGRATION_TESTS=true \
//     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
//     --dart-define=TEST_USER_A_EMAIL=user_a@example.com \
//     --dart-define=TEST_USER_A_PASSWORD=password_a \
//     --dart-define=TEST_USER_B_EMAIL=user_b@example.com \
//     --dart-define=TEST_USER_B_PASSWORD=password_b
// ==============================================================================

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper untuk mengambil nilai konfigurasi dengan urutan prioritas:
/// 1. System Environment / OS (`Platform.environment`)
/// 2. File `.env` (`flutter_dotenv`)
/// 3. Compile-time constant dari `--dart-define` (`dartDefine`)
String _resolveEnv(String key, {String dartDefine = ''}) {
  final platformVal = Platform.environment[key];
  if (platformVal != null && platformVal.trim().isNotEmpty) {
    return platformVal.trim();
  }
  if (dotenv.isInitialized) {
    final dotEnvVal = dotenv.maybeGet(key);
    if (dotEnvVal != null && dotEnvVal.trim().isNotEmpty) {
      return dotEnvVal.trim();
    }
  }
  if (dartDefine.trim().isNotEmpty) {
    return dartDefine.trim();
  }
  return '';
}

void main() {
  // Inisialisasi dotenv jika file .env tersedia di root proyek
  try {
    final envFile = File('.env');
    if (envFile.existsSync()) {
      final content = envFile.readAsStringSync();
      dotenv.testLoad(fileInput: content);
    }
  } catch (_) {
    // Abaikan jika .env tidak dapat dibaca, pembacaan akan beralih ke Platform/dart-define
  }

  // Resolusi environment variable dengan dukungan eksplisit compile-time const untuk --dart-define
  final runIntegration = _resolveEnv(
        'RUN_SUPABASE_INTEGRATION_TESTS',
        dartDefine:
            const String.fromEnvironment('RUN_SUPABASE_INTEGRATION_TESTS'),
      ).toLowerCase() ==
      'true';

  final supabaseUrl = _resolveEnv(
    'SUPABASE_URL',
    dartDefine: const String.fromEnvironment('SUPABASE_URL'),
  );

  final supabaseAnonKey = _resolveEnv(
    'SUPABASE_ANON_KEY',
    dartDefine: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final userAEmail = _resolveEnv(
    'TEST_USER_A_EMAIL',
    dartDefine: const String.fromEnvironment('TEST_USER_A_EMAIL'),
  );

  final userAPassword = _resolveEnv(
    'TEST_USER_A_PASSWORD',
    dartDefine: const String.fromEnvironment('TEST_USER_A_PASSWORD'),
  );

  final userBEmail = _resolveEnv(
    'TEST_USER_B_EMAIL',
    dartDefine: const String.fromEnvironment('TEST_USER_B_EMAIL'),
  );

  final userBPassword = _resolveEnv(
    'TEST_USER_B_PASSWORD',
    dartDefine: const String.fromEnvironment('TEST_USER_B_PASSWORD'),
  );

  final hasAllCredentials = supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      userAEmail.isNotEmpty &&
      userAPassword.isNotEmpty &&
      userBEmail.isNotEmpty &&
      userBPassword.isNotEmpty;

  final String? skipReason = !runIntegration
      ? 'Pengujian integrasi RLS dilewati secara default (opt-in). '
          'Set RUN_SUPABASE_INTEGRATION_TESTS=true untuk mengaktifkan.'
      : (!hasAllCredentials
          ? 'Pengujian integrasi RLS dilewati karena environment variable tidak lengkap. '
              'Pastikan SUPABASE_URL, SUPABASE_ANON_KEY, TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD, '
              'TEST_USER_B_EMAIL, dan TEST_USER_B_PASSWORD telah disetel.'
          : null);

  group('T15 - Pengujian Integrasi dan Otorisasi RLS Antar-Akun', () {
    // Menggunakan tipe nullable agar bebas dari LateInitializationError saat setUpAll gagal
    SupabaseClient? anonClient;
    SupabaseClient? clientA;
    SupabaseClient? clientB;

    String? userAId;
    String? userBId;
    String? tempKosId;
    String? tempKosName;

    setUpAll(() async {
      // 1. Inisialisasi 3 client Supabase independen dengan anon key
      anonClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
      clientA = SupabaseClient(supabaseUrl, supabaseAnonKey);
      clientB = SupabaseClient(supabaseUrl, supabaseAnonKey);

      // 2. Autentikasi Akun A
      final authResA = await clientA!.auth.signInWithPassword(
        email: userAEmail,
        password: userAPassword,
      );
      expect(authResA.user, isNotNull,
          reason: 'Akun A harus berhasil login ke Supabase Auth');
      userAId = clientA!.auth.currentUser!.id;

      // 3. Autentikasi Akun B
      final authResB = await clientB!.auth.signInWithPassword(
        email: userBEmail,
        password: userBPassword,
      );
      expect(authResB.user, isNotNull,
          reason: 'Akun B harus berhasil login ke Supabase Auth');
      userBId = clientB!.auth.currentUser!.id;

      // 4. Verifikasi bahwa Akun A dan Akun B adalah akun yang berbeda
      expect(userAId, isNot(equals(userBId)),
          reason: 'Akun A dan Akun B harus memiliki User ID yang berbeda');

      // 5. Akun A membuat satu record kos sementara untuk pengujian
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempKosName = 'Kos Temp RLS Test $timestamp';

      final insertResponse = await clientA!.from('kos').insert({
        'owner_id': userAId,
        'nama': tempKosName,
        'alamat_area': 'Area Uji RLS Singaraja',
        'harga_per_bulan': 750000,
        'deskripsi': 'Data kos sementara untuk pengujian integrasi RLS T15',
        'fasilitas': 'WiFi, Kamar Mandi Dalam, Kasur',
        'tipe_kos': 'Campur',
        'nomor_kontak': '081234567890',
      }).select().single();

      tempKosId = insertResponse['id'] as String;
      expect(tempKosId, isNotNull);
      expect(tempKosId, isNotEmpty);
    });

    tearDownAll(() async {
      // 1. Bersihkan data sementara yang dibuat oleh Akun A
      try {
        if (tempKosId != null && clientA != null) {
          await clientA!.from('kos').delete().eq('id', tempKosId!);
        }
      } catch (_) {
        // Abaikan error cleanup agar tidak menutupi hasil test
      }

      // 2. Logout Akun A dengan null-aware call
      try {
        await clientA?.auth.signOut();
      } catch (_) {}

      // 3. Logout Akun B dengan null-aware call
      try {
        await clientB?.auth.signOut();
      } catch (_) {}

      // 4. Dispose seluruh client untuk melepaskan resource, timer, dan koneksi
      try {
        clientA?.dispose();
      } catch (_) {}
      try {
        clientB?.dispose();
      } catch (_) {}
      try {
        anonClient?.dispose();
      } catch (_) {}
    });

    test(
      '1. SELECT publik: Pengguna anonim tanpa login dapat membaca data kos (US01-US04)',
      () async {
        // Query menggunakan client anonim tanpa autentikasi
        final response = await anonClient!
            .from('kos')
            .select()
            .eq('id', tempKosId!);

        expect(response, isA<List<dynamic>>());
        expect(response, isNotEmpty,
            reason: 'Data kos harus dapat dibaca oleh pengguna publik/anonim');
        expect(response.first['id'], equals(tempKosId));
        expect(response.first['nama'], equals(tempKosName));
      },
    );

    test(
      '2. UPDATE lintas akun: Akun B ditolak saat mencoba mengubah data kos milik Akun A (US07)',
      () async {
        final unauthorizedPayload = {
          'nama': 'Kos Diretas Akun B',
          'harga_per_bulan': 9999999,
        };

        // Akun B mencoba melakukan update pada data milik Akun A.
        // Dengan RLS "USING (auth.uid() = owner_id)", PostgREST memfilter baris yang boleh diupdate.
        // Operasi yang tidak memenuhi RLS menghasilkan 0 baris terpengaruh (list kosong).
        final updateResponse = await clientB!
            .from('kos')
            .update(unauthorizedPayload)
            .eq('id', tempKosId!)
            .select();

        expect(updateResponse, isA<List<dynamic>>());
        expect(
          updateResponse,
          isEmpty,
          reason: 'Operasi UPDATE dari Akun B harus ditolak oleh RLS '
              'sehingga tidak ada baris yang terpengaruh (list kosong).',
        );

        // Akun A membaca kembali data dari database untuk memastikan nilainya tetap sama
        final checkData = await clientA!
            .from('kos')
            .select()
            .eq('id', tempKosId!)
            .single();

        expect(checkData['nama'], equals(tempKosName),
            reason: 'Nama kos milik Akun A tidak boleh berubah');
        expect(checkData['harga_per_bulan'], equals(750000),
            reason: 'Harga kos milik Akun A tidak boleh berubah');
      },
    );

    test(
      '3. DELETE lintas akun: Akun B ditolak saat mencoba menghapus data kos milik Akun A (US08)',
      () async {
        // Akun B mencoba melakukan delete pada data milik Akun A.
        // Dengan RLS "USING (auth.uid() = owner_id)", PostgREST memfilter baris yang boleh dihapus.
        // Operasi yang tidak memenuhi RLS menghasilkan 0 baris terpengaruh (list kosong).
        final deleteResponse = await clientB!
            .from('kos')
            .delete()
            .eq('id', tempKosId!)
            .select();

        expect(deleteResponse, isA<List<dynamic>>());
        expect(
          deleteResponse,
          isEmpty,
          reason: 'Operasi DELETE dari Akun B harus ditolak oleh RLS '
              'sehingga tidak ada baris yang terpengaruh (list kosong).',
        );

        // Akun A membaca kembali data dari database untuk memastikan baris masih tersedia
        final checkData = await clientA!
            .from('kos')
            .select()
            .eq('id', tempKosId!)
            .single();

        expect(checkData, isNotNull);
        expect(checkData['id'], equals(tempKosId));
        expect(checkData['nama'], equals(tempKosName),
            reason: 'Record kos milik Akun A harus tetap ada di database');
      },
    );
  }, skip: skipReason);
}
