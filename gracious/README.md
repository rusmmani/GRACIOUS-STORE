# GRACIOUS Store — Supabase V3

## What was added

### Admin Catalog
- Add/edit products from dashboard.
- Product name, price, category, premium description, short description.
- Material and printing fields.
- Custom sizes per product.
- Product-level ORDER / PRE-ORDER.
- Product badge and active/inactive switch.
- Multiple product image uploads through Supabase Storage.
- Existing image URLs can also be kept/added.
- Add and activate/deactivate categories.

### Payment Control
Admin can add:
- Bank transfer
- QRIS + QR image upload
- E-wallet
- Account / wallet number
- Account holder
- Instructions
- Display order
- ON/OFF

Active payment methods appear at checkout. The selected payment method is saved on the order.

### Orders
- Orders grouped by month.
- Status update + tracking number.
- WhatsApp order message.
- Completed-order WhatsApp message.

### Store
- Product catalog is read dynamically from Supabase.
- Product detail uses the admin's images, description, sizes, price and product mode.
- Categories are dynamic.
- Checkout displays active payment methods.

## Supabase setup

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Run the complete `supabase/schema.sql` file.
4. Create an admin user under **Authentication → Users**.
5. Put the user's UUID into:

```sql
insert into public.profiles(id,role)
values('ADMIN_UUID','admin')
on conflict(id) do update set role='admin';
```

6. Put the Supabase Project URL and publishable/anon key in both:
- `store/assets/config.js`
- `admin/assets/config.js`

Use the browser-safe publishable/anon key. Never put a Supabase service-role key in these files.

## Supabase Storage

The SQL creates two public buckets automatically:
- `product-images`
- `payment-assets`

Only authenticated admin users can upload/update/delete. Public users can read the public files.

## Vercel

Deploy `store/` as the customer website and `admin/` as the admin project. If using one Git repository, create two Vercel projects and set Root Directory to the corresponding folder.

## Important upgrade note

This V3 schema adds catalog, category, payment and product image fields. Run the full SQL file before using the new Admin Catalog or Payment pages.


## Supabase configuration
The V4 Fixed package is preconfigured for the supplied Supabase project in:
- `store/assets/config.js`
- `admin/assets/config.js`

The browser uses the Supabase publishable key. Keep any Supabase secret/service-role key out of browser code.
