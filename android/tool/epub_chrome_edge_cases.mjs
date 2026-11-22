import {Chrome,pause} from './epub_chrome.mjs';import fs from 'node:fs';import assert from 'node:assert/strict';
const c=await new Chrome().connect();const results=[];const record=(step,value)=>{results.push({step,value});console.log(step,JSON.stringify(value))};
const records=()=>c.eval(`new Promise(r=>{const q=indexedDB.open('capitulo0-imported-epubs-v1');q.onsuccess=()=>{const db=q.result;const t=db.transaction('records').objectStore('records').getAll();t.onsuccess=()=>{r(t.result.map(x=>JSON.parse(x)));db.close()}}})`);
const location=()=>c.eval(`document.querySelector('iframe')?.contentWindow.rendition?.currentLocation()`);
async function reloadLibrary(){await c.send('Page.reload',{ignoreCache:true});await c.waitText('Iniciar como invitado',60000);await c.click('Iniciar como invitado');await pause(1000);const s=await c.eval('({w:innerWidth,h:innerHeight})');for(const type of ['mousePressed','mouseReleased'])await c.send('Input.dispatchMouseEvent',{type,x:12+(s.w-84)*.375,y:s.h-45,button:'left',clickCount:1});await c.waitText('Mis libros importados (1)');await c.click('Mis libros importados (1)');}
try{
 const initial=await c.text();
 if(initial.includes('Incorporar EPUB'))await c.click('Cancelar');
 else if(initial.includes('Volver a Mi Biblioteca'))await c.click('Volver a Mi Biblioteca');
 if((await records()).length){if(!(await c.text()).includes('Eliminar de mi Biblioteca'))await c.click('Mis libros importados (1)');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');}
 await c.waitText('Mis libros importados (0)');
 await c.send('Storage.overrideQuotaForOrigin',{origin:'http://127.0.0.1:8766',quotaSize:1});
 await c.pickFile('test/fixtures/epub/generated/quota_probe.epub');await c.click('Guardar y leer');await pause(1800);
 if((await records()).length===0){await c.waitText('No se guardó el EPUB');record('real-IndexedDB-quota-error','clear message and zero records');await c.screenshot('tool/epub_chrome_quota_error.png');}
 else{record('quota-override-limitation','Chrome did not reject the test write; quota errors remain verified with a storage double');await c.click('Volver a Mi Biblioteca');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');}
 await c.send('Storage.overrideQuotaForOrigin',{origin:'http://127.0.0.1:8766'});
 await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub');await c.click('Cancelar');assert.equal((await records()).length,0);record('real-import-confirmation-cancel','zero records');
 fs.writeFileSync('test/fixtures/epub/corrupt_browser_test.epub','This is not a ZIP or EPUB.');await c.pickFile('test/fixtures/epub/corrupt_browser_test.epub');await c.waitText('no es un EPUB ZIP válido');assert.equal((await records()).length,0);record('real-corrupt-import','rejected, zero records');
 await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub');await c.click('Guardar y leer');await c.waitText('Índice de capítulos');await pause(1000);await c.click('Índice de capítulos');await c.click('Capítulo 2: El puente de las voces');await pause(1200);assert.equal((await location()).start.index,1);await c.click('Volver a Mi Biblioteca');await c.waitText('Continuar leyendo');
 const saved=(await records())[0];assert.ok(saved.cfi.includes('/6/4'));
 await c.eval(`new Promise((resolve,reject)=>{const q=indexedDB.open('capitulo0-imported-epubs-v1');q.onsuccess=()=>{const db=q.result;const tx=db.transaction(['files','records'],'readwrite');const r=tx.objectStore('files').getAllKeys();r.onsuccess=()=>{for(const k of r.result)tx.objectStore('files').delete(k)};tx.oncomplete=()=>{db.close();resolve(true)};tx.onerror=()=>reject(tx.error)}})`);
 await reloadLibrary();await c.waitText('Reimportar EPUB');record('real-missing-binary-after-reload','shows Reimportar EPUB, no reading promise');
 await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub','Reimportar EPUB');await c.click('Guardar y leer');await c.waitText('Índice de capítulos');await pause(1600);assert.equal((await location()).start.index,1);assert.equal((await location()).start.cfi,saved.cfi);record('real-missing-binary-recovery','original file and exact chapter2 CFI recovered');
 for(const [width,height] of [[320,568],[360,640],[390,844]]){
  await c.send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:true});await pause(1200);
  const metrics=await c.eval(`(()=>{const frame=document.querySelector('iframe');const doc=frame.contentDocument;return {appWidth:innerWidth,rootWidth:doc.documentElement.clientWidth,scrollWidth:doc.documentElement.scrollWidth,frameWidth:frame.getBoundingClientRect().width,chapter:frame.contentWindow.rendition.currentLocation()?.start?.index}})()`);
  assert.ok(metrics.scrollWidth<=metrics.rootWidth+1);assert.ok(metrics.frameWidth<=width+1);await c.screenshot('tool/epub_chrome_'+width+'x'+height+'.png');record('real-mobile-'+width+'x'+height,metrics);
 }
 await c.send('Emulation.clearDeviceMetricsOverride');
 fs.writeFileSync('tool/epub_chrome_edge_results.json',JSON.stringify({success:true,results},null,2));
}catch(error){console.log('FAILED',String(error));console.log(await c.text());fs.writeFileSync('tool/epub_chrome_edge_results.json',JSON.stringify({success:false,error:String(error),results},null,2));await c.screenshot('tool/epub_chrome_edge_failure.png');process.exitCode=1}
finally{try{await c.send('Storage.overrideQuotaForOrigin',{origin:'http://127.0.0.1:8766'})}catch{}c.close()}
