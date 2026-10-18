# f_04_database

Aplikasi Flutter ini membaca dan menampilkan semua baris dari tabel `produk`
di Supabase. Daftar dapat dimuat ulang dengan menarik layar ke bawah atau
menekan tombol muat ulang.

## Menjalankan aplikasi

```sh
flutter pub get
flutter run
```

Konfigurasi URL proyek dan publishable key tersedia di `lib/main.dart`.
Publishable key memang digunakan di aplikasi klien; jangan pernah memasukkan
secret key atau service-role key ke aplikasi mobile.

Pastikan tabel `produk` dapat dibaca oleh role `anon` melalui kebijakan Row
Level Security (RLS) Supabase. Jika tidak, aplikasi akan menampilkan pesan
kesalahan dari Supabase.
