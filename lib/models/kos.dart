class Kos {
  final String id;
  final String ownerId;
  final String nama;
  final String alamatArea;
  final int hargaPerBulan;
  final String deskripsi;
  final String fasilitas;
  final String tipeKos;
  final String nomorKontak;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Kos({
    required this.id,
    required this.ownerId,
    required this.nama,
    required this.alamatArea,
    required this.hargaPerBulan,
    required this.deskripsi,
    required this.fasilitas,
    required this.tipeKos,
    required this.nomorKontak,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Mengonversi Map JSON dari Supabase menjadi objek [Kos].
  factory Kos.fromJson(Map<String, dynamic> json) {
    return Kos(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      nama: json['nama'] as String,
      alamatArea: json['alamat_area'] as String,
      hargaPerBulan: (json['harga_per_bulan'] as num).toInt(),
      deskripsi: json['deskripsi'] as String,
      fasilitas: json['fasilitas'] as String,
      tipeKos: json['tipe_kos'] as String,
      nomorKontak: json['nomor_kontak'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Mengonversi objek [Kos] menjadi Map JSON yang sesuai dengan kolom tabel Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'nama': nama,
      'alamat_area': alamatArea,
      'harga_per_bulan': hargaPerBulan,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'tipe_kos': tipeKos,
      'nomor_kontak': nomorKontak,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Membuat salinan objek [Kos] dengan nilai atribut yang diperbarui.
  Kos copyWith({
    String? id,
    String? ownerId,
    String? nama,
    String? alamatArea,
    int? hargaPerBulan,
    String? deskripsi,
    String? fasilitas,
    String? tipeKos,
    String? nomorKontak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Kos(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      nama: nama ?? this.nama,
      alamatArea: alamatArea ?? this.alamatArea,
      hargaPerBulan: hargaPerBulan ?? this.hargaPerBulan,
      deskripsi: deskripsi ?? this.deskripsi,
      fasilitas: fasilitas ?? this.fasilitas,
      tipeKos: tipeKos ?? this.tipeKos,
      nomorKontak: nomorKontak ?? this.nomorKontak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kos &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.nama == nama &&
        other.alamatArea == alamatArea &&
        other.hargaPerBulan == hargaPerBulan &&
        other.deskripsi == deskripsi &&
        other.fasilitas == fasilitas &&
        other.tipeKos == tipeKos &&
        other.nomorKontak == nomorKontak &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      nama,
      alamatArea,
      hargaPerBulan,
      deskripsi,
      fasilitas,
      tipeKos,
      nomorKontak,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Kos(id: $id, ownerId: $ownerId, nama: $nama, alamatArea: $alamatArea, hargaPerBulan: $hargaPerBulan, tipeKos: $tipeKos, nomorKontak: $nomorKontak)';
  }
}

