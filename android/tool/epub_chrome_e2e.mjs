import {Chrome,pause} from './epub_chrome.mjs';
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
const c=await new Chrome().connect();
const results=[];const record=(step,detail)=>{results.push({step,detail});console.log(step,JSON.stringify(detail))};
const records=()=>c.eval(`new Promise((resolve,reject)=>{const q=indexedDB.open('capitulo0-imported-epubs-v1');q.onsuccess=()=>{const db=q.result;const r=db.transaction('records').objectStore('records').getAll();r.onsuccess=()=>{resolve(r.result.map(v=>JSON.parse(v)));db.close()};r.onerror=()=>reject(r.error)}})`);
const location=()=>c.eval(`document.querySelector('iframe')?.contentWindow.rendition?.currentLocation()`);
async function libraryAfterReload(){
 await c.send('Page.reload',{ignoreCache:true});await c.waitText('Iniciar como invitado',60000);await c.click('Iniciar como invitado');await pause(1200);
 const s=await c.eval('({w:innerWidth,h:innerHeight})');for(const type of ['mousePressed','mouseReleased'])await c.send('Input.dispatchMouseEvent',{type,x:12+(s.w-84)*.375,y:s.h-45,button:'left',clickCount:1});await c.waitText('Mis libros importados (1)');
 await c.click('Mis libros importados (1)');await c.waitText('Continuar leyendo');
}
try{
 if(!(await c.eval('location.href')).startsWith('http://127.0.0.1:8766'))await c.navigate('http://127.0.0.1:8766');
 await c.send('Page.reload',{ignoreCache:true});await c.waitText('Iniciar como invitado',60000);await c.click('Iniciar como invitado');await pause(1200);
 const screen=await c.eval('({w:innerWidth,h:innerHeight})');for(const type of ['mousePressed','mouseReleased'])await c.send('Input.dispatchMouseEvent',{type,x:12+(screen.w-84)*.375,y:screen.h-45,button:'left',clickCount:1});await c.waitText('Importar libro EPUB');
 const previous=await records();
 if(previous.length){await c.click('Mis libros importados (1)');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');}
 record('start-real-Capitulo0-library','guest account, existing production UI');
 await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub');await c.waitText('3 entradas en el índice');await c.click('Guardar y leer');await pause(1800);await c.waitText('Aumentar letra EPUB');
 const first=await location();assert.equal(first.start.index,0);record('import-original-and-open',true);
 await c.click('Aumentar letra EPUB');await c.waitText('20');record('font-size',20);
 await c.click('Índice de capítulos');await c.waitText('Capítulo 3: Una biblioteca al amanecer');
 await c.screenshot('tool/epub_chrome_three_chapters.png');record('index-chapters',3);
 await c.click('Capítulo 2: El puente de las voces');await pause(1500);
 const chapter2=await location();assert.equal(chapter2.start.index,1);record('chapter2-location',chapter2.start.cfi);
 await c.screenshot('tool/epub_chrome_chapter2.png');
 await c.click('Volver a Mi Biblioteca');await c.waitText('Continuar leyendo');
 const saved=(await records())[0];assert.equal(saved.fontSize,20);assert.ok(saved.cfi.startsWith('epubcfi('));record('persisted-record',{id:saved.id,cfi:saved.cfi,progress:saved.progress,fontSize:saved.fontSize});
 await libraryAfterReload();record('full-page-reload','book remains in Mi Biblioteca');
 await c.click('Continuar leyendo');await pause(2500);
 const restored=await location();assert.equal(restored.start.index,1);assert.equal(restored.start.cfi,saved.cfi);record('restored-exact-cfi',restored.start.cfi);
 await c.waitText('20');await c.click('Volver a Mi Biblioteca');await c.waitText('Continuar leyendo');
 const download=path.resolve('tool/epub_downloads');fs.mkdirSync(download,{recursive:true});await c.send('Browser.setDownloadBehavior',{behavior:'allow',downloadPath:download,eventsEnabled:true});
 await c.click('Exportar copia EPUB');const exported=path.join(download,'capitulo0_prueba_3_capitulos.epub');
 for(let i=0;i<30&&!fs.existsSync(exported);i++)await pause(250);
 assert.deepEqual(fs.readFileSync(exported),fs.readFileSync('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub'));record('export-original-bytes',fs.statSync(exported).size);
 await c.click('Eliminar de mi Biblioteca');await c.click('Cancelar');assert.equal((await records()).length,1);record('delete-cancel','record and file preserved');
 await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');assert.equal((await records()).length,0);record('delete-confirm','record removed');
 await c.pickFile(exported);await c.click('Guardar y leer');await pause(2500);const reimport=await location();assert.equal(reimport.start.index,0);record('reimport-exported-file','opens chapter 1');
 await c.click('Índice de capítulos');await c.click('Capítulo 3: Una biblioteca al amanecer');await pause(1000);assert.equal((await location()).start.index,2);record('third-chapter-readable',true);
 const bad=c.events.filter(e=>e.method==='Network.requestWillBeSent'&&/gutendex\.com|wikisource\.org|gutenberg\.org/.test(e.params.request.url));assert.equal(bad.length,0);record('external-book-catalogue-requests',0);
 await c.screenshot('tool/epub_chrome_reimported.png');
 fs.writeFileSync('tool/epub_chrome_e2e_results.json',JSON.stringify({success:true,origin:'http://127.0.0.1:8766',mode:'real Capitulo 0 guest UI, native file chooser, real IndexedDB and epub.js',results},null,2));
}catch(error){await c.screenshot('tool/epub_chrome_e2e_failure.png');console.log('FAILED',String(error));console.log('UI',await c.text());fs.writeFileSync('tool/epub_chrome_e2e_results.json',JSON.stringify({success:false,error:String(error),results},null,2));process.exitCode=1}
finally{c.close()}
