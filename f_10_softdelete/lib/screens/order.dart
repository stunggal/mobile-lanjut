import 'package:flutter/material.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 64, color: Colors.blueAccent),
          SizedBox(height: 12),
          Text(
            'Halaman Pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Riwayat pesanan Anda akan muncul di sini.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
