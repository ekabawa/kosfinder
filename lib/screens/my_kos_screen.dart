import 'package:flutter/material.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

/// Layar pengelolaan kos milik pemilik (MyKosScreen).
///
/// Menampilkan daftar kos yang khusus dimiliki oleh akun pemilik yang sedang login
/// (`owner_id == currentUser.id`), tombol Tambah Kos, tombol Ubah, tombol Hapus,
/// serta tombol Logout untuk keluar dari sesi pemilik.
class MyKosScreen extends StatefulWidget {
  const MyKosScreen({super.key});

  @override
  State<MyKosScreen> createState() => _MyKosScreenState();
}

class _MyKosScreenState extends State<MyKosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KosProvider>().loadKos();
      }
    });
  }

  /// Menjalankan proses logout dan mengarahkan pengguna kembali ke halaman Home publik.
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signOut();
    if (success && context.mounted) {
      // Sesi pengguna berakhir, arahkan kembali ke Home publik dan hapus stack navigasi
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const KosListScreen()),
        (route) => false,
      );
    } else if (context.mounted && authProvider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Gagal melakukan logout.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Membuka formulir Tambah Kos ([KosFormScreen]) dan memuat ulang daftar kos setelahnya.
  Future<void> _openTambahKos(BuildContext context) async {
    final result = await Navigator.push<Kos?>(
      context,
      MaterialPageRoute(
        builder: (context) => const KosFormScreen(),
      ),
    );

    if (result != null && context.mounted) {
      context.read<KosProvider>().loadKos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final kosProvider = context.watch<KosProvider>();

    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.id ?? '';

    // Menyaring daftar kos agar hanya menampilkan kos milik pemilik yang sedang aktif
    final myKosList = currentUserId.isNotEmpty
        ? kosProvider.allKos
            .where((kos) => kos.ownerId == currentUserId)
            .toList()
        : <Kos>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kos Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('tambah_kos_appbar_button'),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Kos',
            onPressed: () => _openTambahKos(context),
          ),
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Status 1: Sedang memuat data awal (Loading State)
          if (kosProvider.isLoading && kosProvider.allKos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                key: Key('my_kos_loading'),
              ),
            );
          }

          // Status 2: Terjadi kesalahan pemuatan data (Error State)
          if (kosProvider.hasError && kosProvider.allKos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Data Kos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kosProvider.errorMessage ??
                          'Terjadi kesalahan jaringan atau server saat memuat data.',
                      key: const Key('my_kos_error_message'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('my_kos_retry_button'),
                      onPressed: () => kosProvider.loadKos(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Status 3: Pemilik belum memiliki kos (Empty State)
          if (myKosList.isEmpty) {
            return Center(
              key: const Key('my_kos_empty_state'),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 72,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Kos Terdaftar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anda belum memiliki unit kos yang didaftarkan. Tekan tombol Tambah Kos untuk mempublikasikan kos pertama Anda.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('empty_tambah_kos_button'),
                      onPressed: () => _openTambahKos(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kos Sekarang'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Status 4: Menampilkan daftar kos milik pemilik
          return RefreshIndicator(
            onRefresh: () => kosProvider.loadKos(),
            child: ListView.builder(
              key: const Key('my_kos_list'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: myKosList.length,
              itemBuilder: (context, index) {
                final kos = myKosList[index];
                return _MyKosCard(
                  key: Key('my_kos_card_${kos.id}'),
                  kos: kos,
                  isFirst: index == 0,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tambah_kos_button'),
        onPressed: () => _openTambahKos(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kos'),
      ),
    );
  }
}

/// Kartu tampilan unit kos milik pemilik pada [MyKosScreen].
class _MyKosCard extends StatelessWidget {
  final Kos kos;
  final bool isFirst;

  const _MyKosCard({
    super.key,
    required this.kos,
    this.isFirst = false,
  });

  Color _getTypeBadgeColor(String tipeKos) {
    switch (tipeKos.toLowerCase()) {
      case 'putra':
        return Colors.blue;
      case 'putri':
        return Colors.pink;
      case 'campur':
      default:
        return Colors.teal;
    }
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _handleDeleteKos(BuildContext context, Kos kos) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('delete_confirmation_dialog'),
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${kos.nama}"? Data yang dihapus tidak dapat dipulihkan.',
          ),
          actions: [
            TextButton(
              key: const Key('cancel_delete_button'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: const Key('confirm_delete_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      final ownerId = authProvider.currentUser?.id;

      if (ownerId == null || ownerId.isEmpty || ownerId != kos.ownerId) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Anda tidak memiliki izin untuk menghapus kos ini.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        return;
      }

      final kosProvider = context.read<KosProvider>();
      final success = await kosProvider.deleteKos(
        id: kos.id,
        ownerId: ownerId,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Data kos "${kos.nama}" berhasil dihapus!'),
                backgroundColor: Colors.green,
              ),
            );
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  kosProvider.errorMessage ?? 'Gagal menghapus data kos.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _getTypeBadgeColor(kos.tipeKos);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: Nama Kos dan Badge Tipe Kos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    kos.nama,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    kos.tipeKos,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Alamat / Area
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    kos.alamatArea,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Harga Sewa
            Text(
              'Rp ${_formatPrice(kos.hargaPerBulan)} / bulan',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Fasilitas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 15,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    kos.fasilitas,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Tombol Ubah dan Hapus
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Ubah (T13)
                TextButton.icon(
                  key: isFirst
                      ? const Key('edit_kos_button')
                      : Key('edit_kos_button_${kos.id}'),
                  onPressed: () async {
                    final result = await Navigator.push<Kos?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KosFormScreen(kos: kos),
                      ),
                    );
                    if (result != null && context.mounted) {
                      context.read<KosProvider>().loadKos();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Ubah'),
                ),
                const SizedBox(width: 8),

                // Tombol Hapus (T14)
                TextButton.icon(
                  key: isFirst
                      ? const Key('delete_kos_button')
                      : Key('delete_kos_button_${kos.id}'),
                  onPressed: () => _handleDeleteKos(context, kos),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

