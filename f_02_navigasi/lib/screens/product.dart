import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2, size: 64, color: Colors.blueAccent),
          SizedBox(height: 12),
          Text(
            'Halaman Produk',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Daftar produk akan ditampilkan di sini.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
