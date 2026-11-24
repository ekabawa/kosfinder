import 'package:flutter/material.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/screens/about_screen.dart';
import 'package:kosfinder/screens/auth_screen.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';
import 'package:kosfinder/screens/my_kos_screen.dart';
import 'package:provider/provider.dart';

/// Layar utama publik untuk menampilkan daftar tempat kos di sekitar kampus,
/// dilengkapi dengan kolom pencarian kata kunci dan filter batas harga sewa.
class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().loadKos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _resetFilters(KosProvider provider) {
    _searchController.clear();
    _priceController.clear();
    provider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KosFinder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol Akun / Login Pemilik Kos
          const _AuthActionButton(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<KosProvider>(
        builder: (context, provider, _) {
          // Status 1: Sedang memuat data awal (Loading)
          if (provider.isLoading && provider.allKos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Status 2: Terjadi kesalahan koneksi / server (Error State)
          if (provider.hasError && provider.allKos.isEmpty) {
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
                      'Gagal Memuat Data',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ??
                          'Terjadi kesalahan jaringan atau server.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadKos(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Status 3: Data belum tersedia di database (Empty State)
          if (provider.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Kos Tersedia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daftar kos saat ini masih kosong.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => provider.loadKos(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Status 4: Menampilkan antarmuka pencarian, filter, dan daftar kos
          return Column(
            children: [
              _buildSearchAndFilterSection(context, provider),
              Expanded(
                child: provider.isFilteredEmpty
                    ? _buildFilteredEmptyState(context, provider)
                    : RefreshIndicator(
                        onRefresh: () => provider.refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          itemCount: provider.kosList.length,
                          itemBuilder: (context, index) {
                            final kos = provider.kosList[index];
                            return _KosCard(kos: kos);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bagian antarmuka pencarian kata kunci dan kontrol batas harga sewa maksimum.
  Widget _buildSearchAndFilterSection(
    BuildContext context,
    KosProvider provider,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kolom Input Pencarian Nama atau Area
          TextField(
            key: const Key('search_field'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau area kos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => provider.setSearchQuery(value),
          ),
          const SizedBox(height: 8),

          // Kolom Input Batas Harga Maksimum dan Tombol Reset Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('price_field'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Batas harga sewa maksimum...',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    prefixText: 'Rp ',
                    suffixIcon: _priceController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _priceController.clear();
                              provider.setMaxPrice(null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    final cleanValue = value.replaceAll('.', '').trim();
                    final price = int.tryParse(cleanValue);
                    provider.setMaxPrice(price);
                  },
                ),
              ),
              if (provider.isFilterActive) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: const Key('reset_filter_button'),
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Reset Filter',
                  onPressed: () => _resetFilters(provider),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Tampilan ketika kata kunci pencarian atau filter harga tidak menghasilkan kos yang cocok.
  Widget _buildFilteredEmptyState(BuildContext context, KosProvider provider) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Kos Tidak Ditemukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada kos yang cocok dengan kata kunci atau filter harga yang Anda terapkan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _resetFilters(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KosCard extends StatelessWidget {
  final Kos kos;

  const _KosCard({required this.kos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KosDetailScreen(kos: kos),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      kos.nama,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTipeColor(kos.tipeKos, theme).withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kos.tipeKos,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getTipeColor(kos.tipeKos, theme),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kos.alamatArea,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kos.fasilitas,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${_formatPrice(kos.hargaPerBulan)} / bulan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTipeColor(String tipe, ThemeData theme) {
    switch (tipe.toLowerCase()) {
      case 'putra':
        return Colors.blue;
      case 'putri':
        return Colors.pink;
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
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton();

  @override
  Widget build(BuildContext context) {
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider>(context);
    } on Object catch (_) {
      authProvider = null;
    }

    final isAuthenticated = authProvider?.isAuthenticated ?? false;

    return IconButton(
      key: const Key('auth_button'),
      icon: Icon(
        isAuthenticated ? Icons.person : Icons.person_outline,
      ),
      tooltip: isAuthenticated ? 'Kelola Kos Saya' : 'Login Pemilik Kos',
      onPressed: () async {
        if (isAuthenticated) {
          // Jika sudah login, langsung buka MyKosScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyKosScreen(),
            ),
          );
        } else {
          // Jika belum login, buka AuthScreen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (authProvider != null) {
                  return ChangeNotifierProvider<AuthProvider>.value(
                    value: authProvider,
                    child: const AuthScreen(),
                  );
                }
                return ChangeNotifierProvider<AuthProvider>(
                  create: (_) => AuthProvider(),
                  child: const AuthScreen(),
                );
              },
            ),
          );

          // Setelah kembali dari AuthScreen, jika login berhasil arahkan ke MyKosScreen
          if (context.mounted) {
            AuthProvider? updatedAuth;
            try {
              updatedAuth = Provider.of<AuthProvider>(context, listen: false);
            } on Object catch (_) {
              updatedAuth = null;
            }
            if (updatedAuth?.isAuthenticated ?? false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyKosScreen(),
                ),
              );
            }
          }
        }
      },
    );
  }
}
