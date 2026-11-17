import json,re
from pathlib import Path
from prepare_collection import CACHE,key,LiteraryText
specs=[('monte_animas','El monte de las ánimas','EL MONTE DE LAS ÁNIMAS','daba vueltas alrededor de la tumba de Alonso.',2),('maese_perez','Maese Pérez el organista','MAESE PÉREZ EL ORGANISTA','el alma de maese Pérez.',1),('ojos_verdes','Los ojos verdes','LOS OJOS VERDES','hasta espirar en las orillas.',1),('ajorca_oro','La ajorca de oro','LA AJORCA DE ORO','El infeliz estaba loco.',1),('miserere','El miserere (Bécquer)','EL MISERERE','¿Quién sabe si no serán una locura?',2)]
works=[]
for slug,title,begin,end,vol in specs:
 d=json.loads((CACHE/key(title)).read_text(encoding='utf-8')); p=d['parse']; parser=LiteraryText(); parser.feed(p['text']['*']); t=parser.text()
 assert t.startswith(begin) and t.endswith(end)
 print(slug,ascii(t[:125]),ascii(t[-110:]),flush=True)
 sections=re.findall(r'(?m)^[IVXLCDM]+$',t)
 works.append(dict(slug=slug,title=title.replace(' (Bécquer)',''),author='Gustavo Adolfo Bécquer',death_year=1870,genre='Cuentos',edition=f'Obras de Gustavo A. Bécquer, tomo {vol}, 1885. Transcripción del escaneo de Wikisource.',edition_evidence=f'https://es.wikisource.org/wiki/Índice:Obras_de_Bécquer_-_Vol._{vol}.djvu',rights_evidence=['https://www.bcn.cl/leychile/navegar?idNorma=28933','https://es.wikisource.org/wiki/Wikisource:Derechos_de_autor','https://es.wikisource.org/wiki/Autor:Gustavo_Adolfo_Bécquer'],reviewed_complete=True,internal_sections=sections,sections=[dict(label='Leyenda completa; secciones '+', '.join(sections),page=title,beginning=begin,ending=end)]))
Path('tool/free_works_batch1.json').write_text(json.dumps(works,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
