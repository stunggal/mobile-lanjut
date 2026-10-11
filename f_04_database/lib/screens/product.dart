import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _placeholderImage =
    'https://img.magnific.com/free-photo/smiling-young-woman-holding-retro-camera_329181-142.jpg?semt=ais_hybrid&w=740&q=80';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, this.loadProduk});
  final Future<List<Map<String, dynamic>>> Function()? loadProduk;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

// alias agar test lama ProdukPage tetap jalan
class ProdukPage extends ProductScreen {
  const ProdukPage({super.key, super.loadProduk});
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<List<Map<String, dynamic>>> _produkFuture;

  @override
  void initState() {
    super.initState();
    _produkFuture = _bacaProduk();
  }

  Future<List<Map<String, dynamic>>> _bacaProduk() {
    // tabel supabase `barang` kolom: id, nama, deskripsi, rating, harga, stok
    return widget.loadProduk?.call() ??
        Supabase.instance.client.from('barang').select();
  }

  // FIX: jangan lakukan async di dalam setState(). Set state sync, await di luar.
  Future<void> _muatUlang() async {
    setState(() {
      _produkFuture = _bacaProduk();
    });
    try {
      await _produkFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _produkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Gagal memuat produk', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _muatUlang,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        final produk = snapshot.data ?? [];
        if (produk.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Tidak ada produk tersedia'),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _muatUlang, icon: const Icon(Icons.refresh), label: const Text('Muat ulang')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _muatUlang,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: produk.length,
            itemBuilder: (context, index) => _ProductCard(row: produk[index]),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ProductCard({required this.row});
  @override
  Widget build(BuildContext context) {
    final id = row['id']?.toString() ?? '-';
    final nama = row['nama']?.toString() ?? 'Tanpa nama';
    final deskripsi = row['deskripsi']?.toString() ?? '-';
    final rating = double.tryParse(row['rating']?.toString() ?? '') ?? 0;
    final harga = row['harga'];
    final stok = int.tryParse(row['stok']?.toString() ?? '') ?? 0;
    final hargaText = harga == null ? '-' : 'Rp ${_formatAngka(harga)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_placeholderImage, width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('ID: $id', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text(deskripsi, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: Text('ID $id', style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                if (rating > 0) ...[const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 2), Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))],
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(hargaText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: stok > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(stok > 0 ? 'Stok: $stok' : 'Habis', style: TextStyle(fontSize: 11, color: stok > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500))),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
  void _showDetail(BuildContext context) {
    final id = row['id']?.toString() ?? '-';
    final nama = row['nama']?.toString() ?? 'Tanpa nama';
    final deskripsi = row['deskripsi']?.toString() ?? '-';
    final rating = double.tryParse(row['rating']?.toString() ?? '') ?? 0;
    final harga = row['harga'];
    final stok = int.tryParse(row['stok']?.toString() ?? '') ?? 0;
    final hargaText = harga == null ? '-' : 'Rp ${_formatAngka(harga)}';
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5, expand: false, builder: (context, sc) => SingleChildScrollView(controller: sc, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_placeholderImage, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: double.infinity, height: 200, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey)))),
      const SizedBox(height: 16),
      Text(nama, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text('ID: $id', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 8),
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)), child: Text('ID $id', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Text(hargaText, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 16),
      Row(children: [const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4), Text('${rating.toStringAsFixed(1)}  \u2022  Stok $stok', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]),
      const SizedBox(height: 16),
      Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(deskripsi, style: const TextStyle(fontSize: 15, height: 1.5)),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _detailRow('ID', id), _detailRow('Nama', nama), _detailRow('Harga', hargaText), _detailRow('Rating', rating.toString()), _detailRow('Stok', stok.toString()),
      ])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama ditambahkan ke keranjang'))); }, icon: const Icon(Icons.add_shopping_cart), label: Text('Beli Sekarang - $hargaText', style: const TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ])))));
  }
  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 70, child: Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[600]))), Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))]));
}
String _formatAngka(dynamic n) {
  if (n == null) return '-';
  final v = num.tryParse(n.toString());
  if (v == null) return n.toString();
  if (v % 1 == 0) return v.toInt().toString();
  return v.toStringAsFixed(2);
}
