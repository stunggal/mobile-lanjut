import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://gxiuwbzsprglffwjvfym.supabase.co';
const _supabasePublishableKey =
    'sb_publishable_e9_S28yMAggT1zlC1pQGdg_3JhxVjVQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
  runApp(const ProdukApp());
}

class ProdukApp extends StatelessWidget {
  const ProdukApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Produk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ProdukPage(),
    );
  }
}

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key, this.loadProduk});

  final Future<List<Map<String, dynamic>>> Function()? loadProduk;

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  late Future<List<Map<String, dynamic>>> _produkFuture;

  @override
  void initState() {
    super.initState();
    _produkFuture = _bacaProduk();
  }

  Future<List<Map<String, dynamic>>> _bacaProduk() {
    return widget.loadProduk?.call() ??
        Supabase.instance.client.from('produk').select();
  }

  void _muatUlang() {
    setState(() {
      _produkFuture = _bacaProduk();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        actions: [
          IconButton(
            onPressed: _muatUlang,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _produkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _PesanTengah(
              icon: Icons.error_outline,
              message: 'Gagal membaca produk.\n${snapshot.error}',
              action: FilledButton.icon(
                onPressed: _muatUlang,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            );
          }

          final produk = snapshot.data ?? [];
          if (produk.isEmpty) {
            return const _PesanTengah(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada produk.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _muatUlang(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: produk.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _KartuProduk(produk: produk[index], index: index);
              },
            ),
          );
        },
      ),
    );
  }
}

class _KartuProduk extends StatelessWidget {
  const _KartuProduk({required this.produk, required this.index});

  final Map<String, dynamic> produk;
  final int index;

  @override
  Widget build(BuildContext context) {
    const kolomNama = ['nama', 'nama_produk', 'name', 'product_name'];
    final kolomJudul = kolomNama.cast<String?>().firstWhere(
      (kolom) => kolom != null && produk[kolom] != null,
      orElse: () => null,
    );
    final judul = kolomJudul == null
        ? 'Produk ${index + 1}'
        : _formatNilai(produk[kolomJudul]);
    final detail = produk.entries
        .where((entry) => entry.key != kolomJudul)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: Theme.of(context).textTheme.titleMedium),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final entry in detail)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key}: ${_formatNilai(entry.value)}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PesanTengah extends StatelessWidget {
  const _PesanTengah({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String _formatNilai(Object? nilai) {
  if (nilai == null) return '-';
  if (nilai is Map || nilai is List) return jsonEncode(nilai);
  return nilai.toString();
}
