(() => {
  const NS = "http://www.w3.org/2000/svg";
  const fmt = (v, digits = 1) => v == null || Number.isNaN(Number(v)) ? "—" : new Intl.NumberFormat("pt-BR", { minimumFractionDigits: digits, maximumFractionDigits: digits }).format(Number(v));
  const count = v => v == null ? "—" : new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(Number(v));
  const el = (name, attrs = {}) => { const n = document.createElementNS(NS, name); Object.entries(attrs).forEach(([k,v]) => n.setAttribute(k,v)); return n; };
  const clear = n => { while (n.firstChild) n.removeChild(n.firstChild); };

  function tooltip(container) {
    let tip = container.querySelector(".skills-tooltip");
    if (!tip) { tip = document.createElement("div"); tip.className = "skills-tooltip"; container.appendChild(tip); }
    return tip;
  }
  function showTip(container, event, html) {
    const tip = tooltip(container); tip.innerHTML = html; tip.classList.add("is-visible");
    const r = container.getBoundingClientRect(); tip.style.left = `${event.clientX-r.left+12}px`; tip.style.top = `${event.clientY-r.top+12}px`;
  }
  function hideTip(container) { const tip = container.querySelector(".skills-tooltip"); if (tip) tip.classList.remove("is-visible"); }

  function bar(container, p) {
    clear(container); const labels=p.labels||[], values=(p.values||[]).map(v=>v==null?null:Number(v)), meta=p.meta||[];
    if (!values.some(v=>v!=null)) { container.textContent="Sem dados para exibir."; return; }
    const width=Math.max(container.clientWidth||900,900), height=430, left=58,right=24,top=28,bottom=60, pw=width-left-right, ph=height-top-bottom;
    const max=Math.max(...values.filter(v=>v!=null),1)*1.18, slot=pw/labels.length, bw=Math.max(8,Math.min(28,slot*.62));
    const svg=el("svg",{viewBox:`0 0 ${width} ${height}`,role:"img","aria-label":"Distribuição das habilidades"}); svg.classList.add("skills-svg");
    for(let i=0;i<=4;i++){const y=top+(i/4)*ph,val=max-(i/4)*max;svg.appendChild(el("line",{x1:left,y1:y,x2:width-right,y2:y,class:"skills-grid"}));const t=el("text",{x:left-9,y:y+4,"text-anchor":"end",class:"skills-axis"});t.textContent=`${fmt(val)}%`;svg.appendChild(t);}
    labels.forEach((lab,i)=>{const v=values[i],x=left+i*slot+slot/2;const tx=el("text",{x,y:height-24,"text-anchor":"middle",class:"skills-axis"});tx.textContent=lab;svg.appendChild(tx);if(v==null)return;const h=(v/max)*ph,y=top+ph-h;const rect=el("rect",{x:x-bw/2,y,width:bw,height:h,rx:4,class:"skills-bar"});rect.addEventListener("mousemove",e=>{const m=meta[i]||{};showTip(container,e,`<strong>${lab} · ${fmt(v)}%</strong><span>${count(m.questions)} questão(ões)</span><span>${m.competency?`Competência ${m.competency}`:"Competência não informada"}</span><small>${m.description||""}</small>`)});rect.addEventListener("mouseleave",()=>hideTip(container));svg.appendChild(rect);});container.appendChild(svg);
  }

  function line(container,p){
    clear(container);const labels=p.labels||[],values=(p.values||[]).map(v=>v==null?null:Number(v)),meta=p.meta||[],pts=values.map((v,i)=>({v,i})).filter(x=>x.v!=null);
    if(!pts.length){container.textContent="Sem dados para exibir.";return;}const width=Math.max(container.clientWidth||800,700),height=360,left=62,right=28,top=30,bottom=52,pw=width-left-right,ph=height-top-bottom;
    const rawMax=Math.max(...pts.map(x=>x.v)),rawMin=p.zero_floor?0:Math.min(...pts.map(x=>x.v));const pad=Math.max((rawMax-rawMin)*.12,1),min=p.zero_floor?0:Math.max(0,rawMin-pad),max=Math.max(rawMax+pad,5),range=max-min;
    const x=i=>left+(labels.length<=1?pw/2:(i/(labels.length-1))*pw),y=v=>top+ph-((v-min)/range)*ph;const svg=el("svg",{viewBox:`0 0 ${width} ${height}`,role:"img","aria-label":"Evolução histórica"});svg.classList.add("skills-svg");
    for(let i=0;i<=4;i++){const gy=top+(i/4)*ph,val=max-(i/4)*range;svg.appendChild(el("line",{x1:left,y1:gy,x2:width-right,y2:gy,class:"skills-grid"}));const t=el("text",{x:left-9,y:gy+4,"text-anchor":"end",class:"skills-axis"});t.textContent=`${fmt(val)}${p.suffix||""}`;svg.appendChild(t);}
    labels.forEach((lab,i)=>{const t=el("text",{x:x(i),y:height-20,"text-anchor":"middle",class:"skills-axis"});t.textContent=lab;svg.appendChild(t);});svg.appendChild(el("polyline",{points:pts.map(q=>`${x(q.i)},${y(q.v)}`).join(" "),fill:"none",class:"skills-line"}));
    pts.forEach(q=>{const c=el("circle",{cx:x(q.i),cy:y(q.v),r:5,class:"skills-point"});c.addEventListener("mousemove",e=>{const m=meta[q.i]||{};let extras="";if(m.questions!=null)extras+=`<span>${count(m.questions)} questão(ões)</span>`;if(m.participants!=null)extras+=`<span>${count(m.participants)} participantes</span><span>${count(m.correct)} acertos em ${count(m.responses)} respostas</span>`;showTip(container,e,`<strong>${labels[q.i]} · ${fmt(q.v)}${p.suffix||""}</strong>${extras}`)});c.addEventListener("mouseleave",()=>hideTip(container));svg.appendChild(c);});container.appendChild(svg);
  }

  function render(){document.querySelectorAll("[data-skills-chart-type]").forEach(c=>{let p={};try{p=JSON.parse(c.dataset.skillsChart||"{}")}catch(_e){};c.dataset.skillsChartType==="bar"?bar(c,p):line(c,p);});}
  let timer;document.addEventListener("DOMContentLoaded",render);document.addEventListener("turbo:load",render);window.addEventListener("resize",()=>{clearTimeout(timer);timer=setTimeout(render,150);});
})();
