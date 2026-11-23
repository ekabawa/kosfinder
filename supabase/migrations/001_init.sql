-- ==============================================================================
-- Migrasi: 001_init.sql
-- Aplikasi: KosFinder
-- Deskripsi: Inisialisasi tabel kos beserta aturan Row Level Security (RLS).
-- ==============================================================================

-- 1. Buat tabel kos
CREATE TABLE IF NOT EXISTS public.kos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    alamat_area TEXT NOT NULL,
    harga_per_bulan BIGINT NOT NULL CHECK (harga_per_bulan >= 0),
    deskripsi TEXT NOT NULL,
    fasilitas TEXT NOT NULL,
    tipe_kos TEXT NOT NULL CHECK (tipe_kos IN ('Putra', 'Putri', 'Campur')),
    nomor_kontak TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks untuk mengoptimalkan performa pencarian teks dan filter harga
CREATE INDEX IF NOT EXISTS idx_kos_nama_area ON public.kos (nama, alamat_area);
CREATE INDEX IF NOT EXISTS idx_kos_harga ON public.kos (harga_per_bulan);
CREATE INDEX IF NOT EXISTS idx_kos_owner_id ON public.kos (owner_id);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan RLS (Policies)

-- US01, US02, US03, US04: Semua pengguna (publik/anonim dan terautentikasi) boleh melihat semua data kos
CREATE POLICY "Semua pengguna dapat melihat data kos"
ON public.kos
FOR SELECT
USING (true);

-- US06: Hanya pemilik terautentikasi yang boleh menambah data kos baru atas namanya sendiri
CREATE POLICY "Pemilik dapat menambah data kos miliknya"
ON public.kos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_id);

-- US07: Hanya pemilik yang boleh mengubah data kos miliknya sendiri
CREATE POLICY "Pemilik dapat mengubah data kos miliknya"
ON public.kos
FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- US08: Hanya pemilik yang boleh menghapus data kos miliknya sendiri
CREATE POLICY "Pemilik dapat menghapus data kos miliknya"
ON public.kos
FOR DELETE
TO authenticated
USING (auth.uid() = owner_id);

-- 4. Hak Akses Tabel (GRANT)
-- Mengizinkan role anon dan authenticated untuk membaca data (SELECT)
GRANT SELECT ON TABLE public.kos TO anon, authenticated;

-- Mengizinkan role authenticated untuk menambah, mengubah, dan menghapus data (INSERT, UPDATE, DELETE)
GRANT INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;


