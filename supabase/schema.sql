create extension if not exists "uuid-ossp";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, avatar_url text,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.profiles(id,full_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict(id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.store_profile (
  id boolean primary key default true, store_name text not null default 'GRACIOUS',
  tagline text not null default 'Premium Graphic Essentials', description text default '',
  logo_url text, email text, phone text, whatsapp text, instagram text, address text,
  updated_at timestamptz not null default now(), constraint store_profile_singleton check (id=true)
);
create table if not exists public.site_settings (
  id boolean primary key default true,
  order_mode text not null default 'preorder' check (order_mode in ('order','preorder')),
  shipping_origin_id integer, shipping_origin_label text,
  shirt_weight_grams integer not null default 190,
  shipping_api_enabled boolean not null default true,
  updated_at timestamptz not null default now(), constraint site_settings_singleton check (id=true)
);
create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(), name text not null, slug text unique not null,
  description text default '', active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.products (
  id text primary key, name text not null, price integer not null default 0,
  category_id uuid references public.categories(id) on delete set null, description text default '',
  short_description text default '', material text, printing text,
  sizes text[] not null default array['S','M','L','XL'], stock_by_size jsonb not null default '{}'::jsonb,
  order_mode text not null default 'preorder' check (order_mode in ('order','preorder')),
  colors jsonb not null default '[]'::jsonb,
  badge text, active boolean not null default true, image_urls text[] not null default '{}',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.payment_methods (
  id uuid primary key default uuid_generate_v4(), method_type text not null check (method_type in ('bank','qris','ewallet')),
  name text not null, account_number text, account_name text, qr_image_url text, instructions text,
  sort_order integer not null default 0, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.promos (
  id uuid primary key default uuid_generate_v4(), code text unique not null,
  type text not null check (type in ('percent','fixed')), value integer not null,
  quantity integer, used_count integer not null default 0, min_subtotal integer not null default 0,
  max_discount integer not null default 50000, active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default uuid_generate_v4(), order_code text unique not null,
  customer_name text not null, customer_phone text not null, customer_email text,
  address text not null, city text not null, province text not null, postal_code text not null, notes text,
  promo_code text, payment_method text, payment_proof_url text,
  subtotal integer not null default 0, discount integer not null default 0, shipping_cost integer not null default 0, total integer not null default 0,
  shipping_courier_code text, shipping_courier_name text, shipping_service text, shipping_etd text,
  shipping_weight_grams integer not null default 190, shipping_origin_id integer, shipping_origin_label text,
  shipping_destination_id integer, shipping_destination_label text, tracking_number text,
  status text not null default 'pending' check (status in ('pending','confirmed','shipped','completed','cancelled')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default uuid_generate_v4(), order_id uuid not null references public.orders(id) on delete cascade,
  product_id text, product_name text not null, size text not null, color text, quantity integer not null check(quantity>0),
  unit_price integer not null default 0, created_at timestamptz not null default now()
);

alter table public.site_settings add column if not exists shipping_origin_id integer;
alter table public.site_settings add column if not exists shipping_origin_label text;
alter table public.site_settings add column if not exists shirt_weight_grams integer not null default 190;
alter table public.site_settings add column if not exists shipping_api_enabled boolean not null default true;
alter table public.products add column if not exists colors jsonb not null default '[]'::jsonb;
alter table public.order_items add column if not exists color text;
alter table public.orders add column if not exists shipping_courier_code text;
alter table public.orders add column if not exists shipping_courier_name text;
alter table public.orders add column if not exists shipping_service text;
alter table public.orders add column if not exists shipping_etd text;
alter table public.orders add column if not exists shipping_weight_grams integer not null default 190;
alter table public.orders add column if not exists shipping_origin_id integer;
alter table public.orders add column if not exists shipping_origin_label text;
alter table public.orders add column if not exists shipping_destination_id integer;
alter table public.orders add column if not exists shipping_destination_label text;
alter table public.orders add column if not exists shipping_cost integer not null default 0;

insert into public.store_profile(id,store_name,tagline) values(true,'GRACIOUS','Premium Graphic Essentials') on conflict(id) do nothing;
insert into public.site_settings(id,order_mode,shirt_weight_grams,shipping_api_enabled) values(true,'preorder',190,true) on conflict(id) do nothing;
insert into public.categories(name,slug,description) values
('New Drop','new-drop','Latest GRACIOUS releases'),('Essentials','essentials','Everyday GRACIOUS essentials')
on conflict(slug) do nothing;

alter table public.profiles enable row level security;
alter table public.store_profile enable row level security;
alter table public.site_settings enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.payment_methods enable row level security;
alter table public.promos enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "public read store profile" on public.store_profile;
create policy "public read store profile" on public.store_profile for select using(true);
drop policy if exists "public read site settings" on public.site_settings;
create policy "public read site settings" on public.site_settings for select using(true);
drop policy if exists "public read categories" on public.categories;
create policy "public read categories" on public.categories for select using(active=true);
drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products for select using(active=true);
drop policy if exists "public read active payments" on public.payment_methods;
create policy "public read active payments" on public.payment_methods for select using(active=true);
drop policy if exists "public read active promos" on public.promos;
create policy "public read active promos" on public.promos for select using(active=true);

drop policy if exists "admin manage profiles" on public.profiles;
create policy "admin manage profiles" on public.profiles for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage store profile" on public.store_profile;
create policy "admin manage store profile" on public.store_profile for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage site settings" on public.site_settings;
create policy "admin manage site settings" on public.site_settings for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage categories" on public.categories;
create policy "admin manage categories" on public.categories for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage products" on public.products;
create policy "admin manage products" on public.products for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage payments" on public.payment_methods;
create policy "admin manage payments" on public.payment_methods for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage promos" on public.promos;
create policy "admin manage promos" on public.promos for all to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin read orders" on public.orders;
create policy "admin read orders" on public.orders for select to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders for update to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin delete orders" on public.orders;
create policy "admin delete orders" on public.orders for delete to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin read order items" on public.order_items;
create policy "admin read order items" on public.order_items for select to authenticated
using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

insert into storage.buckets(id,name,public) values
('payment-proofs','payment-proofs',true),('product-images','product-images',true),('store-assets','store-assets',true)
on conflict(id) do nothing;
drop policy if exists "public read payment proofs" on storage.objects;
create policy "public read payment proofs" on storage.objects for select using(bucket_id='payment-proofs');
drop policy if exists "anon upload payment proofs" on storage.objects;
create policy "anon upload payment proofs" on storage.objects for insert to anon,authenticated with check(bucket_id='payment-proofs');
drop policy if exists "admin manage product images" on storage.objects;
create policy "admin manage product images" on storage.objects for all to authenticated
using(bucket_id='product-images' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(bucket_id='product-images' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "admin manage store assets" on storage.objects;
create policy "admin manage store assets" on storage.objects for all to authenticated
using(bucket_id='store-assets' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(bucket_id='store-assets' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

create or replace function public.place_order(
  customer_name text, customer_phone text, customer_email text, address text, city text, province text, postal_code text,
  notes text, promo_code text, payment_method text, payment_proof_url text, items jsonb,
  shipping_courier_code text default null, shipping_courier_name text default null, shipping_service text default null,
  shipping_cost integer default 0, shipping_etd text default null, shipping_weight_grams integer default 190,
  shipping_origin_id integer default null, shipping_origin_label text default null,
  shipping_destination_id integer default null, shipping_destination_label text default null
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_order_id uuid; v_order_code text; v_subtotal integer:=0; v_discount integer:=0; v_total integer:=0;
  v_item jsonb; v_product public.products%rowtype; v_qty integer; v_size text; v_color text; v_stock integer; v_promo public.promos%rowtype;
begin
  if jsonb_typeof(items)<>'array' or jsonb_array_length(items)=0 then raise exception 'Cart kosong.'; end if;
  for v_item in select * from jsonb_array_elements(items) loop
    select * into v_product from public.products where id=(v_item->>'product_id') and active=true for update;
    if not found then raise exception 'Produk tidak tersedia: %',v_item->>'product_id'; end if;
    v_qty:=greatest(1,coalesce((v_item->>'quantity')::integer,1)); v_size:=upper(trim(v_item->>'size')); v_color:=nullif(trim(v_item->>'color'),'');
    if not(v_size=any(v_product.sizes)) then raise exception 'Size % tidak tersedia untuk %.',v_size,v_product.name; end if;
    if jsonb_typeof(coalesce(v_product.colors,'[]'::jsonb))='array' and jsonb_array_length(coalesce(v_product.colors,'[]'::jsonb))>0 and not exists (select 1 from jsonb_array_elements(coalesce(v_product.colors,'[]'::jsonb)) c where lower(trim(c->>'name'))=lower(coalesce(v_color,''))) then raise exception 'Warna % tidak tersedia untuk %.',coalesce(v_color,'-'),v_product.name; end if;
    v_stock:=coalesce((v_product.stock_by_size->>v_size)::integer,0);
    if v_stock<v_qty then raise exception 'Stock % size % tidak mencukupi.',v_product.name,v_size; end if;
    v_subtotal:=v_subtotal+v_product.price*v_qty;
  end loop;
  if promo_code is not null and trim(promo_code)<>'' then
    select * into v_promo from public.promos where code=upper(trim(promo_code)) and active=true for update;
    if not found then raise exception 'Promo tidak tersedia.'; end if;
    if v_promo.quantity is not null and v_promo.used_count>=v_promo.quantity then raise exception 'Kuota promo habis.'; end if;
    if v_subtotal<v_promo.min_subtotal then raise exception 'Minimum belanja promo belum terpenuhi.'; end if;
    if v_promo.type='percent' then v_discount:=least(round(v_subtotal*v_promo.value/100.0)::integer,coalesce(nullif(v_promo.max_discount,0),2147483647));
    else v_discount:=least(v_promo.value,v_subtotal); end if;
    update public.promos set used_count=used_count+1 where id=v_promo.id;
  end if;
  v_total:=greatest(0,v_subtotal-v_discount+greatest(0,shipping_cost));
  v_order_code:='GR-'||to_char(now(),'YYYYMMDD')||'-'||upper(substr(md5(gen_random_uuid()::text),1,4));
  insert into public.orders(order_code,customer_name,customer_phone,customer_email,address,city,province,postal_code,notes,promo_code,payment_method,payment_proof_url,subtotal,discount,shipping_cost,total,shipping_courier_code,shipping_courier_name,shipping_service,shipping_etd,shipping_weight_grams,shipping_origin_id,shipping_origin_label,shipping_destination_id,shipping_destination_label)
  values(v_order_code,customer_name,customer_phone,customer_email,address,city,province,postal_code,notes,nullif(upper(trim(promo_code)),''),payment_method,payment_proof_url,v_subtotal,v_discount,greatest(0,shipping_cost),v_total,shipping_courier_code,shipping_courier_name,shipping_service,shipping_etd,shipping_weight_grams,shipping_origin_id,shipping_origin_label,shipping_destination_id,shipping_destination_label)
  returning id into v_order_id;
  for v_item in select * from jsonb_array_elements(items) loop
    select * into v_product from public.products where id=(v_item->>'product_id') for update;
    v_qty:=greatest(1,coalesce((v_item->>'quantity')::integer,1)); v_size:=upper(trim(v_item->>'size')); v_color:=nullif(trim(v_item->>'color'),'');
    insert into public.order_items(order_id,product_id,product_name,size,color,quantity,unit_price) values(v_order_id,v_product.id,v_product.name,v_size,v_color,v_qty,v_product.price);
    v_stock:=coalesce((v_product.stock_by_size->>v_size)::integer,0)-v_qty;
    v_product.stock_by_size:=jsonb_set(coalesce(v_product.stock_by_size,'{}'::jsonb),array[v_size],to_jsonb(greatest(0,v_stock)),true);
    update public.products set stock_by_size=v_product.stock_by_size,updated_at=now() where id=v_product.id;
  end loop;
  return jsonb_build_object('id',v_order_id,'order_code',v_order_code,'total',v_total);
end; $$;

grant execute on function public.place_order(text,text,text,text,text,text,text,text,text,text,text,jsonb,text,text,text,integer,text,integer,integer,text,integer,text) to anon,authenticated;

create or replace function public.get_order_tracking(p_order_code text) returns jsonb language sql security definer set search_path=public as $$
select jsonb_build_object('id',o.id,'order_code',o.order_code,'customer_name',o.customer_name,'total',o.total,'status',o.status,'tracking_number',o.tracking_number,'shipping_courier_code',o.shipping_courier_code,'shipping_courier_name',o.shipping_courier_name,'shipping_service',o.shipping_service,'shipping_etd',o.shipping_etd,'shipping_weight_grams',o.shipping_weight_grams,'shipping_destination_label',o.shipping_destination_label) from public.orders o where upper(o.order_code)=upper(trim(p_order_code)) limit 1; $$;
grant execute on function public.get_order_tracking(text) to anon,authenticated;

create or replace function public.get_order_tracking_by_identity(p_tracking_number text,p_customer_name text) returns jsonb language sql security definer set search_path=public as $$
select jsonb_build_object('id',o.id,'order_code',o.order_code,'customer_name',o.customer_name,'total',o.total,'status',o.status,'tracking_number',o.tracking_number,'shipping_courier_code',o.shipping_courier_code,'shipping_courier_name',o.shipping_courier_name,'shipping_service',o.shipping_service,'shipping_etd',o.shipping_etd,'shipping_weight_grams',o.shipping_weight_grams,'shipping_destination_label',o.shipping_destination_label) from public.orders o where upper(coalesce(o.tracking_number,''))=upper(trim(p_tracking_number)) and lower(trim(o.customer_name))=lower(trim(p_customer_name)) and o.status<>'cancelled' order by o.created_at desc limit 1; $$;
grant execute on function public.get_order_tracking_by_identity(text,text) to anon,authenticated;
