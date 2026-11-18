from pathlib import Path
p=Path('lib/features/epub/data/epub_repository.dart');s=p.read_text(encoding='utf-8').replace("if (duplicate?.fileAvailable == true) return duplicate!;", """if (duplicate?.fileAvailable == true) {
        try { await bytes(duplicate!); return duplicate; }
        on EpubFailure { /* A valid reimport repairs a missing/corrupt private copy. */ }
      }""")
s=s.replace("source.bytes.length >", "(duplicate == null ? source.bytes.length : 0) >")
p.write_text(s,encoding='utf-8')
p=Path('tool/epub_chrome_e2e.mjs');s=p.read_text(encoding='utf-8-sig');needle="try{\n await c.click('Aumentar letra EPUB');";replacement="""try{
 await c.send('Page.reload',{ignoreCache:true});await c.waitText('Iniciar como invitado',60000);await c.click('Iniciar como invitado');await pause(1200);
 const screen=await c.eval('({w:innerWidth,h:innerHeight})');for(const type of ['mousePressed','mouseReleased'])await c.send('Input.dispatchMouseEvent',{type,x:12+(screen.w-84)*.375,y:screen.h-45,button:'left',clickCount:1});await c.waitText('Importar libro EPUB');
 const previous=await records();
 if(previous.length){await c.click('Mis libros importados (1)');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');}
 record('start-real-Capitulo0-library','guest account, existing production UI');
 await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub');await c.waitText('3 entradas en el índice');await c.click('Guardar y leer');await pause(1800);await c.waitText('Aumentar letra EPUB');
 const first=await location();assert.equal(first.start.index,0);record('import-original-and-open',true);
 await c.click('Aumentar letra EPUB');"""
assert needle in s;s=s.replace(needle,replacement);p.write_text(s,encoding='utf-8')
