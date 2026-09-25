const FALLBACK_PRODUCTS=[
{id:'entangled-nightmares',name:'Entangled Nightmares Tee',price:145000,cat:'new-drop',badge:'Pre-Order',order_mode:'preorder',sizes:['S','M','L','XL'],image_urls:['assets/products/entangled-1.jpg','assets/products/entangled-2.jpg','assets/products/entangled-3.jpg','assets/products/entangled-4.jpg'],description:'Dibuat untuk mereka yang ingin graphic tee terasa lebih refined. Matt Cotton 24s memberi karakter kain yang solid namun tetap nyaman, sementara Plastisol Screen Printing menghasilkan artwork yang tajam, padat, dan punya depth visual yang terasa premium.',short_description:'Graphic tee dengan artwork gelap yang kuat, material premium, dan finishing print yang clean.',material:'Matt Cotton 24s',printing:'Plastisol Screen Printing'},
{id:'the-doppelganger',name:'The Doppelgänger Tee',price:145000,cat:'new-drop',badge:'Pre-Order',order_mode:'preorder',sizes:['S','M','L','XL'],image_urls:['assets/products/doppelganger-1.jpg','assets/products/doppelganger-2.jpg','assets/products/doppelganger-3.jpg'],description:'The Doppelgänger memadukan karakter artwork editorial dengan feel kaos premium yang understated. Matt Cotton 24s terasa lembut namun tetap berstruktur, dipadukan dengan Plastisol Screen Printing untuk detail grafis yang tegas dan durable.',short_description:'Editorial graphic tee dengan hand-feel premium dan print yang bold namun refined.',material:'Matt Cotton 24s',printing:'Plastisol Screen Printing'},
{id:'dark-vitruvian',name:'Dark Vitruvian Tee',price:145000,cat:'new-drop',badge:'Pre-Order',order_mode:'preorder',sizes:['S','M','L','XL'],image_urls:['assets/products/dark-vitruvian-1.jpg','assets/products/dark-vitruvian-2.jpg','assets/products/dark-vitruvian-3.jpg'],description:'Dark Vitruvian menghadirkan graphic yang ikonik dengan pendekatan modern dan clean. Matt Cotton 24s memberikan body kain premium, breathable, dan tetap nyaman, sedangkan Plastisol Screen Printing menjaga artwork tetap crisp.',short_description:'Ikonik, dark, dan clean — premium everyday tee dengan graphic statement.',material:'Matt Cotton 24s',printing:'Plastisol Screen Printing'},
{id:'gracious-white',name:'GRACIOUS White Graphic Tee',price:145000,cat:'essentials',badge:'Essential',order_mode:'order',sizes:['S','M','L','XL'],image_urls:['assets/products/entangled-1.jpg'],description:'Essential graphic tee dengan pendekatan clean dan versatile. Matt Cotton 24s menghadirkan body kain yang nyaman dan berstruktur, dipadukan dengan Plastisol Screen Printing untuk hasil graphic yang tajam dan premium.',short_description:'Clean essential tee untuk daily rotation.',material:'Matt Cotton 24s',printing:'Plastisol Screen Printing'}
];
let PRODUCTS=[...FALLBACK_PRODUCTS],CATEGORIES=[],PAYMENT_METHODS=[];
let STORE_PROFILE={store_name:'GRACIOUS',tagline:'Premium Graphic Essentials',description:'',logo_url:'',email:'',phone:'',whatsapp:'',instagram:'',address:''};
const SHIPPING=15000;
const STORE_I18N={
  id:{
    shop:'Toko',newDrop:'New Drop',essentials:'Essentials',track:'Lacak Pesanan',bag:'Tas',
    all:'Semua',buy:'BELI SEKARANG ↗',preorder:'PRE-ORDER ↗',shopPre:'SHOP PRE-ORDER ↗',
    shopCollection:'SHOP COLLECTION ↗',explorePre:'EXPLORE PRE-ORDER ↗',exploreDrop:'EXPLORE THE DROP ↗',
    sold:'SOLD OUT',available:(n,size)=>`${n} pcs tersedia untuk size ${size}.`,out:'Size ini sedang habis.',
    currency:'Mata Uang',language:'Bahasa',premium:'Premium Hand Feel',
    order:'ORDER',orderNow:'ORDER NOW ↗',preorderItem:'Pre-order item. Detail pengiriman akan dikonfirmasi admin setelah pesanan diterima.',
    readyItem:'Ready to order. Pesanan akan diproses setelah konfirmasi admin.'
  },
  en:{
    shop:'Shop',newDrop:'New Drop',essentials:'Essentials',track:'Track Order',bag:'Bag',
    all:'All',buy:'BUY NOW ↗',preorder:'PRE-ORDER ↗',shopPre:'SHOP PRE-ORDER ↗',
    shopCollection:'SHOP COLLECTION ↗',explorePre:'EXPLORE PRE-ORDER ↗',exploreDrop:'EXPLORE THE DROP ↗',
    sold:'SOLD OUT',available:(n,size)=>`${n} pcs available in size ${size}.`,out:'This size is sold out.',
    currency:'Currency',language:'Language',premium:'Premium Hand Feel',
    order:'ORDER',orderNow:'ORDER NOW ↗',preorderItem:'Pre-order item. Shipping details will be confirmed by admin after your order is received.',
    readyItem:'Ready to order. Your order will be processed after admin confirmation.'
  }
};
const CURRENCY_CONFIG={
  IDR:{locale:'id-ID',rate:1,label:'Indonesian Rupiah',flag:'🇮🇩',decimals:0},
  USD:{locale:'en-US',rate:1/16000,label:'US Dollar',flag:'🇺🇸',decimals:2},
  EUR:{locale:'de-DE',rate:1/18700,label:'Euro',flag:'🇪🇺',decimals:2},
  GBP:{locale:'en-GB',rate:1/21600,label:'British Pound',flag:'🇬🇧',decimals:2},
  SGD:{locale:'en-SG',rate:1/12500,label:'Singapore Dollar',flag:'🇸🇬',decimals:2},
  MYR:{locale:'ms-MY',rate:1/3800,label:'Malaysian Ringgit',flag:'🇲🇾',decimals:2},
  JPY:{locale:'ja-JP',rate:1/107,label:'Japanese Yen',flag:'🇯🇵',decimals:0},
  KRW:{locale:'ko-KR',rate:1/12,label:'South Korean Won',flag:'🇰🇷',decimals:0},
  AUD:{locale:'en-AU',rate:1/10800,label:'Australian Dollar',flag:'🇦🇺',decimals:2},
  CAD:{locale:'en-CA',rate:1/11700,label:'Canadian Dollar',flag:'🇨🇦',decimals:2},
  CNY:{locale:'zh-CN',rate:1/2250,label:'Chinese Yuan',flag:'🇨🇳',decimals:2}
};
let STORE_LANGUAGE=localStorage.getItem('graciousLanguage')||'id';
let STORE_CURRENCY=localStorage.getItem('graciousCurrency')||'IDR';
const fmt=n=>new Intl.NumberFormat(CURRENCY_CONFIG[STORE_CURRENCY].locale,{style:'currency',currency:STORE_CURRENCY,maximumFractionDigits:CURRENCY_CONFIG[STORE_CURRENCY].decimals}).format((Number(n)||0)*CURRENCY_CONFIG[STORE_CURRENCY].rate);
const esc=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
function t(key,...args){const v=STORE_I18N[STORE_LANGUAGE]?.[key]??STORE_I18N.id[key]??key;return typeof v==='function'?v(...args):v}
function applyStorePreferences(){
  document.documentElement.lang=STORE_LANGUAGE;
  document.querySelectorAll('[data-lang-id]').forEach(el=>{el.textContent=t(el.dataset.langId)});
  document.querySelectorAll('[data-lang]').forEach(el=>el.classList.toggle('active',el.dataset.lang===STORE_LANGUAGE));
  document.querySelectorAll('[data-currency]').forEach(el=>el.classList.toggle('active',el.dataset.currency===STORE_CURRENCY));
  document.querySelectorAll('[data-currency-label]').forEach(el=>el.textContent=STORE_CURRENCY);
  const cur=CURRENCY_CONFIG[STORE_CURRENCY];
  document.querySelectorAll('[data-currency-current]').forEach(el=>el.innerHTML=`<span>${cur.flag}</span><b>${STORE_CURRENCY}</b><small>${cur.label}</small>`);
  document.querySelectorAll('[data-money]').forEach(el=>{el.textContent=fmt(Number(el.dataset.money||0))});
  document.querySelectorAll('[data-order-cta]').forEach(el=>{const pre=window.GRACIOUS_MODE==='preorder';const key=pre?(el.dataset.preorderKey||'shopPre'):(el.dataset.orderKey||'shopCollection');el.textContent=t(key)});
  const bag=document.getElementById('cartLink')||document.querySelector('[data-bag-link]');if(bag)bag.setAttribute('aria-label',t('bag'));
  const add=document.getElementById('add');if(add&&!add.disabled){const p=window.__CURRENT_PRODUCT;if(p)add.textContent=p.preorder?t('preorder'):t('orderNow')}
}
function setLanguage(lang){if(!STORE_I18N[lang])return;STORE_LANGUAGE=lang;localStorage.setItem('graciousLanguage',lang);location.reload()}
function setCurrency(currency){if(!CURRENCY_CONFIG[currency])return;STORE_CURRENCY=currency;localStorage.setItem('graciousCurrency',currency);document.querySelectorAll('.currency-popover').forEach(x=>x.classList.remove('open'));applyStorePreferences();document.dispatchEvent(new CustomEvent('currencychange',{detail:currency}))}
function injectStoreControls(){
  const nav=document.querySelector('nav');if(!nav||nav.querySelector('.store-preferences'))return;
  const box=document.createElement('div');box.className='store-preferences';
  const currencyOptions=Object.entries(CURRENCY_CONFIG).map(([code,c])=>`<button type="button" class="currency-option ${code===STORE_CURRENCY?'active':''}" data-currency="${code}"><span class="currency-flag">${c.flag}</span><span><b>${code}</b><small>${c.label}</small></span></button>`).join('');
  box.innerHTML=`<div class="pref-group language-pop"><button class="pref-trigger" type="button"><span>文</span><b>${STORE_LANGUAGE.toUpperCase()}</b><i>⌄</i></button><div class="mini-pop language-menu"><button data-lang="id" class="${STORE_LANGUAGE==='id'?'active':''}">🇮🇩 Indonesia</button><button data-lang="en" class="${STORE_LANGUAGE==='en'?'active':''}">🇺🇸 English</button></div></div>
  <div class="pref-group currency-pop"><button class="pref-trigger currency-trigger" type="button"><span>${CURRENCY_CONFIG[STORE_CURRENCY].flag}</span><b data-currency-label>${STORE_CURRENCY}</b><i>⌄</i></button><div class="currency-popover">${currencyOptions}</div></div>`;
  nav.querySelector('.actions')?.prepend(box);
  const close=()=>box.querySelectorAll('.mini-pop,.currency-popover').forEach(x=>x.classList.remove('open'));
  box.addEventListener('click',e=>{
    const lang=e.target.closest('[data-lang]');const cur=e.target.closest('[data-currency]');
    if(lang){setLanguage(lang.dataset.lang);return}
    if(cur){setCurrency(cur.dataset.currency);return}
    const lt=e.target.closest('.language-pop>.pref-trigger');const ct=e.target.closest('.currency-trigger');
    if(lt){close();box.querySelector('.language-menu').classList.toggle('open')}
    if(ct){close();box.querySelector('.currency-popover').classList.toggle('open')}
  });
  document.addEventListener('click',e=>{if(!box.contains(e.target))close()},{passive:true});
  applyStorePreferences();
}
const normalizeProduct=p=>({...p,cat:p.categories?.slug||p.cat||'',preorder:p.order_mode==='preorder',badge:p.badge||'',images:p.image_urls?.length?p.image_urls:['assets/logo.jpg'],desc:p.description||'',short:p.short_description||'',tag:[p.material,p.printing].filter(Boolean).join(' · '),stock_by_size:p.stock_by_size||{}});
const byId=id=>PRODUCTS.find(p=>p.id===id)||PRODUCTS[0];
function stockForSize(p,size){return Number(p?.stock_by_size?.[size]??0)}
function getCart(){try{return JSON.parse(localStorage.getItem('graciousCart')||'[]')}catch{return[]}}
function setCart(c){localStorage.setItem('graciousCart',JSON.stringify(c));updateCartCount()}
function addCart(id,size='M',qty=1){const c=getCart(),p=byId(id);if(!p)return;const key=id+'-'+size,x=c.find(i=>i.key===key);if(x)x.qty+=qty;else c.push({key,id,size,qty,name:p.name,price:p.price,img:p.images[0],preorder:p.preorder});setCart(c);toast('Ditambahkan ke keranjang')}
function updateCartCount(){const n=getCart().reduce((s,x)=>s+x.qty,0);document.querySelectorAll('[data-cart-count]').forEach(e=>e.textContent=n)}
function toast(m){const e=document.querySelector('.toast');if(!e)return;e.textContent=m;e.classList.add('show');clearTimeout(window.__toast);window.__toast=setTimeout(()=>e.classList.remove('show'),2200)}
function escapeHtml(s){return esc(s)}
async function supa(){if(!window.supabase)return null;return window.supabase.createClient(window.GRACIOUS_CONFIG?.supabaseUrl||'https://dlkdtmdmauqvbumhyqsu.supabase.co',window.GRACIOUS_CONFIG?.supabaseAnonKey||'sb_publishable_A5Lenr4D9XPyVTHgoIozuA_9wfsvfIc')}
async function loadStoreProfile(){try{const sb=await supa();if(!sb)return;const {data,error}=await sb.from('store_profile').select('*').eq('id',true).maybeSingle();if(!error&&data){STORE_PROFILE={...STORE_PROFILE,...data};document.title=`${STORE_PROFILE.store_name} — ${STORE_PROFILE.tagline}`;document.querySelectorAll('.logo img').forEach(img=>{if(STORE_PROFILE.logo_url)img.src=STORE_PROFILE.logo_url});document.querySelectorAll('link[rel="icon"]').forEach(icon=>{if(STORE_PROFILE.logo_url)icon.href=STORE_PROFILE.logo_url});document.querySelectorAll('.logo span').forEach(el=>{el.textContent=STORE_PROFILE.store_name});document.querySelectorAll('footer .wrap').forEach(el=>{el.innerHTML=`© ${new Date().getFullYear()} ${esc(STORE_PROFILE.store_name)} — ${esc(STORE_PROFILE.tagline)}${STORE_PROFILE.address?` · ${esc(STORE_PROFILE.address)}`:''}.`});document.querySelectorAll('[data-store-name]').forEach(el=>el.textContent=STORE_PROFILE.store_name);document.querySelectorAll('[data-store-tagline]').forEach(el=>el.textContent=STORE_PROFILE.tagline);document.querySelectorAll('[data-store-description]').forEach(el=>el.textContent=STORE_PROFILE.description);}}catch(e){console.warn('Store profile unavailable',e)}return STORE_PROFILE}
async function loadCatalog(){try{const sb=await supa();if(!sb)return;const [{data:p},{data:c},{data:pay}]=await Promise.all([sb.from('products').select('*,categories(name,slug)').eq('active',true).order('created_at',{ascending:false}),sb.from('categories').select('*').eq('active',true).order('name'),sb.from('payment_methods').select('*').eq('active',true).order('sort_order').order('created_at')]);if(Array.isArray(p)) PRODUCTS=p.map(normalizeProduct);if(c)CATEGORIES=c;if(pay)PAYMENT_METHODS=pay}catch(e){console.warn('Catalog unavailable',e)}return PRODUCTS}
window.GRACIOUS_MODE='preorder';
async function loadStoreMode(){try{const sb=await supa();if(sb){const {data}=await sb.from('site_settings').select('order_mode').eq('id',true).maybeSingle();if(data?.order_mode)window.GRACIOUS_MODE=data.order_mode}}catch(e){}applyStoreMode()}
function applyStoreMode(){const isPre=window.GRACIOUS_MODE==='preorder';document.documentElement.dataset.orderMode=window.GRACIOUS_MODE;document.querySelectorAll('[data-order-cta]').forEach(el=>el.textContent=isPre?(el.dataset.preorderText||'PRE-ORDER ↗'):(el.dataset.orderText||'ORDER NOW ↗'));document.querySelectorAll('[data-mode-label]').forEach(el=>el.textContent=isPre?'PRE-ORDER':'ORDER')}
function setupButtonMotion(){document.querySelectorAll('button,.btn,.icon,.filter,.size').forEach(el=>{if(el.dataset.motionReady)return;el.dataset.motionReady='1';el.addEventListener('pointerdown',()=>el.classList.add('press'));el.addEventListener('pointerup',()=>setTimeout(()=>el.classList.remove('press'),120));el.addEventListener('pointerleave',()=>el.classList.remove('press'));el.addEventListener('click',e=>{if(el.disabled)return;const r=el.getBoundingClientRect(),ripple=document.createElement('i');ripple.className='ripple';ripple.style.left=e.clientX-r.left+'px';ripple.style.top=e.clientY-r.top+'px';el.appendChild(ripple);setTimeout(()=>ripple.remove(),650)})})}
async function nav(){injectStoreControls();document.querySelectorAll('[data-cart]').forEach(e=>e.innerHTML='◰ <span class="cart-count" data-cart-count>0</span>');updateCartCount();const l=document.querySelector('.loader');window.addEventListener('load',()=>setTimeout(()=>l?.classList.add('hide'),320));await Promise.all([loadCatalog(),loadStoreProfile(),loadStoreMode()]);setupButtonMotion();applyStorePreferences()}
function renderCards(items,el){if(!el)return;el.innerHTML=items.map(p=>`<a class="card reveal" href="product.html?id=${encodeURIComponent(p.id)}"><div class="media"><img src="${esc(p.images[0])}" alt="${esc(p.name)}" loading="lazy"></div><div class="badge">${esc(p.preorder?'PRE-ORDER':(p.badge||'ORDER'))}</div><h3>${esc(p.name)}</h3><p class="price">${fmt(p.price)}</p></a>`).join('');requestAnimationFrame(()=>document.querySelectorAll('.reveal').forEach((x,i)=>setTimeout(()=>x.classList.add('in'),Math.min(i*55,350))));setupButtonMotion()}
function categorySlugFromQuery(){return new URLSearchParams(location.search).get('category')||'all'}
window.GRACIOUS={loadCatalog,loadStoreProfile,loadStoreMode,nav,renderCards,byId,addCart,getCart,setCart,fmt,esc,stockForSize,CATEGORIES,PRODUCTS,PAYMENT_METHODS,STORE_PROFILE,setLanguage,setCurrency,t};
