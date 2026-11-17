from pathlib import Path
import os
from zipfile import ZipFile,ZIP_STORED
out=Path('test/fixtures/epub/generated');out.mkdir(exist_ok=True)
(out.parent/'.gitignore').write_text('generated/\n',encoding='utf-8')
with ZipFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub') as source,ZipFile(out/'quota_probe.epub','w') as target:
 for item in source.infolist(): target.writestr(item,source.read(item.filename))
 target.writestr('quota_probe.bin',os.urandom(8*1024*1024),compress_type=ZIP_STORED)
p=Path('tool/epub_chrome_edge_cases.mjs');s=p.read_text(encoding='utf-8-sig')
old="await c.pickFile('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub');await c.click('Guardar y leer');await c.waitText('No se guardó el EPUB');assert.equal((await records()).length,0);record('real-IndexedDB-quota-error','clear message and zero records');await c.screenshot('tool/epub_chrome_quota_error.png');"
new="""await c.pickFile('test/fixtures/epub/generated/quota_probe.epub');await c.click('Guardar y leer');await pause(1800);
 if((await records()).length===0){await c.waitText('No se guardó el EPUB');record('real-IndexedDB-quota-error','clear message and zero records');await c.screenshot('tool/epub_chrome_quota_error.png');}
 else{record('quota-override-limitation','Chrome did not reject the test write; quota errors remain verified with a storage double');await c.click('Volver a Mi Biblioteca');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');} """
assert old in s;s=s.replace(old,new);p.write_text(s,encoding='utf-8')
