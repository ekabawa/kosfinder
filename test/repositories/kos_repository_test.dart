import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

class TestableKosRepository extends KosRepository {
  final Future<List<Kos>> Function() onFetchKos;

  TestableKosRepository({required this.onFetchKos});

  @override
  Future<List<Kos>> fetchKos() => onFetchKos();
}

void main() {
  group('KosRepository Unit Tests', () {
    final dummyKos = Kos(
      id: 'kos-1',
      ownerId: 'owner-1',
      nama: 'Kos Mawar',
      alamatArea: 'Jimbaran',
      hargaPerBulan: 700000,
      deskripsi: 'Kos nyaman',
      fasilitas: 'Wi-Fi, Kasur',
      tipeKos: 'Putri',
      nomorKontak: '081234567890',
      createdAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-24T00:00:00.000Z'),
    );

    test('Mengembalikan daftar kos ketika pemanggilan berhasil', () async {
      final repository = TestableKosRepository(
        onFetchKos: () async => [dummyKos],
      );

      final result = await repository.fetchKos();

      expect(result, isA<List<Kos>>());
      expect(result.length, equals(1));
      expect(result.first.nama, equals('Kos Mawar'));
    });

    test('Melempar Exception ketika terjadi kegagalan jaringan atau database', () async {
      final repository = TestableKosRepository(
        onFetchKos: () async => throw Exception('Koneksi internet terputus'),
      );

      expect(
        () async => await repository.fetchKos(),
        throwsA(isA<Exception>()),
      );
    });

    test('Memastikan instansiasi KosRepository tanpa Supabase terinisialisasi melempar AssertionError saat client diakses', () {
      final repository = KosRepository();
      expect(() => repository.client, throwsA(isA<AssertionError>()));
    });
  });
}

