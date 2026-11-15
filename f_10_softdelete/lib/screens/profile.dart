import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 64, color: Colors.blueAccent),
          SizedBox(height: 12),
          Text(
            'Halaman Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Pengaturan akun dan profil pengguna.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
