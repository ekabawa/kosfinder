import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/screens/auth_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mock AuthRepository untuk pengujian widget
// ---------------------------------------------------------------------------

class MockAuthRepository extends AuthRepository {
  User? mockUser;
  Exception? mockSignInError;
  Exception? mockSignUpError;

  MockAuthRepository({this.mockUser, this.mockSignInError, this.mockSignUpError});

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (mockSignUpError != null) throw mockSignUpError!;
    return AuthResponse(session: null, user: mockUser);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (mockSignInError != null) throw mockSignInError!;
    return AuthResponse(session: null, user: mockUser);
  }

  @override
  Future<void> signOut() async {}

  @override
  User? get currentUser => null;
}

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
// Helper: membuat widget test dengan AuthProvider
// ---------------------------------------------------------------------------

Widget createTestWidget(AuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: const MaterialApp(
      home: AuthScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  group('AuthScreen Widget Tests (T10)', () {
    // -----------------------------------------------------------------------
    // 1. Validasi form: email dan password kosong
    // -----------------------------------------------------------------------
    testWidgets(
      '1. Menampilkan pesan validasi jika email dan password dikosongkan (US05-AC1)',
      (WidgetTester tester) async {
        final repository = MockAuthRepository();
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Tekan tombol Login tanpa mengisi form
        final submitButton = find.byKey(const Key('submit_button'));
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Pesan validasi muncul
        expect(find.text('Email wajib diisi'), findsOneWidget);
        expect(find.text('Password wajib diisi'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Validasi format email
    // -----------------------------------------------------------------------
    testWidgets(
      '2. Menampilkan pesan validasi jika format email tidak valid',
      (WidgetTester tester) async {
        final repository = MockAuthRepository();
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Masukkan email dengan format tidak valid
        await tester.enterText(
          find.byKey(const Key('email_field')),
          'emailtanpaat',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Format email tidak valid'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Validasi password terlalu pendek
    // -----------------------------------------------------------------------
    testWidgets(
      '3. Menampilkan pesan validasi jika password kurang dari 6 karakter',
      (WidgetTester tester) async {
        final repository = MockAuthRepository();
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('email_field')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          '123',
        );
        await tester.tap(find.byKey(const Key('submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Peralihan antara mode Login dan Registrasi
    // -----------------------------------------------------------------------
    testWidgets(
      '4. Peralihan antara mode Login dan Registrasi berfungsi (US05-AC1)',
      (WidgetTester tester) async {
        final repository = MockAuthRepository();
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // State awal: mode Login
        expect(find.text('Login Pemilik Kos'), findsOneWidget);
        expect(find.text('Login'), findsWidgets); // Tombol submit dan toggle
        expect(find.text('Belum punya akun?'), findsOneWidget);

        // Pindah ke mode Registrasi
        final toggleButton = find.byKey(const Key('toggle_mode_button'));
        expect(toggleButton, findsOneWidget);
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        expect(find.text('Daftar Akun Pemilik'), findsOneWidget);
        expect(find.text('Daftar'), findsWidgets);
        expect(find.text('Sudah punya akun?'), findsOneWidget);

        // Pindah kembali ke mode Login
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        expect(find.text('Login Pemilik Kos'), findsOneWidget);
        expect(find.text('Belum punya akun?'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 5. Pesan error muncul saat login gagal (kredensial salah)
    // -----------------------------------------------------------------------
    testWidgets(
      '5. Menampilkan pesan error saat login gagal tanpa crash (US05-AC3)',
      (WidgetTester tester) async {
        final repository = MockAuthRepository(
          mockSignInError: Exception(
            'Login gagal: Invalid login credentials',
          ),
        );
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Isi form
        await tester.enterText(
          find.byKey(const Key('email_field')),
          'wrong@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'wrongpassword',
        );

        // Submit
        await tester.tap(find.byKey(const Key('submit_button')));
        await tester.pumpAndSettle();

        // Pesan error tampil di UI
        expect(
          find.byKey(const Key('auth_error_message')),
          findsOneWidget,
        );
        expect(
          find.text('Login gagal: Invalid login credentials'),
          findsOneWidget,
        );
      },
    );

    // -----------------------------------------------------------------------
    // 6. Pesan error muncul saat registrasi gagal (network error)
    // -----------------------------------------------------------------------
    testWidgets(
      '6. Menampilkan pesan error saat registrasi gagal karena network error (US05-AC3)',
      (WidgetTester tester) async {
        final repository = MockAuthRepository(
          mockSignUpError: Exception(
            'Terjadi kesalahan jaringan atau server: SocketException',
          ),
        );
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Pindah ke mode Registrasi
        await tester.tap(find.byKey(const Key('toggle_mode_button')));
        await tester.pumpAndSettle();

        // Isi form
        await tester.enterText(
          find.byKey(const Key('email_field')),
          'newuser@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );

        // Submit
        await tester.tap(find.byKey(const Key('submit_button')));
        await tester.pumpAndSettle();

        // Pesan error tampil
        expect(
          find.byKey(const Key('auth_error_message')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Terjadi kesalahan jaringan'),
          findsOneWidget,
        );
      },
    );

    // -----------------------------------------------------------------------
    // 7. Tampilan awal AuthScreen sesuai desain
    // -----------------------------------------------------------------------
    testWidgets(
      '7. Menampilkan form login dengan email, password, dan tombol submit pada tampilan awal',
      (WidgetTester tester) async {
        final repository = MockAuthRepository();
        final provider = AuthProvider(repository: repository);

        await tester.pumpWidget(createTestWidget(provider));
        await tester.pumpAndSettle();

        // Elemen-elemen form tampil
        expect(find.byKey(const Key('email_field')), findsOneWidget);
        expect(find.byKey(const Key('password_field')), findsOneWidget);
        expect(find.byKey(const Key('submit_button')), findsOneWidget);
        expect(find.byKey(const Key('toggle_mode_button')), findsOneWidget);

        // Label dan hint
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
      },
    );
  });
}

