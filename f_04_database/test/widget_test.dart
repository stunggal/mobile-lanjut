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
            {'nama': 'Kopi', 'harga': 12000},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('harga: 12000'), findsOneWidget);
  });

  testWidgets('menampilkan status kosong', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProdukPage(loadProduk: () async => []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada produk.'), findsOneWidget);
  });
}
