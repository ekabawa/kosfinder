import 'package:flutter/material.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Layar autentikasi pemilik kos: Login dan Registrasi menggunakan Email & Password.
///
/// Menyediakan peralihan antara mode Login dan Registrasi, validasi form input,
/// indikator loading, serta pesan error autentikasi/koneksi.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memvalidasi format email sederhana.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    // Validasi format email dasar
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Memvalidasi password tidak kosong dan panjang minimum.
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.trim().length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Menjalankan proses autentikasi (login atau registrasi).
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(email: email, password: password);
    } else {
      success = await authProvider.signUp(email: email, password: password);
    }

    if (success && mounted) {
      // Navigasi kembali setelah login/registrasi berhasil
      // T12 akan mengarahkan ke MyKosScreen; untuk saat ini pop ke layar sebelumnya
      Navigator.pop(context);
    }
  }

  /// Beralih antara mode Login dan Registrasi.
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
    // Bersihkan error saat berpindah mode
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoginMode ? 'Login Pemilik Kos' : 'Daftar Akun Pemilik',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ikon dan judul
                  const SizedBox(height: 16),
                  Icon(
                    _isLoginMode ? Icons.login_rounded : Icons.person_add_alt_1,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoginMode
                        ? 'Masuk ke Akun Anda'
                        : 'Buat Akun Pemilik Baru',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode
                        ? 'Gunakan email dan password untuk login sebagai pemilik kos.'
                        : 'Daftar dengan email dan password untuk mulai mengelola kos Anda.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input Email
                  TextFormField(
                    key: const Key('email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  TextFormField(
                    key: const Key('password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),

                  // Pesan Error Autentikasi
                  if (authProvider.hasError)
                    Container(
                      key: const Key('auth_error_message'),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Tombol Submit (Login / Daftar)
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const Key('submit_button'),
                      onPressed: authProvider.isLoading ? null : _submitForm,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Login' : 'Daftar',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol peralihan mode Login <-> Registrasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode
                            ? 'Belum punya akun?'
                            : 'Sudah punya akun?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const Key('toggle_mode_button'),
                        onPressed: _toggleMode,
                        child: Text(
                          _isLoginMode ? 'Daftar' : 'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

