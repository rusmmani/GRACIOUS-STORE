# GRACIOUS Store — Static Vercel + Supabase

## Perubahan versi ini

- Checkout punya pilihan **JNE, J&T Express, SiCepat, POS Indonesia**.
- Berat otomatis **190 gram / baju** dan dikalikan jumlah item.
- Tarif ongkir dihitung live berdasarkan **origin + destination + courier + service + berat** melalui RajaOngkir Shipping Cost API.
- Customer mencari tujuan berdasarkan kota/kecamatan/kode pos sehingga destination ID yang dipakai untuk tarif tidak lagi sekadar teks.
- Admin dapat mengatur **Origin Destination ID**, label origin, dan berat default per baju.
- Tracking customer memakai **nomor resi + nama pembeli + kurir**.
- Homepage campaign memakai 6 foto yang kamu kirim sebagai slideshow.
- Teks **THE NEW PRE-ORDER** di campaign dihapus; **MORE TEXTURE. MORE CHARACTER.** tetap.
- Foto terakhir yang kamu kirim dipakai sebagai `size-chart.png`.

## Shipping API

API key RajaOngkir **jangan diletakkan di frontend**. Function di `supabase/functions/shipping/index.ts` menjadi proxy server-side.

### 1. Jalankan SQL

Supabase → SQL Editor → jalankan:

`supabase/schema.sql`

Setelah user admin dibuat, set role admin:

```sql
update public.profiles
set role='admin'
where id='UUID_USER_AUTH';
```

### 2. Pasang RajaOngkir API key sebagai Secret

Dengan Supabase CLI:

```bash
supabase secrets set RAJAONGKIR_API_KEY=YOUR_SHIPPING_COST_API_KEY
supabase functions deploy shipping --no-verify-jwt
```

Frontend sudah mengarah ke:

`https://dlkdtmdmauqvbumhyqsu.supabase.co/functions/v1/shipping`

Kalau project Supabase berbeda, ubah `shippingFunctionUrl` di `store/assets/config.js`.

### 3. Atur origin

Admin → Settings → Shipping:

- **Origin Destination ID**: ID lokasi asal GRACIOUS dari RajaOngkir.
- **Origin Label**: misalnya `GRACIOUS — Indramayu`.
- **Berat per baju**: `190`.
- **Shipping API**: aktif.

### 4. Tracking

Admin memasukkan nomor resi pada detail order. Customer membuka `store/tracking.html`, memilih kurir, lalu mengisi resi + nama pembeli.

RajaOngkir Shipping Cost saat ini mencantumkan tracking AWB untuk JNE, J&T Express, dan POS Indonesia, sedangkan SiCepat tercantum untuk perhitungan tarif tetapi tidak untuk AWB tracking pada daftar courier availability. Karena itu halaman tracking menyediakan fallback ke halaman tracking resmi SiCepat.

### 5. Deploy

Upload folder ini ke GitHub → import ke Vercel sebagai static site. Tidak membutuhkan build command.
