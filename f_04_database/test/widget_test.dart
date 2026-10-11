// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f_04_database/main.dart';

void main() {
  testWidgets('menampilkan produk yang dibaca', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProdukPage(
          loadProduk: () async => [
            {
              'id': 1,
              'nama': 'Kopi',
              'deskripsi': 'Kopi arabika',
              'rating': 4.5,
              'harga': 12000,
              'stok': 10,
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Rp 12000'), findsOneWidget);
  });

  testWidgets('menampilkan status kosong', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProdukPage(loadProduk: () async => []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada produk tersedia'), findsOneWidget);
  });
}
