import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock AuthRepository
// ---------------------------------------------------------------------------

/// Implementasi palsu [AuthRepository] untuk pengujian tanpa koneksi Supabase.
class MockAuthRepository extends AuthRepository {
  User? mockUser;
  Exception? mockError;

  MockAuthRepository({this.mockUser, this.mockError});

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (mockError != null) throw mockError!;
    return AuthResponse(
      session: null,
      user: mockUser,
    );
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (mockError != null) throw mockError!;
    return AuthResponse(
      session: null,
      user: mockUser,
    );
  }

  @override
  Future<void> signOut() async {
    if (mockError != null) throw mockError!;
  }

  @override
  User? get currentUser => mockUser;
}

// ---------------------------------------------------------------------------
// Helper: membuat objek User palsu
// ---------------------------------------------------------------------------

/// Membuat objek [User] palsu untuk keperluan pengujian.
User buildFakeUser({
  String id = 'fake-user-id-001',
  String email = 'test@example.com',
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
// Test suite
// ---------------------------------------------------------------------------

void main() {
  group('AuthProvider Unit Tests (T09)', () {
    // -----------------------------------------------------------------------
    // 1. Registrasi berhasil
    // -----------------------------------------------------------------------
    test(
      '1. signUp berhasil: currentUser diperbarui dan state loading selesai',
      () async {
        final fakeUser = buildFakeUser();
        // Buat repository tanpa user aktif agar state awal bersih
        final repository = MockAuthRepository(mockUser: null);
        final provider = AuthProvider(repository: repository);

        // Verifikasi state awal tidak ada user
        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);

        // Set mockUser agar signUp mengembalikan user
        repository.mockUser = fakeUser;

        final loadingStates = <bool>[];
        provider.addListener(() => loadingStates.add(provider.isLoading));

        final result = await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.currentUser, isNotNull);
        expect(provider.currentUser!.email, equals('test@example.com'));
        expect(provider.isAuthenticated, isTrue);
        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
        expect(loadingStates, contains(true));
      },
    );

    // -----------------------------------------------------------------------
    // 2. Login berhasil — currentUser diperbarui
    // -----------------------------------------------------------------------
    test(
      '2. signIn berhasil: currentUser diperbarui dan isAuthenticated = true',
      () async {
        final fakeUser = buildFakeUser(id: 'user-login-123');
        final repository = MockAuthRepository(mockUser: fakeUser);
        final provider = AuthProvider(repository: repository);

        final result = await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(provider.isAuthenticated, isTrue);
        expect(provider.currentUser!.id, equals('user-login-123'));
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Login gagal — kredensial salah
    // -----------------------------------------------------------------------
    test(
      '3. signIn gagal karena kredensial salah: errorMessage terisi, aplikasi tidak crash',
      () async {
        final repository = MockAuthRepository(
          mockError: Exception('Login gagal: Invalid login credentials'),
        );
        final provider = AuthProvider(repository: repository);

        final result = await provider.signIn(
          email: 'salah@example.com',
          password: 'wrongpassword',
        );

        expect(result, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.currentUser, isNull);
        expect(provider.hasError, isTrue);
        expect(
          provider.errorMessage,
          contains('Login gagal: Invalid login credentials'),
        );
        expect(provider.isLoading, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Registrasi gagal — network error
    // -----------------------------------------------------------------------
    test(
      '4. signUp gagal karena network error: errorMessage terisi, aplikasi tidak crash',
      () async {
        final repository = MockAuthRepository(
          mockError: Exception(
            'Terjadi kesalahan jaringan atau server: SocketException',
          ),
        );
        final provider = AuthProvider(repository: repository);

        final result = await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Terjadi kesalahan jaringan'));
        expect(provider.isLoading, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // 5. Logout berhasil — state user dibersihkan
    // -----------------------------------------------------------------------
    test(
      '5. signOut berhasil: currentUser dibersihkan dan isAuthenticated = false',
      () async {
        final fakeUser = buildFakeUser();
        final repository = MockAuthRepository(mockUser: fakeUser);
        final provider = AuthProvider(repository: repository);

        // Login terlebih dahulu
        await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(provider.isAuthenticated, isTrue);

        // Reset mockUser supaya logout tidak mengembalikan user
        repository.mockUser = null;

        final result = await provider.signOut();

        expect(result, isTrue);
        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.hasError, isFalse);
        expect(provider.isLoading, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // 6. Tidak ada sesi aktif saat inisialisasi
    // -----------------------------------------------------------------------
    test(
      '6. Kondisi tidak ada sesi aktif: currentUser null dan isAuthenticated = false',
      () {
        final repository = MockAuthRepository(mockUser: null);
        final provider = AuthProvider(repository: repository);

        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // 7. Sesi aktif tersedia saat inisialisasi
    // -----------------------------------------------------------------------
    test(
      '7. Sesi aktif terdeteksi saat provider diinisialisasi: isAuthenticated = true',
      () {
        final fakeUser = buildFakeUser(email: 'existing@example.com');
        final repository = MockAuthRepository(mockUser: fakeUser);
        final provider = AuthProvider(repository: repository);

        // Provider harus langsung mengenali sesi aktif dari repository
        expect(provider.isAuthenticated, isTrue);
        expect(provider.currentUser!.email, equals('existing@example.com'));
      },
    );

    // -----------------------------------------------------------------------
    // 8. clearError membersihkan pesan error
    // -----------------------------------------------------------------------
    test(
      '8. clearError menghapus errorMessage yang tersimpan',
      () async {
        final repository = MockAuthRepository(
          mockError: Exception('Login gagal: Invalid login credentials'),
        );
        final provider = AuthProvider(repository: repository);

        await provider.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        );
        expect(provider.hasError, isTrue);

        provider.clearError();

        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // 9. Logout gagal — network error saat logout
    // -----------------------------------------------------------------------
    test(
      '9. signOut gagal karena network error: errorMessage terisi, aplikasi tidak crash',
      () async {
        final fakeUser = buildFakeUser();
        final repository = MockAuthRepository(mockUser: fakeUser);
        final provider = AuthProvider(repository: repository);

        // Login berhasil dahulu
        await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Set error untuk simulasi kegagalan logout
        repository.mockError = Exception(
          'Logout gagal: Terjadi kesalahan jaringan',
        );

        final result = await provider.signOut();

        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Logout gagal'));
        expect(provider.isLoading, isFalse);
      },
    );

    // -----------------------------------------------------------------------
    // 10. Transisi state loading saat signIn
    // -----------------------------------------------------------------------
    test(
      '10. Transisi isLoading: true saat proses signIn berlangsung, false setelah selesai',
      () async {
        final fakeUser = buildFakeUser();
        final repository = MockAuthRepository(mockUser: fakeUser);
        final provider = AuthProvider(repository: repository);

        final loadingStates = <bool>[];
        provider.addListener(() => loadingStates.add(provider.isLoading));

        await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(loadingStates, contains(true));
        expect(loadingStates.last, isFalse);
        expect(provider.isLoading, isFalse);
      },
    );
  });
}

