const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const BASE = "https://rajaongkir.komerce.id/api/v1";
const KEY = Deno.env.get("RAJAONGKIR_API_KEY") || "";
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {status, headers:{...corsHeaders,"Content-Type":"application/json"}});
}
async function apiFetch(path:string, init:RequestInit={}) {
  if(!KEY) throw new Error("RAJAONGKIR_API_KEY belum diset di Supabase Edge Function.");
  const headers=new Headers(init.headers||{}); headers.set("key",KEY);
  const res=await fetch(`${BASE}${path}`,{...init,headers});
  let body:any=null; try{body=await res.json()}catch{}
  if(!res.ok || body?.meta?.status==="failed") throw new Error(body?.meta?.message||`RajaOngkir HTTP ${res.status}`);
  return body;
}
Deno.serve(async(req)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST") return json({error:"Method not allowed"},405);
  try{
    const body=await req.json(), action=body?.action;
    if(action==="search"){
      const q=String(body?.query||"").trim(); if(q.length<2)return json({data:[]});
      const p=new URLSearchParams({search:q,limit:"20",offset:"0"});
      const result=await apiFetch(`/destination/domestic-destination?${p.toString()}`);
      return json({data:result?.data||[]});
    }
    if(action==="cost"){
      const origin=Number(body?.origin),destination=Number(body?.destination),weight=Math.max(1,Number(body?.weight||0)),courier=String(body?.courier||"").trim().toLowerCase();
      if(!origin||!destination||!courier||!weight)return json({error:"origin, destination, courier, dan weight wajib diisi."},400);
      const form=new URLSearchParams({origin:String(origin),destination:String(destination),weight:String(Math.round(weight)),courier,price:"lowest"});
      const result=await apiFetch("/calculate/domestic-cost",{method:"POST",headers:{"Content-Type":"application/x-www-form-urlencoded"},body:form.toString()});
      return json({data:result?.data||[]});
    }
    if(action==="track"){
      const awb=String(body?.awb||"").trim(),courier=String(body?.courier||"").trim().toLowerCase(),lastPhoneNumber=String(body?.lastPhoneNumber||"").replace(/\D/g,"").slice(-5);
      if(!awb||!courier)return json({error:"awb dan courier wajib diisi."},400);
      const qs=new URLSearchParams({awb,courier}); if(lastPhoneNumber)qs.set("last_phone_number",lastPhoneNumber);
      const result=await apiFetch(`/track/waybill?${qs.toString()}`,{method:"POST"});
      return json({data:result?.data||null});
    }
    return json({error:"Action tidak dikenali."},400);
  }catch(e){return json({error:e?.message||"Shipping service error."},500)}
});
