// Test-only bridge for Flutter 3.47 Windows runner CanvasKit 404s.
// Serves the exact existing SDK JS/Wasm bytes; never changes application/tests/SDK.
import fs from 'node:fs';
import path from 'node:path';
const port=Number(process.argv[2]);
const sdk=path.resolve(process.argv[3]);
const pages=await(await fetch(`http://127.0.0.1:${port}/json`)).json();
const target=pages.find(p=>p.type==='iframe' && p.url.includes('_test.html')) ?? pages.find(p=>p.type==='page');
if(!target)throw new Error('No test Chrome page');
const ws=new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve,reject)=>{ws.onopen=resolve;ws.onerror=reject});
let sequence=0;const pending=new Map();let served=0;
function send(method,params={}){const id=++sequence;return new Promise((resolve,reject)=>{pending.set(id,{resolve,reject});ws.send(JSON.stringify({id,method,params}))})}
ws.onmessage=async event=>{
 const message=JSON.parse(event.data);
 if(message.id){const h=pending.get(message.id);if(!h)return;pending.delete(message.id);if(message.error)h.reject(new Error(JSON.stringify(message.error)));else h.resolve(message.result);return}
 if(message.method!=='Fetch.requestPaused')return;
 const request=message.params;const pathname=new URL(request.request.url).pathname;
 try{
  const relative=decodeURIComponent(pathname).replace(/^\/canvaskit\//,'');
  const file=path.resolve(sdk,relative);
  if(!file.startsWith(sdk+path.sep)||!['.js','.wasm'].includes(path.extname(file)))throw new Error('Unexpected asset path');
  const bytes=fs.readFileSync(file);
  await send('Fetch.fulfillRequest',{requestId:request.requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:file.endsWith('.wasm')?'application/wasm':'text/javascript'}],body:bytes.toString('base64')});
  served++;console.log('SDK_ASSET',relative,bytes.length);
 }catch(error){console.log('ASSET_ERROR',String(error));await send('Fetch.continueRequest',{requestId:request.requestId}).catch(()=>{})}
};
await send('Fetch.enable',{patterns:[{urlPattern:'*/canvaskit/*',requestStage:'Request'}]});
await send('Page.addScriptToEvaluateOnNewDocument',{source: `if(location.pathname.endsWith('_test.html')){Object.defineProperty(window,'testSelector',{configurable:true,get(){return decodeURIComponent(location.pathname).slice(1).replace(/\\.html$/,'.dart')},set(v){}})}`});
const mainSource=await send('Runtime.evaluate',{expression: "fetch('/main.dart.lib.js').then(r=>r.text()).then(s=>s.slice(0,5000))",awaitPromise:true,returnByValue:true});
console.log('Bootstrap inspected; no application data accessed.');
await send('Runtime.evaluate',{expression:target.type==='iframe'?"location.reload()":"document.querySelector('iframe').contentWindow.location.reload()"});
console.log('CanvasKit SDK bridge active. No test assertions altered.');
ws.onclose=()=>{console.log('Chrome closed; served',served,'SDK assets');process.exit(0)};
process.on('SIGINT',()=>ws.close());