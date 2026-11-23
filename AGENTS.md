# Aturan Kerja Agen AI: KosFinder

Dokumen ini berisi panduan dan aturan baku bagi agen AI dalam mengembangkan aplikasi KosFinder.

## 1. Konteks Proyek & Dokumen Acuan
Setiap pengerjaan harus merujuk dan patuh pada dokumen spesifikasi berikut:
- `docs/PRD.md`: Kebutuhan produk, batasan versi 1, User Stories, Acceptance Criteria, dan NFR.
- `docs/ARCHITECTURE.md`: Arsitektur sistem, struktur folder, pemodelan data, dan pola state management.
- `docs/TASKS.md`: Rincian daftar task pengerjaan beserta ID task yang harus diselesaikan bertahap.

## 2. Prinsip & Cara Kerja
- **Satu task per permintaan**: Kerjakan hanya satu task yang sedang diminta dalam satu iterasi.
- **Batasan perubahan file**: Jangan mengubah file di luar cakupan task yang sedang dikerjakan.
- **Perencanaan perubahan besar**: Buat rencana langkah kerja dan komunikasikan terlebih dahulu sebelum mengeksekusi perubahan besar/struktural.
- **Pilih solusi paling sederhana**: Utamakan kode yang bersih, mudah dipahami (*KISS* / *Keep It Simple, Stupid*), dan tanpa abstraksi berlebihan.
- **Izin penambahan package**: Dilarang menambahkan package atau dependensi baru ke `pubspec.yaml` tanpa persetujuan tertulis dari pengguna.

## 3. Teknologi Utama
- **Framework**: Flutter (Dart) untuk platform Android.
- **State Management**: Provider.
- **Backend & Database**: Supabase (Supabase Auth & PostgreSQL).

## 4. Keamanan
- **Tanpa kredensial di kode**: Dilarang menaruh API key, secret, password, atau token secara *hardcoded* di dalam kode sumber.
- **Larangan `service_role`**: Kunci `service_role` tidak boleh digunakan di dalam aplikasi klien. Gunakan hanya `anon key` publik.
- **Otorisasi via RLS**: Seluruh pembatasan hak akses data wajib ditegakkan di level database menggunakan Supabase Row Level Security (RLS), bukan hanya mengandalkan logika di sisi klien.

## 5. Standar Git
- **Satu task satu commit**: Lakukan satu commit untuk setiap task yang selesai dan terverifikasi.
- **Format pesan commit**: Pesan commit wajib mencantumkan ID task yang bersangkutan (contoh: `feat(T01): inisialisasi state provider` atau `docs(T02): update arsitektur`).

## 6. Definition of Done (DoD)
Sebuah task dinyatakan selesai jika memenuhi seluruh kriteria berikut:
1. `flutter analyze` bersih (0 error, 0 warning).
2. `flutter test` berhasil lulus (100% pass).
3. Aplikasi berhasil dijalankan dan diverifikasi di device/emulator target.
4. Laporkan secara transparan jika ada bagian alur atau kondisi yang belum/tidak dapat diuji.

## 7. Identitas Pengembang
- Pada halaman **About** aplikasi KosFinder, wajib mencantumkan identitas pengembang:
  - **NIM**: 2415051008
  - **Nama**: I Putu Eka Bawa Utama

