import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';

void main() {
  group('Kos Model Unit Test', () {
    final fixedDateTime = DateTime.parse('2026-11-24T00:00:00.000Z');

    final testKosMap = <String, dynamic>{
      'id': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      'owner_id': 'f0e1d2c3-b4a5-9687-8594-a3b2c1d0e1f2',
      'nama': 'Kos Melati Indah',
      'alamat_area': 'Jl. Kampus Jimbaran No. 12',
      'harga_per_bulan': 850000,
      'deskripsi': 'Kamar bersih, lingkungan tenang dan nyaman untuk mahasiswa.',
      'fasilitas': 'Wi-Fi, Kasur, Lemari, Kamar Mandi Dalam',
      'tipe_kos': 'Campur',
      'nomor_kontak': '081234567890',
      'created_at': '2026-11-24T00:00:00.000Z',
      'updated_at': '2026-11-24T00:00:00.000Z',
    };

    final testKosObject = Kos(
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      ownerId: 'f0e1d2c3-b4a5-9687-8594-a3b2c1d0e1f2',
      nama: 'Kos Melati Indah',
      alamatArea: 'Jl. Kampus Jimbaran No. 12',
      hargaPerBulan: 850000,
      deskripsi: 'Kamar bersih, lingkungan tenang dan nyaman untuk mahasiswa.',
      fasilitas: 'Wi-Fi, Kasur, Lemari, Kamar Mandi Dalam',
      tipeKos: 'Campur',
      nomorKontak: '081234567890',
      createdAt: fixedDateTime,
      updatedAt: fixedDateTime,
    );

    test('fromJson berhasil mengonversi Map JSON menjadi objek Kos dengan benar', () {
      final kos = Kos.fromJson(testKosMap);

      expect(kos.id, equals('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'));
      expect(kos.ownerId, equals('f0e1d2c3-b4a5-9687-8594-a3b2c1d0e1f2'));
      expect(kos.nama, equals('Kos Melati Indah'));
      expect(kos.alamatArea, equals('Jl. Kampus Jimbaran No. 12'));
      expect(kos.hargaPerBulan, equals(850000));
      expect(kos.deskripsi, equals('Kamar bersih, lingkungan tenang dan nyaman untuk mahasiswa.'));
      expect(kos.fasilitas, equals('Wi-Fi, Kasur, Lemari, Kamar Mandi Dalam'));
      expect(kos.tipeKos, equals('Campur'));
      expect(kos.nomorKontak, equals('081234567890'));
      expect(kos.createdAt, equals(fixedDateTime));
      expect(kos.updatedAt, equals(fixedDateTime));
    });

    test('toJson berhasil mengonversi objek Kos menjadi Map JSON dengan key database', () {
      final json = testKosObject.toJson();

      expect(json['id'], equals('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'));
      expect(json['owner_id'], equals('f0e1d2c3-b4a5-9687-8594-a3b2c1d0e1f2'));
      expect(json['nama'], equals('Kos Melati Indah'));
      expect(json['alamat_area'], equals('Jl. Kampus Jimbaran No. 12'));
      expect(json['harga_per_bulan'], equals(850000));
      expect(json['deskripsi'], equals('Kamar bersih, lingkungan tenang dan nyaman untuk mahasiswa.'));
      expect(json['fasilitas'], equals('Wi-Fi, Kasur, Lemari, Kamar Mandi Dalam'));
      expect(json['tipe_kos'], equals('Campur'));
      expect(json['nomor_kontak'], equals('081234567890'));
      expect(json['created_at'], equals('2026-11-24T00:00:00.000Z'));
      expect(json['updated_at'], equals('2026-11-24T00:00:00.000Z'));
    });

    test('Round-trip serialisasi dan deserialisasi mempertahankan nilai objek', () {
      final json = testKosObject.toJson();
      final reconstructed = Kos.fromJson(json);

      expect(reconstructed, equals(testKosObject));
      expect(reconstructed.hashCode, equals(testKosObject.hashCode));
    });

    test('copyWith berhasil membuat salinan objek dengan nilai atribut yang diubah', () {
      final updated = testKosObject.copyWith(
        nama: 'Kos Melati Barokah',
        hargaPerBulan: 900000,
        tipeKos: 'Putri',
      );

      expect(updated.id, equals(testKosObject.id));
      expect(updated.nama, equals('Kos Melati Barokah'));
      expect(updated.hargaPerBulan, equals(900000));
      expect(updated.tipeKos, equals('Putri'));
      expect(updated.ownerId, equals(testKosObject.ownerId));
      expect(updated.alamatArea, equals(testKosObject.alamatArea));
    });
  });
}

