# Product Requirements Document (PRD): KosFinder (Versi 1)

## 1. Masalah dan Tujuan yang Bisa Diukur
* **Masalah**: Informasi kos sekitar kampus tersebar tidak terstruktur di media sosial/grup chat; pencari kos sulit membandingkan harga/fasilitas tanpa login; pemilik kos belum memiliki wadah terpusat untuk mengelola kos miliknya secara mandiri.
* **Tujuan Terukur**:
  1. *Aksesibilitas*: 100% pencari kos dapat melihat daftar dan detail kos tanpa perlu registrasi/login.
  2. *Efisiensi*: Pencari kos dapat menemukan kos dan mencoba filter harga dalam waktu maksimal 30 detik pada percobaan pertama.
  3. *Integritas & Keamanan*: 100% aksi modifikasi data terikat ke `owner_id` dan divalidasi oleh Supabase Row Level Security (RLS) sehingga 0% data dapat dimodifikasi/dihapus oleh pengguna lain.
  4. *Keandalan*: 0 *crash* aplikasi saat terjadi kegagalan jaringan atau server melalui *graceful error handling*.

## 2. Pengguna Aplikasi
* **Pencari Kos (Publik)**: Mahasiswa/masyarakat pencari kos di sekitar kampus. Mengakses fitur tanpa login.
* **Pemilik Kos**: Pemilik hunian kos. Wajib registrasi dan login dengan Email dan Kata Sandi untuk mengelola data kos.

## 3. Scope Versi 1
* **In-Scope**:
  * Daftar kos publik (nama, area, harga/bulan, tipe kos, fasilitas) tanpa login.
  * Detail informasi kos lengkap dengan nomor kontak telepon/WhatsApp pemilik (teks).
  * Pencarian berbasis kata kunci nama atau area (*case-insensitive*).
  * Filter batas nominal harga sewa maksimum (`harga <= harga_maksimum`).
  * Registrasi dan login akun pemilik via Supabase Auth (Email & Password).
  * Manajemen data kos oleh pemilik (Tambah, Ubah, Hapus kos milik sendiri).
  * Penegakan otorisasi data dengan Supabase Row Level Security (RLS).
  * Penanganan kondisi kosong (*empty state*) dan kegagalan jaringan (*error state*).
* **Out-of-Scope**: Pembayaran online, chat dalam aplikasi, ulasan/rating bintang, rekomendasi AI, verifikasi identitas pemilik, upload foto kos, dan peta/koordinat GPS.

## 4. Non-Functional Requirements (NFR)
* **NFR-SEC (Keamanan)**: Akses database diamankan via Supabase RLS. Operasi `SELECT` terbuka publik; `INSERT`, `UPDATE`, `DELETE` wajib terautentikasi dan `auth.uid() == owner_id`.
  * *Kriteria Uji*: Operasi UPDATE dan DELETE terhadap kos milik orang lain harus ditolak atau tidak menghasilkan perubahan data, dan data asli di database tetap utuh.
* **NFR-REL (Keandalan)**: Aplikasi tidak boleh *force close* (*crash*) saat koneksi internet offline, *timeout*, atau server galat.
  * *Kriteria Uji*: Pemutusan koneksi saat memuat data atau menyimpan formulir harus menampilkan pesan error informatif tanpa *crash*.
* **NFR-USE (Kemudahan Penggunaan)**: Antarmuka langsung menampilkan daftar kos pada layar utama tanpa halaman pembatas login/onboarding.
  * *Kriteria Uji*: Pengguna baru dapat menemukan kos dan mencoba filter harga dalam waktu maksimal 30 detik pada percobaan pertama.
* **NFR-PER (Performa)**:
  * *Kriteria Uji Pemuatan Data*: Waktu pemuatan awal daftar kos (hingga 20 item) terukur maksimal 2 detik pada koneksi internet stabil via DevTools/Network Profiler.
  * *Kriteria Uji Pencarian & Filter*: Waktu respons filter dan pencarian terukur maksimal 500 ms setelah input selesai via DevTools Profiler.
* **NFR-PRI (Privasi)**: Hanya menyimpan email & hashed password pemilik di Supabase Auth. Tidak ada pelacakan lokasi latar belakang atau pembacaan data pribadi perangkat.
  * *Kriteria Uji*: Berkas `AndroidManifest.xml` hanya mendeklarasikan izin `android.permission.INTERNET`.

## 5. User Stories & Acceptance Criteria

### US01: Melihat Daftar Kos (Pencari Kos)
**Sebagai** Pencari Kos, **saya ingin** melihat daftar kos tanpa login, **agar** saya dapat menemukan pilihan tempat tinggal di sekitar kampus dengan mudah.
* **US01-AC1**: *Given* pengguna membuka aplikasi tanpa login, *When* data kos tersedia di Supabase, *Then* aplikasi menampilkan daftar kos dengan nama, area, harga/bulan, tipe, dan fasilitas.
* **US01-AC2**: *Given* pengguna membuka aplikasi, *When* belum ada data kos di database, *Then* aplikasi menampilkan pesan bahwa belum ada kos yang tersedia (*empty state*).
* **US01-AC3**: *Given* koneksi internet terputus, *When* aplikasi memuat daftar kos, *Then* aplikasi menampilkan pesan galat koneksi dan opsi coba lagi tanpa *crash*.

### US02: Melihat Detail Informasi Kos (Pencari Kos)
**Sebagai** Pencari Kos, **saya ingin** melihat detail informasi kos, **agar** saya mengetahui fasilitas lengkap dan kontak pemilik yang dapat dihubungi.
* **US02-AC1**: *Given* pengguna memilih salah satu kos dari daftar, *When* halaman detail dibuka, *Then* aplikasi menampilkan nama, area, harga/bulan, tipe, deskripsi, fasilitas, dan nomor telepon/WhatsApp pemilik (teks).
* **US02-AC2**: *Given* koneksi terputus saat membuka detail kos, *When* data gagal dimuat, *Then* aplikasi menampilkan pesan kesalahan jaringan tanpa *crash*.

### US03: Mencari Kos Berdasarkan Nama atau Area (Pencari Kos)
**Sebagai** Pencari Kos, **saya ingin** mencari kos berdasarkan kata kunci nama atau area, **agar** saya dapat menemukan kos di lokasi yang relevan dengan cepat.
* **US03-AC1**: *Given* pengguna di layar daftar kos, *When* memasukkan kata kunci teks (contoh: "jimbaran" atau "KAMPUS"), *Then* aplikasi menampilkan kos yang nama atau areanya memuat kata kunci tersebut (*case-insensitive*).
* **US03-AC2**: *Given* pengguna memasukkan kata kunci yang tidak ada pada data, *When* pencarian diproses, *Then* aplikasi menampilkan pesan bahwa kos tidak ditemukan.

### US04: Memfilter Kos Berdasarkan Harga Maksimum (Pencari Kos)
**Sebagai** Pencari Kos, **saya ingin** memfilter kos berdasarkan harga maksimum, **agar** saya hanya melihat kos yang sesuai anggaran saya.
* **US04-AC1**: *Given* pengguna memasukkan batas harga maksimum (misal: Rp2.000.000), *When* filter diterapkan, *Then* aplikasi menampilkan seluruh kos dengan harga $\le$ Rp2.000.000 dan menyembunyikan kos di atas batas tersebut.
* **US04-AC2**: *Given* pengguna menetapkan batas harga di bawah harga kos terendah, *When* filter diterapkan, *Then* aplikasi menampilkan pesan bahwa tidak ada kos dalam batas harga tersebut.

### US05: Registrasi dan Login Pemilik Kos (Pemilik Kos)
**Sebagai** Pemilik Kos, **saya ingin** mendaftar dan login dengan email dan kata sandi, **agar** saya dapat mengelola data kos saya.
* **US05-AC1**: *Given* pengguna di halaman registrasi, *When* mengisi email valid dan kata sandi lalu klik daftar, *Then* akun terbuat di Supabase Auth dan sesi login aktif.
* **US05-AC2**: *Given* pemilik telah terdaftar, *When* memasukkan email dan kata sandi yang sesuai, *Then* login berhasil dan aplikasi masuk ke halaman kelola kos.
* **US05-AC3**: *Given* kredensial tidak cocok atau jaringan terputus, *When* tombol login ditekan, *Then* aplikasi menampilkan pesan kesalahan autentikasi/koneksi tanpa *crash*.

### US06: Menambahkan Data Kos Baru (Pemilik Kos)
**Sebagai** Pemilik Kos yang login, **saya ingin** menambahkan data kos baru, **agar** kos saya dapat dipublikasikan ke pencari kos.
* **US06-AC1**: *Given* pemilik telah login, *When* mengisi seluruh field wajib (nama, area, harga/bulan angka, deskripsi, fasilitas, tipe kos, nomor kontak) dan menekan simpan, *Then* data tersimpan di Supabase dengan `owner_id` terisi otomatis sesuai ID pemilik.
* **US06-AC2**: *Given* pemilik menambah data kos, *When* field wajib kosong atau harga bukan angka, *Then* sistem menolak penyimpanan dan menampilkan pesan validasi field.
* **US06-AC3**: *Given* koneksi terputus saat simpan, *When* tombol simpan ditekan, *Then* muncul notifikasi kegagalan koneksi dan data form yang diisi tidak hilang.

### US07: Mengubah Informasi Kos Milik Sendiri (Pemilik Kos)
**Sebagai** Pemilik Kos yang login, **saya ingin** mengubah data informasi kos milik saya, **agar** data harga, fasilitas, atau kontak tetap akurat.
* **US07-AC1**: *Given* pemilik login dan membuka formulir ubah kos miliknya (`auth.uid() == owner_id`), *When* data diubah dan ditekan simpan, *Then* data kos di Supabase berhasil diperbarui.
* **US07-AC2**: *Given* akun pemilik mencoba mengirim permintaan ubah kos milik akun lain (`auth.uid() != owner_id`), *When* update dikirim ke Supabase, *Then* Supabase RLS menolak operasi atau tidak menghasilkan perubahan data, dan data asli di database tetap utuh.

### US08: Menghapus Data Kos Milik Sendiri (Pemilik Kos)
**Sebagai** Pemilik Kos yang login, **saya ingin** menghapus kos milik saya, **agar** unit yang sudah tidak disewakan tidak tampil lagi di aplikasi.
* **US08-AC1**: *Given* pemilik login dan memilih hapus kos miliknya (`auth.uid() == owner_id`), *When* konfirmasi hapus disetujui, *Then* baris data kos terhapus dari Supabase.
* **US08-AC2**: *Given* akun pemilik mencoba mengirim permintaan hapus kos milik akun lain (`auth.uid() != owner_id`), *When* delete dikirim ke Supabase, *Then* Supabase RLS menolak operasi atau tidak menghapus baris data, dan data asli tetap aman di database.

## 6. Pertanyaan Terbuka / Klarifikasi Lanjutan
*Tidak ada pertanyaan terbuka. Seluruh kebutuhan, batasan scope, aturan otorisasi RLS, dan penanganan kondisi error telah disepakati secara lengkap.*
