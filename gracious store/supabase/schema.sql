-- GRACIOUS STORE — Supabase schema V3
-- Run this whole file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check(role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.categories(
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products(
  id text primary key,
  name text not null,
  price integer not null check(price>=0),
  category_id uuid references public.categories(id) on delete set null,
  description text not null default '',
  short_description text not null default '',
  material text not null default 'Matt Cotton 24s',
  printing text not null default 'Plastisol Screen Printing',
  sizes text[] not null default ARRAY['S','M','L','XL'],
  stock_by_size jsonb not null default '{"S":10,"M":10,"L":10,"XL":10}'::jsonb,
  image_urls text[] not null default ARRAY[]::text[],
  order_mode text not null default 'preorder' check(order_mode in ('order','preorder')),
  badge text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Backfill columns when upgrading an older GRACIOUS database.
alter table public.products add column if not exists category_id uuid references public.categories(id) on delete set null;
alter table public.products add column if not exists description text not null default '';
alter table public.products add column if not exists short_description text not null default '';
alter table public.products add column if not exists material text not null default 'Matt Cotton 24s';
alter table public.products add column if not exists printing text not null default 'Plastisol Screen Printing';
alter table public.products add column if not exists sizes text[] not null default ARRAY['S','M','L','XL'];
alter table public.products add column if not exists stock_by_size jsonb not null default '{"S":10,"M":10,"L":10,"XL":10}'::jsonb;
alter table public.products add column if not exists image_urls text[] not null default ARRAY[]::text[];
alter table public.products add column if not exists order_mode text not null default 'preorder';
alter table public.products add column if not exists badge text not null default '';
alter table public.products add column if not exists updated_at timestamptz not null default now();

create table if not exists public.promos(
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  type text not null check(type in ('percent','fixed')),
  value numeric not null check(value>0),
  quantity integer null check(quantity is null or quantity>=0),
  used_count integer not null default 0,
  min_subtotal integer not null default 0,
  max_discount integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_methods(
  id uuid primary key default gen_random_uuid(),
  method_type text not null check(method_type in ('bank','qris','ewallet')),
  name text not null,
  account_number text,
  account_name text,
  qr_image_url text,
  instructions text,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders(
  id uuid primary key default gen_random_uuid(),
  order_code text unique not null,
  customer_name text not null,
  customer_phone text not null,
  customer_email text,
  address text not null,
  city text not null,
  province text not null,
  postal_code text not null,
  notes text,
  promo_code text,
  payment_method text,
  subtotal integer not null,
  shipping integer not null default 15000,
  discount integer not null default 0,
  total integer not null,
  status text not null default 'pending' check(status in ('pending','confirmed','shipped','completed','cancelled')),
  tracking_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.orders add column if not exists payment_method text;

create table if not exists public.order_items(
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text not null references public.products(id),
  product_name text not null,
  unit_price integer not null,
  size text not null,
  quantity integer not null check(quantity>0)
);

create table if not exists public.site_settings(
  id boolean primary key default true,
  order_mode text not null default 'preorder' check(order_mode in ('order','preorder')),
  updated_at timestamptz not null default now(),
  constraint site_settings_singleton check(id=true)
);
insert into public.site_settings(id,order_mode) values(true,'preorder') on conflict(id) do nothing;

create index if not exists orders_created_idx on public.orders(created_at desc);
-- Do not index date_trunc('month', created_at) on timestamptz: date_trunc(text,timestamptz) is timezone-dependent and not IMMUTABLE.
-- The created_at index above supports month/date filtering safely.
create index if not exists orders_code_idx on public.orders(order_code);
create index if not exists order_items_order_idx on public.order_items(order_id);
create index if not exists products_category_idx on public.products(category_id);
create index if not exists products_active_idx on public.products(active);
create index if not exists payment_methods_active_idx on public.payment_methods(active,sort_order);


-- Admin profile + store profile (editable from Admin > Settings)
alter table public.profiles add column if not exists full_name text not null default '';
alter table public.profiles add column if not exists avatar_url text;

create table if not exists public.store_profile(
  id boolean primary key default true,
  store_name text not null default 'GRACIOUS',
  tagline text not null default 'Premium Graphic Essentials',
  description text not null default '',
  logo_url text,
  email text,
  phone text,
  whatsapp text,
  instagram text,
  address text,
  updated_at timestamptz not null default now(),
  constraint store_profile_singleton check(id=true)
);
insert into public.store_profile(id,store_name,tagline) values(true,'GRACIOUS','Premium Graphic Essentials') on conflict(id) do nothing;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.promos enable row level security;
alter table public.payment_methods enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.site_settings enable row level security;
alter table public.store_profile enable row level security;

create or replace function public.is_admin() returns boolean language sql security definer set search_path=public stable as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

-- Public catalog/settings/payment policies
 drop policy if exists categories_public_select on public.categories;
create policy categories_public_select on public.categories for select to anon,authenticated using(active=true);
drop policy if exists categories_admin_all on public.categories;
create policy categories_admin_all on public.categories for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists products_public_select on public.products;
create policy products_public_select on public.products for select to anon,authenticated using(active=true);
drop policy if exists products_admin_all on public.products;
create policy products_admin_all on public.products for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists promos_public_select on public.promos;
create policy promos_public_select on public.promos for select to anon,authenticated using(active=true and (quantity is null or quantity>0));
drop policy if exists promos_admin_all on public.promos;
create policy promos_admin_all on public.promos for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists payment_methods_public_select on public.payment_methods;
create policy payment_methods_public_select on public.payment_methods for select to anon,authenticated using(active=true);
drop policy if exists payment_methods_admin_all on public.payment_methods;
create policy payment_methods_admin_all on public.payment_methods for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists site_settings_public_select on public.site_settings;
create policy site_settings_public_select on public.site_settings for select to anon,authenticated using(true);
drop policy if exists site_settings_admin_all on public.site_settings;
create policy site_settings_admin_all on public.site_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists store_profile_public_select on public.store_profile;
create policy store_profile_public_select on public.store_profile for select to anon,authenticated using(true);
drop policy if exists store_profile_admin_all on public.store_profile;
create policy store_profile_admin_all on public.store_profile for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Orders/admin policies
drop policy if exists orders_public_select on public.orders;
create policy orders_public_select on public.orders for select to anon using(false);
drop policy if exists orders_admin_all on public.orders;
create policy orders_admin_all on public.orders for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists order_items_admin_all on public.order_items;
create policy order_items_admin_all on public.order_items for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select to authenticated using(id=auth.uid());
drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles for all to authenticated using(public.is_admin()) with check(public.is_admin());

grant select on public.categories, public.products, public.promos, public.payment_methods, public.site_settings to anon,authenticated;
grant insert,update,delete on public.categories, public.products, public.promos, public.payment_methods to authenticated;
grant select,insert,update,delete on public.orders, public.order_items to authenticated;
grant select,insert,update,delete on public.profiles to authenticated;
grant select,update on public.site_settings to authenticated;
grant select on public.store_profile to anon,authenticated;
grant select,insert,update,delete on public.store_profile to authenticated;

-- Storage buckets for admin uploads. Public read; admin-only writes.
insert into storage.buckets(id,name,public) values
('product-images','product-images',true),
('payment-assets','payment-assets',true),
('store-assets','store-assets',true)
on conflict(id) do update set public=true;

drop policy if exists gracious_product_upload on storage.objects;
create policy gracious_product_upload on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.is_admin());
drop policy if exists gracious_product_update on storage.objects;
create policy gracious_product_update on storage.objects for update to authenticated using(bucket_id='product-images' and public.is_admin()) with check(bucket_id='product-images' and public.is_admin());
drop policy if exists gracious_product_delete on storage.objects;
create policy gracious_product_delete on storage.objects for delete to authenticated using(bucket_id='product-images' and public.is_admin());
drop policy if exists gracious_product_select on storage.objects;
create policy gracious_product_select on storage.objects for select to public using(bucket_id='product-images');

drop policy if exists gracious_store_upload on storage.objects;
create policy gracious_store_upload on storage.objects for insert to authenticated with check(bucket_id='store-assets' and public.is_admin());
drop policy if exists gracious_store_update on storage.objects;
create policy gracious_store_update on storage.objects for update to authenticated using(bucket_id='store-assets' and public.is_admin()) with check(bucket_id='store-assets' and public.is_admin());
drop policy if exists gracious_store_delete on storage.objects;
create policy gracious_store_delete on storage.objects for delete to authenticated using(bucket_id='store-assets' and public.is_admin());
drop policy if exists gracious_store_select on storage.objects;
create policy gracious_store_select on storage.objects for select to public using(bucket_id='store-assets');

drop policy if exists gracious_payment_upload on storage.objects;
create policy gracious_payment_upload on storage.objects for insert to authenticated with check(bucket_id='payment-assets' and public.is_admin());
drop policy if exists gracious_payment_update on storage.objects;
create policy gracious_payment_update on storage.objects for update to authenticated using(bucket_id='payment-assets' and public.is_admin()) with check(bucket_id='payment-assets' and public.is_admin());
drop policy if exists gracious_payment_delete on storage.objects;
create policy gracious_payment_delete on storage.objects for delete to authenticated using(bucket_id='payment-assets' and public.is_admin());
drop policy if exists gracious_payment_select on storage.objects;
create policy gracious_payment_select on storage.objects for select to public using(bucket_id='payment-assets');

-- Order creation RPC. Payment method is stored with the order.
drop function if exists public.place_order(text,text,text,text,text,text,text,text,text,jsonb);
drop function if exists public.place_order(text,text,text,text,text,text,text,text,text,text,jsonb);
create or replace function public.place_order(customer_name text, customer_phone text, customer_email text, address text, city text, province text, postal_code text, notes text, promo_code text, payment_method text, items jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  it jsonb; p public.products%rowtype; sub integer:=0; ship integer:=15000; disc integer:=0; total integer; code text; oid uuid; pr public.promos%rowtype; q integer; chosen_size text;
begin
  if jsonb_array_length(items)=0 then raise exception 'Keranjang kosong'; end if;
  for it in select * from jsonb_array_elements(items) loop
    select * into p from public.products where id=it->>'product_id' and active=true for update;
    if not found then raise exception 'Produk tidak tersedia: %',it->>'product_id'; end if;
    q:=coalesce((it->>'quantity')::int,0); if q<1 then raise exception 'Quantity tidak valid'; end if;
    chosen_size:=upper(trim(it->>'size'));
    if not (chosen_size=any(p.sizes)) then raise exception 'Size tidak tersedia untuk produk %',p.name; end if;
    if coalesce((p.stock_by_size->>chosen_size)::int,0) < q then raise exception 'Stock % size % tidak cukup untuk %', coalesce(p.stock_by_size->>chosen_size,'0'), chosen_size, p.name; end if;
    sub:=sub+(p.price*q);
    update public.products set stock_by_size=jsonb_set(stock_by_size, array[chosen_size], to_jsonb(greatest(coalesce((stock_by_size->>chosen_size)::int,0)-q,0)), true), updated_at=now() where id=p.id;
  end loop;
  if nullif(trim(promo_code),'') is not null then
    select * into pr from public.promos where upper(code)=upper(trim(promo_code)) and active=true for update;
    if not found then raise exception 'Kode promo tidak tersedia'; end if;
    if pr.quantity is not null and pr.quantity<=pr.used_count then raise exception 'Kuota promo habis'; end if;
    if sub<pr.min_subtotal then raise exception 'Minimum belanja untuk promo belum tercapai'; end if;
    if pr.type='percent' then
      disc:=round(sub*pr.value/100);
      if pr.max_discount>0 then disc:=least(disc,pr.max_discount); end if;
    else disc:=least(pr.value::int,sub); end if;
  end if;
  total:=greatest(sub+ship-disc,0);
  code:='GR-'||to_char(now(),'YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
  insert into public.orders(order_code,customer_name,customer_phone,customer_email,address,city,province,postal_code,notes,promo_code,payment_method,subtotal,shipping,discount,total)
  values(code,customer_name,customer_phone,customer_email,address,city,province,postal_code,notes,nullif(trim(promo_code),''),nullif(trim(payment_method),''),sub,ship,disc,total) returning id into oid;
  for it in select * from jsonb_array_elements(items) loop
    select * into p from public.products where id=it->>'product_id';
    insert into public.order_items(order_id,product_id,product_name,unit_price,size,quantity)
    values(oid,p.id,p.name,p.price,upper(trim(it->>'size')),(it->>'quantity')::int);
  end loop;
  if nullif(trim(promo_code),'') is not null then
    update public.promos set used_count=used_count+1,quantity=case when quantity is null then null else greatest(quantity-1,0) end where id=pr.id;
  end if;
  return jsonb_build_object('order_code',code,'order_id',oid,'subtotal',sub,'shipping',ship,'discount',disc,'total',total,'payment_method',payment_method);
end;$$;

grant execute on function public.place_order(text,text,text,text,text,text,text,text,text,text,jsonb) to anon,authenticated;

create or replace function public.get_order_tracking(p_order_code text)
returns jsonb language sql security definer set search_path=public as $$
  select coalesce(jsonb_build_object('order_code',o.order_code,'status',o.status,'tracking_number',o.tracking_number,'created_at',o.created_at,'total',o.total,'payment_method',o.payment_method,'items',coalesce((select jsonb_agg(jsonb_build_object('product_name',oi.product_name,'size',oi.size,'quantity',oi.quantity)) from public.order_items oi where oi.order_id=o.id),'[]'::jsonb)),'null'::jsonb)
  from public.orders o where upper(o.order_code)=upper(trim(p_order_code));
$$;
grant execute on function public.get_order_tracking(text) to anon,authenticated;

-- Initial categories and products. Existing local assets remain as fallback images.
insert into public.categories(name,slug,description) values
('New Drop','new-drop','Latest GRACIOUS releases.'),
('Essentials','essentials','Core pieces for everyday rotation.')
on conflict(slug) do nothing;

insert into public.products(id,name,price,category_id,description,short_description,material,printing,sizes,stock_by_size,image_urls,order_mode,badge)
values
('entangled-nightmares','Entangled Nightmares Tee',145000,(select id from public.categories where slug='new-drop'),'Dibuat untuk mereka yang ingin graphic tee terasa lebih refined. Matt Cotton 24s memberi karakter kain yang solid namun tetap nyaman, sementara Plastisol Screen Printing menghasilkan artwork yang tajam, padat, dan punya depth visual yang terasa premium. Siluetnya clean, jatuh dengan rapi, dan mudah dipakai sebagai statement piece sehari-hari.','Graphic tee dengan artwork gelap yang kuat, material premium, dan finishing print yang clean.','Matt Cotton 24s','Plastisol Screen Printing',ARRAY['S','M','L','XL'],'{"S":10,"M":10,"L":10,"XL":10}'::jsonb,ARRAY['assets/products/entangled-1.jpg','assets/products/entangled-2.jpg','assets/products/entangled-3.jpg','assets/products/entangled-4.jpg'],'preorder','Pre-Order'),
('the-doppelganger','The Doppelgänger Tee',145000,(select id from public.categories where slug='new-drop'),'The Doppelgänger memadukan karakter artwork yang editorial dengan feel kaos premium yang understated. Menggunakan Matt Cotton 24s yang terasa lembut namun tetap berstruktur, dipadukan dengan Plastisol Screen Printing untuk detail grafis yang tegas dan durable. Hasil akhirnya clean, substantial, dan tetap nyaman untuk dipakai sepanjang hari.','Editorial graphic tee dengan hand-feel premium dan print yang bold namun refined.','Matt Cotton 24s','Plastisol Screen Printing',ARRAY['S','M','L','XL'],'{"S":10,"M":10,"L":10,"XL":10}'::jsonb,ARRAY['assets/products/doppelganger-1.jpg','assets/products/doppelganger-2.jpg','assets/products/doppelganger-3.jpg'],'preorder','Pre-Order'),
('dark-vitruvian','Dark Vitruvian Tee',145000,(select id from public.categories where slug='new-drop'),'Dark Vitruvian menghadirkan graphic yang ikonik dengan pendekatan modern dan clean. Matt Cotton 24s memberikan body kain yang premium, breathable, dan tetap nyaman, sedangkan Plastisol Screen Printing menjaga artwork tetap crisp dengan tekstur print yang terasa eksklusif. Dibuat untuk menjadi everyday tee yang punya presence.','Ikonik, dark, dan clean — premium everyday tee dengan graphic statement.','Matt Cotton 24s','Plastisol Screen Printing',ARRAY['S','M','L','XL'],'{"S":10,"M":10,"L":10,"XL":10}'::jsonb,ARRAY['assets/products/dark-vitruvian-1.jpg','assets/products/dark-vitruvian-2.jpg','assets/products/dark-vitruvian-3.jpg'],'preorder','Pre-Order'),
('gracious-white','GRACIOUS White Graphic Tee',145000,(select id from public.categories where slug='essentials'),'Essential graphic tee dengan pendekatan clean dan versatile. Matt Cotton 24s menghadirkan body kain yang nyaman dan berstruktur, dipadukan dengan Plastisol Screen Printing untuk hasil graphic yang tajam dan premium.','Clean essential tee untuk daily rotation.','Matt Cotton 24s','Plastisol Screen Printing',ARRAY['S','M','L','XL'],'{"S":10,"M":10,"L":10,"XL":10}'::jsonb,ARRAY['assets/products/entangled-1.jpg'],'order','Essential')
on conflict(id) do update set name=excluded.name,price=excluded.price,category_id=excluded.category_id,description=excluded.description,short_description=excluded.short_description,material=excluded.material,printing=excluded.printing,sizes=excluded.sizes,stock_by_size=excluded.stock_by_size,image_urls=excluded.image_urls,order_mode=excluded.order_mode,badge=excluded.badge,updated_at=now();

insert into public.promos(code,type,value,quantity,min_subtotal,max_discount,active)
values('WELCOME10','percent',10,50,145000,30000,true)
on conflict(code) do nothing;

-- AFTER creating your Supabase Auth admin user, replace ADMIN_UUID below and run:
-- insert into public.profiles(id,role) values('ADMIN_UUID','admin') on conflict(id) do update set role='admin';
