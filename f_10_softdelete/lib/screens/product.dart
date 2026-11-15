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
  bool _showTrash = false; // false = active, true = trash/soft-deleted

  @override
  void initState() {
    super.initState();
    _produkFuture = _bacaProduk();
  }

  Future<List<Map<String, dynamic>>> _bacaProduk() {
    if (widget.loadProduk != null) {
      return widget.loadProduk!.call();
    }
    // Soft delete: filter by deleted_at
    final query = Supabase.instance.client.from('barang').select();
    return _showTrash
        ? query.not('deleted_at', 'is', null).order('deleted_at', ascending: false)
        : query.isFilter('deleted_at', null).order('created_at', ascending: false);
  }

  Future<void> _muatUlang() async {
    setState(() {
      _produkFuture = _bacaProduk();
    });
    try {
      await _produkFuture;
    } catch (_) {}
  }

  void _toggleTrashView() {
    setState(() {
      _showTrash = !_showTrash;
      _produkFuture = _bacaProduk();
    });
  }

  Future<void> _showCreateSheet() async {
    final namaC = TextEditingController();
    final deskripsiC = TextEditingController();
    final ratingC = TextEditingController();
    final hargaC = TextEditingController();
    final stokC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  Text('Tambah Barang', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Isi data barang baru, disimpan ke Supabase tabel barang', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 16),
                  TextFormField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: deskripsiC, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)), maxLines: 3),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: hargaC, decoration: const InputDecoration(labelText: 'Harga *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib'; if (num.tryParse(v)==null) return 'Angka'; return null; })),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: stokC, decoration: const InputDecoration(labelText: 'Stok *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib'; if (int.tryParse(v)==null) return 'Integer'; return null; })),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: ratingC, decoration: const InputDecoration(labelText: 'Rating 0-5 (opsional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { if (v==null || v.trim().isEmpty) return null; final d=double.tryParse(v); if (d==null) return 'Angka'; if (d<0||d>5) return '0-5'; return null; }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => loading = true);
                        try {
                          final payload = {
                            'nama': namaC.text.trim(),
                            'deskripsi': deskripsiC.text.trim().isEmpty ? null : deskripsiC.text.trim(),
                            'rating': ratingC.text.trim().isEmpty ? null : double.parse(ratingC.text.trim()),
                            'harga': num.parse(hargaC.text.trim()),
                            'stok': int.parse(stokC.text.trim()),
                          }..removeWhere((k,v) => v==null);
                          await Supabase.instance.client.from('barang').insert(payload);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${payload['nama']} berhasil ditambahkan')));
                          _muatUlang();
                        } catch (e) {
                          setSheet(() => loading = false);
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red));
                        }
                      },
                      icon: loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.save),
                      label: Text(loading ? 'Menyimpan...' : 'Simpan'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    namaC.dispose(); deskripsiC.dispose(); ratingC.dispose(); hargaC.dispose(); stokC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<List<Map<String, dynamic>>>(
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
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: _muatUlang, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
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
                Icon(_showTrash ? Icons.delete_sweep_outlined : Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(_showTrash ? 'Tidak ada barang di keranjang sampah' : 'Tidak ada produk tersedia'),
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
            itemBuilder: (context, index) => _ProductCard(row: produk[index], onChanged: _muatUlang, isTrash: _showTrash),
          ),
        );
      },
    );

    return Stack(children: [
      content,
      Positioned(
        right: 16,
        bottom: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'toggle_trash',
              onPressed: _toggleTrashView,
              icon: Icon(_showTrash ? Icons.restore_from_trash : Icons.delete_sweep),
              label: Text(_showTrash ? 'Tampil Aktif' : 'Keranjang Sampah'),
              backgroundColor: _showTrash ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            if (!_showTrash) ...[
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                onPressed: _showCreateSheet,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
                backgroundColor: Colors.blueAccent,
                heroTag: 'create_barang',
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final Future<void> Function() onChanged;
  final bool isTrash;
  const _ProductCard({required this.row, required this.onChanged, required this.isTrash});

  Future<void> _showEdit(BuildContext context) async {
    final id = row['id'];
    final namaC = TextEditingController(text: row['nama']?.toString() ?? '');
    final deskripsiC = TextEditingController(text: row['deskripsi']?.toString() ?? '');
    final ratingC = TextEditingController(text: row['rating']?.toString() ?? '');
    final hargaC = TextEditingController(text: row['harga']?.toString() ?? '');
    final stokC = TextEditingController(text: row['stok']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  Text('Edit Barang', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ID: $id', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 16),
                  TextFormField(controller: namaC, decoration: const InputDecoration(labelText: 'Nama *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: deskripsiC, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)), maxLines: 3),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: hargaC, decoration: const InputDecoration(labelText: 'Harga *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib'; if (num.tryParse(v)==null) return 'Angka'; return null; })),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: stokC, decoration: const InputDecoration(labelText: 'Stok *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib'; if (int.tryParse(v)==null) return 'Integer'; return null; })),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: ratingC, decoration: const InputDecoration(labelText: 'Rating 0-5', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { if (v==null || v.trim().isEmpty) return null; final d=double.tryParse(v); if (d==null) return 'Angka'; if (d<0||d>5) return '0-5'; return null; }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => loading = true);
                        try {
                          final payload = {
                            'nama': namaC.text.trim(),
                            'deskripsi': deskripsiC.text.trim().isEmpty ? null : deskripsiC.text.trim(),
                            'rating': ratingC.text.trim().isEmpty ? null : double.parse(ratingC.text.trim()),
                            'harga': num.parse(hargaC.text.trim()),
                            'stok': int.parse(stokC.text.trim()),
                          }..removeWhere((k,v) => v==null);
                          await Supabase.instance.client.from('barang').update(payload).eq('id', id);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${payload['nama']} berhasil diupdate')));
                          await onChanged();
                        } catch (e) {
                          setSheet(() => loading = false);
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
                        }
                      },
                      icon: loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.save),
                      label: Text(loading ? 'Menyimpan...' : 'Update'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    namaC.dispose(); deskripsiC.dispose(); ratingC.dispose(); hargaC.dispose(); stokC.dispose();
  }

  Future<void> _softDelete(BuildContext context) async {
    final id = row['id'];
    final nama = row['nama']?.toString() ?? 'barang';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus (Soft Delete)?'),
        content: Text('Pindahkan "$nama" (ID: $id) ke keranjang sampah? Bisa dipulihkan nanti.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Pindah ke Sampah')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.from('barang').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama dipindah ke keranjang sampah')));
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final id = row['id'];
    final nama = row['nama']?.toString() ?? 'barang';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Barang?'),
        content: Text('Pulihkan "$nama" (ID: $id) kembali ke daftar aktif?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.green), child: const Text('Pulihkan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.from('barang').update({'deleted_at': null}).eq('id', id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama berhasil dipulihkan')));
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal pulihkan: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _permanentDelete(BuildContext context) async {
    final id = row['id'];
    final nama = row['nama']?.toString() ?? 'barang';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text('Yakin hapus PERMANEN "$nama" (ID: $id)? Aksi TIDAK BISA DIBATALKAN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus Permanen')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.from('barang').delete().eq('id', id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama dihapus permanen')));
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus permanen: $e'), backgroundColor: Colors.red));
    }
  }

  void _showDetail(BuildContext context) {
    final id = row['id']?.toString() ?? '-';
    final nama = row['nama']?.toString() ?? 'Tanpa nama';
    final deskripsi = row['deskripsi']?.toString() ?? '-';
    final rating = double.tryParse(row['rating']?.toString() ?? '') ?? 0;
    final harga = row['harga'];
    final stok = int.tryParse(row['stok']?.toString() ?? '') ?? 0;
    final deletedAt = row['deleted_at']?.toString();
    final hargaText = harga == null ? '-' : 'Rp ${_formatAngka(harga)}';

    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5, expand: false, builder: (context, sc) => SingleChildScrollView(controller: sc, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_placeholderImage, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: double.infinity, height: 200, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey)))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Text(nama, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
        if (deletedAt != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Text('DIHAPUS', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 4), Text('ID: $id', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      if (deletedAt != null) ...[
        const SizedBox(height: 4),
        Text('Dihapus: ${_formatTanggal(deletedAt)}', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
      ],
      const SizedBox(height: 8),
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)), child: Text('ID $id', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Text(hargaText, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 16),
      Row(children: [const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4), Text('${rating.toStringAsFixed(1)}  •  Stok $stok', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]),
      const SizedBox(height: 16),
      Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(deskripsi, style: const TextStyle(fontSize: 15, height: 1.5)),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _detailRow('ID', id), _detailRow('Nama', nama), _detailRow('Harga', hargaText), _detailRow('Rating', rating.toString()), _detailRow('Stok', stok.toString()),
        if (deletedAt != null) _detailRow('Dihapus', _formatTanggal(deletedAt)),
      ])),
      const SizedBox(height: 20),
      if (!isTrash) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _showEdit(context); }, icon: const Icon(Icons.edit, size: 18), label: const Text('Edit'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _softDelete(context); }, icon: const Icon(Icons.delete, size: 18, color: Colors.orange), label: const Text('Hapus (Soft)', style: TextStyle(color: Colors.orange)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)))),
        ]),
      ] else ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _restore(context); }, icon: const Icon(Icons.restore, size: 18, color: Colors.green), label: const Text('Pulihkan', style: TextStyle(color: Colors.green)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _permanentDelete(context); }, icon: const Icon(Icons.delete_forever, size: 18, color: Colors.red), label: const Text('Hapus Permanen', style: TextStyle(color: Colors.red)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)))),
        ]),
      ],
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama ditambahkan ke keranjang'))); }, icon: const Icon(Icons.add_shopping_cart), label: Text('Beli Sekarang - $hargaText', style: const TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]))))));
  }

  @override
  Widget build(BuildContext context) {
    final id = row['id']?.toString() ?? '-';
    final nama = row['nama']?.toString() ?? 'Tanpa nama';
    final deskripsi = row['deskripsi']?.toString() ?? '-';
    final rating = double.tryParse(row['rating']?.toString() ?? '') ?? 0;
    final harga = row['harga'];
    final stok = int.tryParse(row['stok']?.toString() ?? '') ?? 0;
    final deletedAt = row['deleted_at']?.toString();
    final hargaText = harga == null ? '-' : 'Rp ${_formatAngka(harga)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: deletedAt != null ? Colors.orange.withValues(alpha: 0.05) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_placeholderImage, width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (deletedAt != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('SAMPAH', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold))),
                  ]),
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
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (!isTrash) ...[
                  TextButton.icon(onPressed: () => _showEdit(context), icon: const Icon(Icons.edit, size: 16), label: const Text('Edit'), style: TextButton.styleFrom(foregroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 8))),
                  const SizedBox(width: 4),
                  TextButton.icon(onPressed: () => _softDelete(context), icon: const Icon(Icons.delete, size: 16), label: const Text('Hapus'), style: TextButton.styleFrom(foregroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 8))),
                ] else ...[
                  TextButton.icon(onPressed: () => _restore(context), icon: const Icon(Icons.restore, size: 16), label: const Text('Pulihkan'), style: TextButton.styleFrom(foregroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 8))),
                  const SizedBox(width: 4),
                  TextButton.icon(onPressed: () => _permanentDelete(context), icon: const Icon(Icons.delete_forever, size: 16), label: const Text('Hapus Permanen'), style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8))),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
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

String _formatTanggal(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}