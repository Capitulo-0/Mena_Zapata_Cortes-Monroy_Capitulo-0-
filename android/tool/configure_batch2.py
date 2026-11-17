import json,re
from pathlib import Path
from prepare_collection import CACHE,key,extract
rights=['https://www.bcn.cl/leychile/navegar?idNorma=28933','https://es.wikisource.org/wiki/Wikisource:Derechos_de_autor']
works=[]
def section(page,label,begin,end,mode='scan',count=None):
 d=json.loads((CACHE/key(page)).read_text(encoding='utf-8')); parser,t=extract(d['parse'],mode)
 assert t.startswith(begin) and t.endswith(end),(page, t[:100],t[-100:])
 headings=re.findall(r'(?m)^(?:[IVXLCDM]+(?:\.\s*)?|[IVXLCDM]+ - .+)$',t)
 if count is not None: assert len(headings)==count,(page,len(headings))
 return dict(page=page,label=label,beginning=begin,ending=end,extraction=mode,reviewed_headings=headings)
def work(slug,title,author,death,genre,edition,evidence,sections,notes=''):
 return dict(slug=slug,title=title,author=author,death_year=death,genre=genre,edition=edition,edition_evidence=evidence,rights_evidence=rights+['https://es.wikisource.org/wiki/Autor:'+author.replace(' ','_')],reviewed_complete=True,sections=sections,notes=notes)
for slug,title,end,vol in [('beso','El beso','de su guantelete de piedra.',2),('promesa','La promesa','está enterrada Margarita.',2),('cueva_mora','La cueva de la mora','por estos contornos.',2),('gnomo','El gnomo','del toque del Ave- María.',2),('venta_gatos','La venta de los gatos','yo aprendí á descifrar entonces.',3)]:
 works.append(work(slug,title,'Gustavo Adolfo Bécquer',1870,'Cuentos',f'Obras de Gustavo A. Bécquer, tomo {vol}, 1885. Transcripción del escaneo de Wikisource.',f'https://es.wikisource.org/wiki/Índice:Obras_de_Bécquer_-_Vol._{vol}.djvu',[section(title,'Relato completo',title.upper(),end)]))
s=section('scan:rimas1885:141-218','Rimas I–LXXVI','I\n\nYo sé un himno gigante y extraño','¡Qué sueño el del sepulcro tan tranquilo!',count=76)
works.append(work('rimas_1885','Rimas','Gustavo Adolfo Bécquer',1870,'Poesía','Obras de Gustavo A. Bécquer, tomo III, Madrid, Librería de Fernando Fe, 1885. Rimas I–LXXVI.','https://es.wikisource.org/wiki/Rimas_(Bécquer,_1885)',[s],'Colección de 76 rimas de esta edición, no todas las poesías del autor. Exportación MediaWiki del rango 141–218 del escaneo; se excluye el índice.'))
works[-1]['source']='https://es.wikisource.org/wiki/Rimas_(Bécquer,_1885)'
ss=[section('Fuenteovejuna/Acto '+n,'Acto '+n,begin,end,'page') for n,begin,end in [('I','Personajes','FIN DEL ACTO PRIMERO'),('II','ACTO SEGUNDO','FIN DEL ACTO SEGUNDO'),('III','ACTO TERCERO','Fuenteovejuna da fin.')]]
works.append(work('fuenteovejuna','Fuenteovejuna','Lope de Vega',1635,'Teatro','Edición digital de Wikisource: actos I–III, revisiones 1392969, 1393035 y 1393036. Edición impresa base no indicada.','https://es.wikisource.org/wiki/Fuenteovejuna',ss,'Texto español original; incluye personajes y tres actos completos. No se atribuye una edición impresa no documentada.'))
ss=[]
for suffix,begin,end,c in [('primera','Parte Primera: Heridas en el cuerpo','no hay bien ni mal que cien años dure!',10),('segunda','Parte Segunda: Vida del hombre malo','por la primera vez de su vida.',7),('tercera','Parte Tercera: Heridas en el alma','otro momento de descanso.',7),('cuarta','Parte Cuarta: De potencia a potencia','FIN',3)]:
 ss.append(section('El capitán Veneno/Parte '+suffix,'Parte '+suffix,begin,end,'page',c))
works.append(work('capitan_veneno','El capitán Veneno','Pedro Antonio de Alarcón',1891,'Novela','Edición digital de Wikisource, cuatro partes y 27 capítulos. Obra original de 1881; edición impresa base no indicada.','https://es.wikisource.org/wiki/El_capitán_Veneno',ss,'Sin traducción ni prólogo editorial moderno. Se identifica la edición digital por las revisiones de cada parte.'))
Path('tool/free_works_batch2.json').write_text(json.dumps(works,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Validated',len(works),'additional complete editions')
