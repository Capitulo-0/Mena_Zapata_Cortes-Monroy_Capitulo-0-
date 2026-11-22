import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
export const pause=ms=>new Promise(r=>setTimeout(r,ms));
export class Chrome {
  seq=0;pending=new Map();handlers=new Map();events=[];
  async connect(){
    const tabs=await (await fetch('http://127.0.0.1:9227/json')).json();
    this.ws=new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);
    await new Promise((r,j)=>{this.ws.onopen=r;this.ws.onerror=j});
    this.ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const h=this.pending.get(m.id);this.pending.delete(m.id);if(!h)return;if(m.error)h.reject(new Error(JSON.stringify(m.error)));else h.resolve(m.result)}else {this.events.push(m);for(const h of this.handlers.get(m.method)??[])h(m.params)}};
    await this.send('Page.enable');await this.send('Runtime.enable');await this.send('Network.enable');
    this.on('Runtime.exceptionThrown',p=>{const d=p.exceptionDetails;console.log('BROWSER_EXCEPTION',d.text,d.exception?.description?.slice(0,700))});
    return this;
  }
  send(method,params={}){const id=++this.seq;return new Promise((resolve,reject)=>{this.pending.set(id,{resolve,reject});this.ws.send(JSON.stringify({id,method,params}));setTimeout(()=>{if(this.pending.has(id)){this.pending.delete(id);reject(new Error('CDP timeout: '+method))}},30000).unref()})}
  on(name,fn){this.handlers.set(name,[...(this.handlers.get(name)??[]),fn])}
  async eval(expression){const r=await this.send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true,userGesture:true});if(r.exceptionDetails)throw new Error(r.exceptionDetails.exception?.description??r.exceptionDetails.text);return r.result.value}
  async navigate(url){await this.send('Page.navigate',{url});await pause(3000)}
  async semantics(){await this.eval(`(()=>{function find(n){if(n.nodeType===1){if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')return n;if(n.shadowRoot){const v=find(n.shadowRoot);if(v)return v}}for(const child of Array.from(n.childNodes??[])){const v=find(child);if(v)return v}return null}const p=find(document);if(p)p.click()})()`);await pause(800)}
  async text(){return this.eval(`(()=>{const out=[];function walk(n){if(n.nodeType===1){const a=n.getAttribute('aria-label');if(a)out.push(a);if(n.tagName==='FLT-SEMANTICS' && n.textContent)out.push(n.textContent);if(n.shadowRoot)walk(n.shadowRoot)}for(const c of n.childNodes??[])walk(c)}walk(document);return [...new Set(out)].join('\\n')})()`)}
  async click(label,contains=false,attempt=0){
    const point=await this.eval(`(()=>{const found=[];function walk(n){if(n.nodeType===1){const a=n.getAttribute('aria-label')??'';const t=n.tagName==='FLT-SEMANTICS'?n.textContent.trim():'';if(${contains?`a.includes(${JSON.stringify(label)})||t.includes(${JSON.stringify(label)})`:`a===${JSON.stringify(label)}||t===${JSON.stringify(label)}`}){const r=n.getBoundingClientRect();if(r.width>1&&r.height>1)found.push({x:r.x+r.width/2,y:r.y+r.height/2,area:r.width*r.height,role:n.getAttribute('role')})}if(n.shadowRoot)walk(n.shadowRoot)}for(const c of n.childNodes??[])walk(c)}walk(document);found.sort((a,b)=>(a.role==='button'?-1:1)-(b.role==='button'?-1:1)||a.area-b.area);return found[0]})()`);
    if(!point){if(attempt<15){await pause(300);return this.click(label,contains,attempt+1)}throw new Error('No clickable semantics: '+label+'; '+await this.text())}
    await this.send('Input.dispatchMouseEvent',{type:'mousePressed',x:point.x,y:point.y,button:'left',clickCount:1});
    await this.send('Input.dispatchMouseEvent',{type:'mouseReleased',x:point.x,y:point.y,button:'left',clickCount:1});await pause(700);
  }
  async waitText(text,timeout=30000){const start=Date.now();while(Date.now()-start<timeout){await this.eval("(()=>{function find(n){if(n.nodeType===1){if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')return n;if(n.shadowRoot){const v=find(n.shadowRoot);if(v)return v}}for(const child of Array.from(n.childNodes??[])){const v=find(child);if(v)return v}return null}const p=find(document);if(p)p.click()})()");if((await this.text()).includes(text))return;await pause(500)}throw new Error('Missing text: '+text+'; '+await this.text())}
  async pickFile(file,label='Importar libro EPUB'){
    let choose;
    const selected=new Promise(r=>choose=r);
    const listener=p=>choose(p);this.on('Page.fileChooserOpened',listener);
    await this.send('Page.setInterceptFileChooserDialog',{enabled:true});
    await this.click(label);
    const event=await Promise.race([selected,pause(10000).then(()=>{throw new Error('File chooser did not open')})]);
    await this.send('DOM.setFileInputFiles',{files:[path.resolve(file)],backendNodeId:event.backendNodeId});await pause(1500);
  }
  async screenshot(name){const r=await this.send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(name,Buffer.from(r.data,'base64'))}
  close(){this.ws.close()}
}
if(process.argv[1]?.endsWith('epub_chrome.mjs')){
 const c=await new Chrome().connect();await c.navigate('http://127.0.0.1:8765');await c.semantics();console.log(await c.text());c.close();
}
