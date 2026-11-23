import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/screens/about_screen.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    testWidgets('Menampilkan identitas pengembang secara akurat (NIM dan Nama)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      // Verifikasi identitas pengembang sesuai AGENTS.md
      expect(find.text('2415051008'), findsOneWidget);
      expect(find.text('I Putu Eka Bawa Utama'), findsOneWidget);

      // Verifikasi komponen pendukung halaman About
      expect(find.text('Tentang Aplikasi'), findsOneWidget);
      expect(find.text('KosFinder'), findsOneWidget);
      expect(find.text('Identitas Pengembang'), findsOneWidget);
      expect(find.text('Flutter (Android) • Provider • Supabase'), findsOneWidget);
    });

    testWidgets('Dapat dibuka melalui tombol info pada halaman utama', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Pastikan icon info tentang aplikasi ada pada AppBar
      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      // Ketuk tombol info dan tunggu transisi animasi navigasi selesai
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // Verifikasi halaman AboutScreen berhasil dibuka
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('2415051008'), findsOneWidget);
      expect(find.text('I Putu Eka Bawa Utama'), findsOneWidget);
    });
  });
}

