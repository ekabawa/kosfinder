# Arsitektur Aplikasi: KosFinder (Versi 1)

## 1. Komponen Aplikasi (Screen - Provider - Repository - Supabase)
Arsitektur menerapkan pola berlapis terpisah (*layered architecture*) yang sederhana dan mudah diuji:
* **Screen (Presentation Layer)**: Widget Flutter yang menyajikan antarmuka visual, merender data dari Provider, dan meneruskan interaksi pengguna ke Provider.
  * Komponen: `KosListScreen` (US01, US03, US04), `KosDetailScreen` (US02), `AuthScreen` (US05), `MyKosScreen` (US06, US07, US08), `KosFormScreen` (US06, US07), `AboutScreen`.
* **Provider (State Management & Business Logic)**: Kelas `ChangeNotifier` pengelola kondisi aplikasi (data, loading state, error message), memfilter data, serta memanggil Repository.
  * Komponen: `KosProvider` (US01, US02, US03, US04, US06, US07, US08), `AuthProvider` (US05).
* **Repository (Data Access Layer)**: Kelas perantara yang membungkus pemanggilan SDK Supabase, mengonversi respon JSON ke model data Dart `Kos`, serta menangani penangkapan galat jaringan.
  * Komponen: `KosRepository` (US01, US02, US03, US04, US06, US07, US08), `AuthRepository` (US05).
* **Supabase (Backend Service)**: Layanan backend penyedia PostgreSQL Database dan Supabase Auth dengan pengamanan otorisasi via Row Level Security (RLS).
  * Komponen: Supabase Auth (US05), Supabase Database `kos` (US01, US02, US03, US04, US06, US07, US08).

## 2. Daftar Layar dan Alur Navigasi
1. **KosListScreen (Layar Utama)**:
   * Menampilkan daftar kos publik, kolom pencarian teks (nama/area), dan filter harga maksimum.
   * Aksi Navigasi:
     * Ketuk kartu kos $\rightarrow$ Buka `KosDetailScreen`.
     * Ketuk ikon Akun/Login $\rightarrow$ Buka `AuthScreen` (jika belum login) atau `MyKosScreen` (jika sudah login).
     * Ketuk ikon Info $\rightarrow$ Buka `AboutScreen`.
2. **KosDetailScreen**: Menampilkan detail lengkap informasi kos dan nomor telepon/WhatsApp pemilik (teks).
3. **AuthScreen**: Formulir registrasi dan login pemilik kos (tab Login / Daftar menggunakan Email & Password). Sukses login $\rightarrow$ ganti layar ke `MyKosScreen`.
4. **MyKosScreen**: Menampilkan daftar kos milik akun pemilik yang aktif, tombol Tambah Kos, tombol Edit, tombol Hapus, serta tombol Logout.
5. **KosFormScreen**: Formulir input tambah data kos baru atau edit data kos yang sudah ada. Sukses simpan $\rightarrow$ kembali (*pop*) ke `MyKosScreen`.
6. **AboutScreen**: Menampilkan identitas pengembang (NIM: 2415051008, Nama: I Putu Eka Bawa Utama).

## 3. Rencana Database
* **Nama Tabel**: `public.kos`
* **Definisi Kolom & Tipe Data**:
  * `id` (`UUID`, Primary Key, default `gen_random_uuid()`): Identitas unik setiap kos.
  * `owner_id` (`UUID`, Not Null, Foreign Key ke `auth.users(id)` `ON DELETE CASCADE`): ID akun pemilik kos.
  * `nama` (`TEXT`, Not Null): Nama unit kos.
  * `alamat_area` (`TEXT`, Not Null): Area atau alamat kos (target pencarian teks).
  * `harga_per_bulan` (`BIGINT`, Not Null, `CHECK (harga_per_bulan >= 0)`): Biaya sewa per bulan bertipe angka.
  * `deskripsi` (`TEXT`, Not Null): Deskripsi lengkap kos.
  * `fasilitas` (`TEXT`, Not Null): Informasi fasilitas kos.
  * `tipe_kos` (`TEXT`, Not Null, `CHECK (tipe_kos IN ('Putra', 'Putri', 'Campur'))`): Kategori penghuni kos.
  * `nomor_kontak` (`TEXT`, Not Null): Nomor telepon/WhatsApp pemilik untuk dihubungi pencari kos.
  * `created_at` (`TIMESTAMPTZ`, Not Null, default `now()`): Waktu data dibuat.
  * `updated_at` (`TIMESTAMPTZ`, Not Null, default `now()`): Waktu data terakhir diubah.
* **Relasi Data**: *Many-to-One* dari `kos.owner_id` ke `auth.users.id`. Satu akun pemilik dapat memiliki banyak data kos.
* **Aturan Akses (Otorisasi RLS)**:
  * `SELECT`: Publik (Anonim & Authenticated) dapat membaca seluruh data kos (US01, US02, US03, US04).
  * `INSERT`: Hanya user terautentikasi dengan syarat `auth.uid() = owner_id` (US06).
  * `UPDATE`: Hanya pemilik sah dengan syarat `auth.uid() = owner_id` (US07).
  * `DELETE`: Hanya pemilik sah dengan syarat `auth.uid() = owner_id` (US08).

## 4. Konfigurasi Supabase
Untuk menjaga keamanan kredensial, URL dan anon key tidak boleh ditulis secara *hardcoded* di dalam kode sumber:
* Nilai dibaca pada runtime Dart menggunakan:
  ```dart
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  ```
* Parameter disuplai melalui argumen build/run:
  ```bash
  flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=ey...
  ```
* Atau menggunakan berkas `.env` lokal (diabaikan git):
  ```bash
  flutter run --dart-define-from-file=.env
  ```

## 5. Cara Rilis
1. **Build APK Android**:
   Jalankan perintah build rilis dengan menyertakan konfigurasi environment:
   ```bash
   flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```
   Berkas APK siap didistribusikan pada lokasi: `build/app/outputs/flutter-apk/app-release.apk`.
2. **Publikasi GitHub Release**:
   * Buat tag versi pada git: `git tag -a v0.1.0 -m "Release v0.1.0" && git push origin v0.1.0`.
   * Pada repository GitHub (`https://github.com/ekabawa/kosfinder`), buat rilis baru berdasarkan tag tersebut dan unggah berkas `app-release.apk`.

## 6. Kebutuhan Package
Hanya package esensial berikut yang digunakan untuk menjaga aplikasi tetap ringan dan terfokus:
1. **`provider`**:
   * *Alasan*: Pengelolaan state reaktif yang sederhana, stabil, dan memisahkan logika bisnis dari tampilan widget UI secara bersih.
   * *User Story*: Dibutuhkan di seluruh User Story (**US01 s/d US08**).
2. **`supabase_flutter`**:
   * *Alasan*: SDK resmi Supabase untuk konektivitas client, otentikasi pemilik (Supabase Auth), serta operasi CRUD database PostgreSQL berbasis Row Level Security.
   * *User Story*: Autentikasi pemilik (**US05**) dan CRUD data kos (**US01, US02, US03, US04, US06, US07, US08**).

