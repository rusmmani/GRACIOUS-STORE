# GRACIOUS STORE — Supabase Admin + Storage

## Yang sudah tersedia
- Admin dashboard login Supabase Auth.
- Upload foto produk langsung dari Admin ke Supabase Storage bucket `product-images`.
- Preview foto produk sebelum disimpan.
- Foto yang sudah disimpan otomatis masuk ke `products.image_urls` dan tampil di Store.
- Upload QR/payment image ke bucket `payment-assets`.
- **Settings** di Admin untuk mengubah:
  - nama admin
  - foto profil admin
  - nama store
  - tagline
  - deskripsi
  - logo store
  - email, telepon, WhatsApp, Instagram, alamat
- Logo/nama store dari database otomatis dipakai di Store.
- Store tetap memiliki pilihan bahasa ID/EN dan mata uang IDR/USD.

## Instal / Setup Supabase

### 1. Buat project Supabase
Buka Supabase dan buat project baru.

### 2. Jalankan SQL
Masuk ke:
`Supabase Dashboard → SQL Editor → New query`

Copy seluruh isi:
`supabase/schema.sql`

lalu klik **Run**.

SQL ini akan membuat/memperbarui:
- tabel products, categories, orders, payments, site settings
- tabel `store_profile`
- field profil admin `full_name` dan `avatar_url`
- RLS/policy
- Storage bucket:
  - `product-images`
  - `payment-assets`
  - `store-assets`

> Jika database lama sudah dipakai, SQL ini menggunakan `IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS` pada bagian upgrade yang relevan. Jangan menghapus tabel lama.

### 3. Buat user admin
Masuk:
`Supabase Dashboard → Authentication → Users → Add user`

Buat email + password admin.

Salin **User UID** admin tersebut.

Di SQL Editor jalankan:

```sql
insert into public.profiles(id, role, full_name)
values('USER_UID_ANDA', 'admin', 'Nama Admin')
on conflict(id) do update set role='admin';
```

Ganti `USER_UID_ANDA` dengan UID user Supabase.

### 4. Isi konfigurasi frontend
Buka:
- `admin/assets/config.js`
- `store/assets/config.js`

Isi:

```js
window.GRACIOUS_CONFIG = {
  supabaseUrl: 'https://PROJECT_ID.supabase.co',
  supabaseAnonKey: 'SUPABASE_ANON_KEY'
};
```

Gunakan **anon/publishable key**, jangan pernah memasukkan `service_role` key ke HTML/JS.

### 5. Login Admin
Buka:
`admin/login.html`

Login dengan akun Supabase yang sudah diberi role `admin`.

### 6. Upload produk
Di Admin:
`Catalog → + PRODUCT`

Isi data produk → pilih **Upload Gambar Produk** → gambar langsung muncul sebagai preview → klik **SAVE PRODUCT**.

Alurnya:

`Browser → Supabase Storage/product-images → Public URL → products.image_urls → Store`

### 7. Ubah profil admin
Di:
`Settings → Admin Profile`

Bisa mengubah nama dan foto profil. Foto masuk ke:
`store-assets/admin/USER_ID/...`

### 8. Ubah profil store
Di:
`Settings → Store Profile`

Bisa mengubah nama, tagline, deskripsi, logo, kontak dan alamat. Logo masuk ke:
`store-assets/store/...`

Setelah disimpan, Store akan membaca profil tersebut langsung dari Supabase.

## Deploy Vercel

Struktur yang bisa dideploy:

```text
store/
admin/
supabase/
README.md
```

Jika ingin URL terpisah:
- Store → deploy folder `store`
- Admin → deploy folder `admin`

Jika menggunakan satu project Vercel, root dapat berisi keduanya dan URL bisa diarahkan ke `/store` dan `/admin`.

## Penting tentang Storage

Bucket gambar dibuat **public untuk read**, tetapi upload/update/delete hanya boleh dilakukan oleh user yang memiliki `profiles.role = 'admin'`.

Jadi customer/store tidak dapat upload gambar lewat frontend.


## Supabase credentials
The provided Supabase project URL and publishable key are embedded directly in the admin/store JavaScript. No service_role key is used.
