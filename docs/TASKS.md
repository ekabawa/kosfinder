# Daftar Tugas Pengembangan: KosFinder (Versi 1)

Dokumen ini memuat rincian daftar tugas pengembangan (*task breakdown*) aplikasi KosFinder yang disusun dengan pendekatan *vertical slices*. Setiap tugas dirancang memiliki ruang lingkup terbatas, dependensi yang runtut, serta dapat diuji secara bertahap sesuai *Definition of Done* (DoD) pada [AGENTS.md](file:///d:/kosfinder/AGENTS.md).

---

## Slice 1: Persiapan Struktur Aplikasi dan Konfigurasi Supabase

### [T01] Setup Dependensi dan Konfigurasi Environment Supabase
* **Tujuan**: Menambahkan dependensi `provider` dan `supabase_flutter`, menyiapkan pembacaan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` via `String.fromEnvironment`, serta inisialisasi Supabase client pada entry point aplikasi.
* **User Story & AC Terkait**: Fondasi untuk seluruh US01–US08, NFR-SEC (kredensial aman via `--dart-define`), NFR-PRI.
* **File yang Boleh Dibuat / Diubah**:
  * `pubspec.yaml`
  * `lib/main.dart`
* **Pengujian**:
  1. Jalankan `flutter pub get` dan pastikan dependensi terpasang tanpa konflik.
  2. Jalankan `flutter analyze` dan pastikan 0 error / warning.
  3. Verifikasi inisialisasi `Supabase.initialize` berjalan tanpa error saat aplikasi dijalankan.
* **Status**: Todo

---

### [T02] Pembuatan Model Data Kos dan Unit Test Serialisasi
* **Tujuan**: Membuat entitas model data `Kos` di Dart yang memetakan kolom tabel database `public.kos` (termasuk validasi harga angka `int`/`int64`, tipe kos, dan konversi JSON dari/ke Supabase).
* **User Story & AC Terkait**: Fondasi data untuk US01, US02, US03, US04, US06, US07, US08.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/models/kos.dart`
  * `test/models/kos_test.dart`
* **Pengujian**:
  1. Buat unit test pada `test/models/kos_test.dart` untuk menguji `Kos.fromJson` dan `Kos.toJson`.
  2. Uji parsing atribut wajib: `id`, `owner_id`, `nama`, `alamat_area`, `harga_per_bulan`, `deskripsi`, `fasilitas`, `tipe_kos`, `nomor_kontak`.
  3. Jalankan `flutter test test/models/kos_test.dart` (100% lulus).
* **Status**: Todo

---

### [T03] Implementasi Layar About (Identitas Pengembang)
* **Tujuan**: Membuat layar `AboutScreen` yang menampilkan identitas pengembang aplikasi sesuai ketentuan wajib AGENTS.md (NIM: `2415051008`, Nama: `I Putu Eka Bawa Utama`).
* **User Story & AC Terkait**: Kebutuhan Identitas Pengembang (AGENTS.md Bagian 7), NFR-USE.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/about_screen.dart`
  * `lib/main.dart`
  * `test/screens/about_screen_test.dart`
* **Pengujian**:
  1. Buat widget test pada `test/screens/about_screen_test.dart`.
  2. Verifikasi teks `2415051008` dan `I Putu Eka Bawa Utama` terender secara akurat pada widget tree.
  3. Jalankan `flutter test test/screens/about_screen_test.dart`.
* **Status**: Todo

---

## Slice 2: Menampilkan Daftar dan Detail Kos

### [T04] Implementasi KosRepository dan KosProvider untuk Mengambil Data Kos
* **Tujuan**: Mengimplementasikan `KosRepository.fetchKos()` untuk query data dari Supabase, dan `KosProvider.loadKos()` untuk mengelola state data kos, loading state, serta penanganan error jaringan.
* **User Story & AC Terkait**: US01-AC1 (daftar tersedia), US01-AC3 (error jaringan), NFR-REL, NFR-PER.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/repositories/kos_repository.dart`
  * `lib/providers/kos_provider.dart`
  * `test/repositories/kos_repository_test.dart`
  * `test/providers/kos_provider_test.dart`
* **Pengujian**:
  1. Unit test `KosRepository` memanggil query `select()` ke tabel `kos`.
  2. Unit test `KosProvider` memvalidasi transisi state: `isLoading = true` $\rightarrow$ data terisi / `errorMessage` terisi jika gagal.
  3. Uji kondisi offline / network failure menghasilkan pesan galat tanpa *crash*.
* **Status**: Todo

---

### [T05] Implementasi Layar Daftar Kos Publik (KosListScreen)
* **Tujuan**: Membangun tampilan utama `KosListScreen` untuk menampilkan daftar kartu kos (nama, area, harga/bulan, tipe, fasilitas), menampilkan tampilan kosong (*empty state*), dan penanganan error koneksi dengan tombol coba lagi.
* **User Story & AC Terkait**: US01-AC1, US01-AC2 (empty state), US01-AC3 (koneksi gagal), NFR-USE, NFR-REL.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/kos_list_screen.dart`
  * `lib/main.dart`
  * `test/screens/kos_list_screen_test.dart`
* **Pengujian**:
  1. Widget test memverifikasi kartu kos muncul saat ada data.
  2. Widget test memverifikasi teks pesan kosong muncul saat data list kosong.
  3. Widget test memverifikasi pesan error dan tombol coba lagi saat state provider error.
* **Status**: Todo

---

### [T06] Implementasi Layar Detail Kos (KosDetailScreen)
* **Tujuan**: Membangun antarmuka `KosDetailScreen` yang menampilkan seluruh atribut informasi kos secara lengkap beserta nomor telepon/WhatsApp pemilik (teks), serta navigasi dari kartu kos di `KosListScreen`.
* **User Story & AC Terkait**: US02-AC1 (detail lengkap & kontak teks), US02-AC2 (error detail), NFR-USE.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/kos_detail_screen.dart`
  * `lib/screens/kos_list_screen.dart`
  * `test/screens/kos_detail_screen_test.dart`
* **Pengujian**:
  1. Widget test memeriksa seluruh informasi: nama, area, harga, tipe kos, deskripsi, fasilitas, dan nomor kontak pemilik terender pada layar.
  2. Uji ketukan kartu pada `KosListScreen` mengarahkan navigasi ke `KosDetailScreen` dengan membawa data kos terkait.
* **Status**: Todo

---

## Slice 3: Pencarian dan Filter Harga

### [T07] Logika Pencarian Teks dan Filter Harga pada KosProvider
* **Tujuan**: Menambahkan fungsi pencarian kata kunci teks nama/area (*case-insensitive*) dan pemfilteran batas nominal harga maksimum (`harga <= harga_maksimum`) pada `KosProvider`.
* **User Story & AC Terkait**: US03-AC1, US03-AC2, US04-AC1, US04-AC2, NFR-PER.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/providers/kos_provider.dart`
  * `test/providers/kos_search_filter_test.dart`
* **Pengujian**:
  1. Unit test pencarian kata kunci dengan variasi huruf besar dan kecil (misal "jimbaran", "KAMPUS").
  2. Unit test filter batas harga maksimum memastikan kos di atas batas disembunyikan.
  3. Unit test penggabungan pencarian dan filter harga.
  4. Jalankan `flutter test test/providers/kos_search_filter_test.dart`.
* **Status**: Todo

---

### [T08] Integrasi Antarmuka Pencarian dan Filter Harga pada KosListScreen
* **Tujuan**: Menambahkan kolom input teks pencarian kata kunci dan kontrol input batas harga sewa maksimum pada `KosListScreen`, serta menampilkan pesan informatif saat hasil pencarian/filter tidak ditemukan.
* **User Story & AC Terkait**: US03-AC1, US03-AC2, US04-AC1, US04-AC2, NFR-USE.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/kos_list_screen.dart`
  * `test/screens/kos_list_search_filter_test.dart`
* **Pengujian**:
  1. Widget test mengetikkan kata kunci pada TextField pencarian dan memverifikasi pembaruan daftar.
  2. Widget test memasukkan nilai batas harga maksimum dan memeriksa hasil yang ditampilkan.
  3. Widget test memverifikasi pesan "kos tidak ditemukan" tampil saat kata kunci / filter tidak memiliki hasil yang cocok.
* **Status**: Todo

---

## Slice 4: Registrasi, Login, dan Session Persistence

### [T09] Implementasi AuthRepository dan AuthProvider
* **Tujuan**: Mengimplementasikan `AuthRepository` dan `AuthProvider` untuk registrasi akun pemilik (`signUp`), autentikasi login (`signInWithPassword`), logout (`signOut`), pengecekan sesi aktif (`currentUser`), dan penanganan error autentikasi.
* **User Story & AC Terkait**: US05-AC1, US05-AC2, US05-AC3, NFR-SEC, NFR-REL.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/repositories/auth_repository.dart`
  * `lib/providers/auth_provider.dart`
  * `test/providers/auth_provider_test.dart`
* **Pengujian**:
  1. Unit test pendaftaran akun baru dengan format email valid dan password.
  2. Unit test login berhasil dan pembaruan state session user aktif.
  3. Unit test penanganan kegagalan autentikasi (kredensial salah / jaringan error) mengembalikan pesan kesalahan yang sesuai.
* **Status**: Todo

---

### [T10] Implementasi Layar Autentikasi Pemilik Kos (AuthScreen)
* **Tujuan**: Membuat `AuthScreen` yang menyediakan form registrasi dan login menggunakan Email & Password, validasi input wajib/format email, indikator loading, pesan error kredensial/koneksi, serta navigasi ke `MyKosScreen` setelah login berhasil.
* **User Story & AC Terkait**: US05-AC1, US05-AC2, US05-AC3, NFR-USE, NFR-REL.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/auth_screen.dart`
  * `lib/screens/kos_list_screen.dart`
  * `lib/main.dart`
  * `test/screens/auth_screen_test.dart`
* **Pengujian**:
  1. Widget test validasi form jika email atau password dikosongkan.
  2. Widget test peralihan antara mode Login dan Registrasi.
  3. Widget test memverifikasi pesan galat muncul saat autentikasi gagal tanpa membuat aplikasi *crash*.
* **Status**: Todo

---

## Slice 5: Pengelolaan Data Kos oleh Pemilik (Tambah, Edit, Hapus)

### [T11] Implementasi Fitur Tambah Kos Baru (Create)
* **Tujuan**: Mengimplementasikan fungsi `createKos` pada `KosRepository` dan `KosProvider` dengan pengisian otomatis `owner_id = auth.uid()`, membuat formulir `KosFormScreen` mode tambah dengan validasi atribut wajib dan harga angka, serta penanganan koneksi gagal saat simpan.
* **User Story & AC Terkait**: US06-AC1, US06-AC2, US06-AC3, NFR-SEC (RLS INSERT).
* **File yang Boleh Dibuat / Diubah**:
  * `lib/repositories/kos_repository.dart`
  * `lib/providers/kos_provider.dart`
  * `lib/screens/kos_form_screen.dart`
  * `test/screens/kos_create_test.dart`
* **Pengujian**:
  1. Widget test validasi kolom kosong atau kolom harga diisi selain angka.
  2. Unit/widget test verifikasi payload insert menyertakan `owner_id` akun aktif.
  3. Widget test memastikan data form tidak hilang jika terjadi kegagalan jaringan saat tombol simpan ditekan.
* **Status**: Todo

---

### [T12] Implementasi Layar Kelola Kos Pemilik (MyKosScreen)
* **Tujuan**: Membangun tampilan `MyKosScreen` untuk menampilkan daftar kos yang khusus dimiliki oleh akun pemilik yang sedang aktif (`owner_id == auth.uid()`), tombol tambah kos baru, tombol edit, tombol hapus, dan aksi logout.
* **User Story & AC Terkait**: US05-AC2, US06-AC1, US07-AC1, US08-AC1, NFR-SEC, NFR-USE.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/screens/my_kos_screen.dart`
  * `lib/screens/kos_list_screen.dart`
  * `test/screens/my_kos_screen_test.dart`
* **Pengujian**:
  1. Widget test memverifikasi hanya kos dengan `owner_id` milik user login yang muncul di `MyKosScreen`.
  2. Widget test memastikan tombol tambah, edit, hapus, dan logout tersedia dan dapat diklik.
* **Status**: Todo

---

### [T13] Implementasi Fitur Ubah Kos Milik Sendiri (Update)
* **Tujuan**: Menambahkan fungsi `updateKos` pada repository dan provider, mendukung mode edit pada `KosFormScreen` dengan data awal terisi otomatis, serta memvalidasi penolakan modifikasi data milik orang lain di level RLS.
* **User Story & AC Terkait**: US07-AC1, US07-AC2 (penolakan RLS), NFR-SEC, NFR-REL.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/repositories/kos_repository.dart`
  * `lib/providers/kos_provider.dart`
  * `lib/screens/kos_form_screen.dart`
  * `test/screens/kos_update_test.dart`
* **Pengujian**:
  1. Widget test memverifikasi seluruh nilai atribut kos yang diedit muncul pada form.
  2. Unit test menyimpan perubahan data berhasil memperbarui state kos di provider.
  3. Unit test simulasi percobaan update dengan ID pemilik berbeda ditolak oleh aturan RLS dan data asli tetap utuh.
* **Status**: Todo

---

### [T14] Implementasi Fitur Hapus Kos Milik Sendiri (Delete)
* **Tujuan**: Menambahkan fungsi `deleteKos` pada repository dan provider, menampilkan dialog konfirmasi sebelum penghapusan di `MyKosScreen`, serta memastikan kos terhapus dari tampilan dan database.
* **User Story & AC Terkait**: US08-AC1, US08-AC2 (penolakan RLS), NFR-SEC, NFR-REL.
* **File yang Boleh Dibuat / Diubah**:
  * `lib/repositories/kos_repository.dart`
  * `lib/providers/kos_provider.dart`
  * `lib/screens/my_kos_screen.dart`
  * `test/screens/kos_delete_test.dart`
* **Pengujian**:
  1. Widget test menampilkan dialog konfirmasi saat tombol hapus ditekan.
  2. Widget test konfirmasi "Ya, Hapus" memicu pemanggilan `deleteKos` dan kos hilang dari daftar.
  3. Unit test simulasi penghapusan data milik akun lain ditolak oleh Supabase RLS.
* **Status**: Todo

---

## Slice 6: Pengujian dan Penyempurnaan Aplikasi

### [T15] Pengujian Integrasi dan Otorisasi RLS Antar-Akun
* **Tujuan**: Menyusun dan menjalankan test suite integrasi komprehensif untuk memverifikasi keamanan isolasi data: publik hanya dapat membaca, dan akun Pemilik A tidak dapat memodifikasi/menghapus kos milik Pemilik B.
* **User Story & AC Terkait**: US01 s/d US08, US07-AC2, US08-AC2, NFR-SEC (RLS 100% aman).
* **File yang Boleh Dibuat / Diubah**:
  * `test/integration/rls_authorization_test.dart`
* **Pengujian**:
  1. Uji skenario `SELECT` data kos tanpa token auth (berhasil membaca).
  2. Uji skenario `UPDATE` record kos milik user A menggunakan sesi user B (ditolak RLS / tidak ada perubahan data).
  3. Uji skenario `DELETE` record kos milik user A menggunakan sesi user B (ditolak RLS / baris data tidak terhapus).
* **Status**: Todo

---

### [T16] Verifikasi Non-Functional Requirements, Analisis Statis, dan Validasi Akhir
* **Tujuan**: Menjalankan pengujian akhir menyeluruh: `flutter analyze` (wajib 0 error, 0 warning), `flutter test` (100% lulus), verifikasi latensi pemuatan data $\le$ 2s dan filter $\le$ 500ms (NFR-PER), audit izin AndroidManifest (NFR-PRI), serta verifikasi aplikasi berjalan lancar di emulator/device Android.
* **User Story & AC Terkait**: Seluruh US01–US08, NFR-SEC, NFR-REL, NFR-USE, NFR-PER, NFR-PRI, serta DoD pada AGENTS.md.
* **File yang Boleh Dibuat / Diubah**:
  * `analysis_options.yaml`
  * `android/app/src/main/AndroidManifest.xml`
  * File unit/widget test pendukung yang diperlukan.
* **Pengujian**:
  1. Jalankan `flutter analyze` dan pastikan hasil bersih (*no issues found*).
  2. Jalankan `flutter test` dan pastikan seluruh test suite lulus (100% pass).
  3. Jalankan aplikasi pada emulator Android target dan lakukan verifikasi alur end-to-end.
  4. Laporkan secara transparan seluruh hasil pengujian dan kondisi yang belum teruji sesuai DoD.
* **Status**: Todo

