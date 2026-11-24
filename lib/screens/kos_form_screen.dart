import 'package:flutter/material.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:provider/provider.dart';

/// Layar formulir untuk menambah data kos baru (Create).
///
/// Menyediakan input untuk nama, alamat/area, harga per bulan, deskripsi,
/// fasilitas, tipe kos, dan nomor kontak pemilik.
/// Menetapkan `owner_id` secara otomatis dari sesi [AuthProvider] yang aktif.
class KosFormScreen extends StatefulWidget {
  final Kos? kos;

  const KosFormScreen({super.key, this.kos});

  @override
  State<KosFormScreen> createState() => _KosFormScreenState();
}

class _KosFormScreenState extends State<KosFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.kos != null;

  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _hargaController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _fasilitasController;
  late final TextEditingController _kontakController;

  String? _selectedTipeKos;
  String? _localErrorMessage;

  static const List<String> _tipeKosOptions = ['Putra', 'Putri', 'Campur'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KosProvider>().clearError();
      }
    });
    _namaController = TextEditingController(text: widget.kos?.nama ?? '');
    _alamatController =
        TextEditingController(text: widget.kos?.alamatArea ?? '');
    _hargaController = TextEditingController(
      text: widget.kos != null ? widget.kos!.hargaPerBulan.toString() : '',
    );
    _deskripsiController =
        TextEditingController(text: widget.kos?.deskripsi ?? '');
    _fasilitasController =
        TextEditingController(text: widget.kos?.fasilitas ?? '');
    _kontakController =
        TextEditingController(text: widget.kos?.nomorKontak ?? '');
    _selectedTipeKos = widget.kos?.tipeKos;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _fasilitasController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  String? _validateHarga(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga sewa per bulan wajib diisi';
    }
    final cleanValue = value.replaceAll('.', '').trim();
    final parsed = int.tryParse(cleanValue);
    if (parsed == null || parsed < 0) {
      return 'Harga harus berupa angka yang valid';
    }
    return null;
  }

  Future<void> _submitForm() async {
    setState(() {
      _localErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final ownerId = authProvider.currentUser?.id;

    if (ownerId == null || ownerId.isEmpty) {
      setState(() {
        _localErrorMessage =
            'Akun pemilik tidak terautentikasi. Silakan login terlebih dahulu.';
      });
      return;
    }

    final kosProvider = context.read<KosProvider>();
    kosProvider.clearError();

    final cleanHarga =
        _hargaController.text.replaceAll('.', '').trim();
    final hargaPerBulan = int.parse(cleanHarga);

    Kos? result;
    if (isEditMode) {
      // Validasi hak kepemilikan kos sebelum mengirimkan request
      if (widget.kos!.ownerId != ownerId) {
        setState(() {
          _localErrorMessage =
              'Anda tidak memiliki izin untuk mengubah data kos ini.';
        });
        return;
      }

      result = await kosProvider.updateKos(
        id: widget.kos!.id,
        ownerId: ownerId,
        nama: _namaController.text.trim(),
        alamatArea: _alamatController.text.trim(),
        hargaPerBulan: hargaPerBulan,
        deskripsi: _deskripsiController.text.trim(),
        fasilitas: _fasilitasController.text.trim(),
        tipeKos: _selectedTipeKos!,
        nomorKontak: _kontakController.text.trim(),
      );
    } else {
      result = await kosProvider.createKos(
        ownerId: ownerId,
        nama: _namaController.text.trim(),
        alamatArea: _alamatController.text.trim(),
        hargaPerBulan: hargaPerBulan,
        deskripsi: _deskripsiController.text.trim(),
        fasilitas: _fasilitasController.text.trim(),
        tipeKos: _selectedTipeKos!,
        nomorKontak: _kontakController.text.trim(),
      );
    }

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Data kos berhasil diperbarui!'
                  : 'Data kos berhasil ditambahkan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, result);
        }
      }
    } else {
      // Terjadi kesalahan jaringan / database: input tetap dipertahankan
      if (mounted) {
        setState(() {
          _localErrorMessage =
              kosProvider.errorMessage ?? 'Gagal menyimpan data kos.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kosProvider = context.watch<KosProvider>();
    final isSaving = kosProvider.isCreating || kosProvider.isUpdating;

    final errorMessage = _localErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Ubah Informasi Kos' : 'Tambah Kos Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pesan error jika terjadi kegagalan simpan
              if (errorMessage != null) ...[
                Container(
                  key: const Key('kos_form_error_banner'),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
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
                          errorMessage,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Nama Kos
              TextFormField(
                key: const Key('nama_field'),
                controller: _namaController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nama Kos *',
                  hintText: 'Contoh: Kos Melati Cantik',
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => _validateRequired(val, 'Nama kos'),
              ),
              const SizedBox(height: 16),

              // 2. Alamat / Area
              TextFormField(
                key: const Key('alamat_area_field'),
                controller: _alamatController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Alamat / Area *',
                  hintText: 'Contoh: Jalan Sudirman, Jimbaran',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => _validateRequired(val, 'Alamat atau area'),
              ),
              const SizedBox(height: 16),

              // 3. Harga Sewa Per Bulan
              TextFormField(
                key: const Key('harga_field'),
                controller: _hargaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Harga Sewa Per Bulan (Rp) *',
                  hintText: 'Contoh: 750000',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validateHarga,
              ),
              const SizedBox(height: 16),

              // 4. Tipe Kos (Dropdown)
              DropdownButtonFormField<String>(
                key: const Key('tipe_kos_dropdown'),
                initialValue: _selectedTipeKos,
                decoration: InputDecoration(
                  labelText: 'Tipe Kos *',
                  prefixIcon: const Icon(Icons.people_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: const Text('Pilih tipe kos'),
                items: _tipeKosOptions.map((tipe) {
                  return DropdownMenuItem<String>(
                    value: tipe,
                    child: Text(tipe),
                  );
                }).toList(),
                onChanged: isSaving
                    ? null
                    : (val) {
                        setState(() {
                          _selectedTipeKos = val;
                        });
                      },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Tipe kos wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Deskripsi
              TextFormField(
                key: const Key('deskripsi_field'),
                controller: _deskripsiController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Kos *',
                  hintText: 'Jelaskan kondisi dan keunggulan kos...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => _validateRequired(val, 'Deskripsi kos'),
              ),
              const SizedBox(height: 16),

              // 6. Fasilitas
              TextFormField(
                key: const Key('fasilitas_field'),
                controller: _fasilitasController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Fasilitas Kos *',
                  hintText: 'Contoh: WiFi, AC, Kamar Mandi Dalam',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => _validateRequired(val, 'Fasilitas kos'),
              ),
              const SizedBox(height: 16),

              // 7. Nomor Kontak Pemilik
              TextFormField(
                key: const Key('nomor_kontak_field'),
                controller: _kontakController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Nomor Kontak Pemilik (WhatsApp/Telepon) *',
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    _validateRequired(val, 'Nomor kontak pemilik'),
              ),
              const SizedBox(height: 28),

              // Tombol Simpan
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  key: const Key('simpan_kos_button'),
                  onPressed: isSaving ? null : _submitForm,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving
                        ? (isEditMode ? 'Menyimpan Perubahan...' : 'Menyimpan...')
                        : (isEditMode ? 'Simpan Perubahan' : 'Simpan Kos'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

