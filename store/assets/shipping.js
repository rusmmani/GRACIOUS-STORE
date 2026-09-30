(() => {
  const cfg = window.GRACIOUS_CONFIG || {};
  const endpoint = cfg.shippingFunctionUrl || ((cfg.supabaseUrl || '').replace(/\/$/, '') + '/functions/v1/shipping');
  const COURIERS = [
    {code:'jne', name:'JNE'},
    {code:'jnt', name:'J&T Express'},
    {code:'sicepat', name:'SiCepat'},
    {code:'pos', name:'POS Indonesia'}
  ];
  async function request(body){
    if(!endpoint) throw new Error('Shipping API endpoint belum dikonfigurasi.');
    const res = await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    let data=null; try{data=await res.json()}catch{}
    if(!res.ok || data?.error) throw new Error(data?.error || data?.message || `Shipping API error ${res.status}`);
    return data;
  }
  async function search(query){const q=String(query||'').trim();if(q.length<2)return[];const d=await request({action:'search',query:q});return Array.isArray(d?.data)?d.data:[]}
  async function cost({origin,destination,weight,courier}){const d=await request({action:'cost',origin:Number(origin),destination:Number(destination),weight:Number(weight),courier});return Array.isArray(d?.data)?d.data:[]}
  async function track({awb,courier,lastPhoneNumber=''}){return request({action:'track',awb:String(awb||'').trim(),courier,lastPhoneNumber:String(lastPhoneNumber||'').slice(-5)})}
  window.GRACIOUS_SHIPPING={endpoint,COURIERS,search,cost,track};
})();
