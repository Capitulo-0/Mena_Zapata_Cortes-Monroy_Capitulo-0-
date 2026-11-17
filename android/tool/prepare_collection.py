"""Bounded, manifest-driven Wikisource preparation. Never overwrites a book.
inspect fetches only explicitly listed pages, serially, >=12 seconds apart.
prepare is offline and requires reviewed section boundaries and rights records.
"""
import argparse,hashlib,json,re,time,urllib.parse,urllib.request
from pathlib import Path
from datetime import datetime,timezone
from prepare_free_works import LiteraryText as BaseLiteraryText

class LiteraryText(BaseLiteraryText):
 def handle_starttag(self,tag,attrs):
  super().handle_starttag(tag,attrs)
  a=dict(attrs)
  if tag=="img" and self.stack and self.stack[-1][1] and not self.stack[-1][2]:
   alt=a.get("alt","")
   if len(alt)==1 and alt.isalpha(): self.parts.append(alt)
 def text(self):
  return re.sub(r"\u00ac\s*\n\s*", "", super().text())
ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/'tool/free_work_sources'
OUT=ROOT/'assets/free_works'
def digest(data): return hashlib.sha256(data).hexdigest()
def key(title): return digest(title.encode())[:20]+'.json'
def extract(parsed, mode='scan'):
 parser=LiteraryText()
 html=parsed['text']['*']
 if mode=='page': html=html.replace('mw-content-ltr mw-parser-output','mw-content-ltr mw-parser-output prp-pages-output',1)
 parser.feed(html)
 text = re.sub(r'^(?:i: i\n\n)+','',parser.text())
 if mode.startswith('poem:'):
  label = mode.split(':',1)[1]
  boundaries = list(re.finditer(r'(?m)^([IVXLCDM]+)[ \t]*$',text))
  if len(boundaries) != 76: raise ValueError('Expected the reviewed 76 complete Rimas')
  index = next(i for i,m in enumerate(boundaries) if m.group(1)==label)
  text = text[boundaries[index].start():boundaries[index+1].start() if index+1<len(boundaries) else len(text)].strip()
 return parser, text

def inspect(titles):
 CACHE.mkdir(exist_ok=True)
 for title in titles:
  path=CACHE/key(title)
  if not path.exists():
   time.sleep(12)
   url='https://es.wikisource.org/w/api.php?'+urllib.parse.urlencode(dict(action='parse',page=title,prop='text|wikitext|revid',format='json',redirects=1,maxlag=5))
   req=urllib.request.Request(url,headers={'User-Agent':'Capitulo0-educational-reader/1.0 (bounded educational collection)'})
   with urllib.request.urlopen(req,timeout=45) as response: raw=response.read(4000001)
   if len(raw)>4000000: raise ValueError('Source response limit')
   data=json.loads(raw)
   if 'error' in data: raise ValueError(data['error'])
   data['retrieved_at']=datetime.now(timezone.utc).isoformat()
   path.write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
  d=json.loads(path.read_text(encoding='utf-8')); p=d['parse']; parser=LiteraryText(); parser.feed(p['text']['*']); text=parser.text()
  print(json.dumps(dict(title=title,revision=p['revid'],wikitext=p['wikitext']['*'][:7000],characters=len(text),pages=parser.pages,beginning=text[:1200],ending=text[-1200:]),ensure_ascii=True),flush=True)
def export(config):
 for spec in json.loads(Path(config).read_text(encoding='utf-8')):
  path=CACHE/key(spec['key'])
  if not path.exists():
   time.sleep(12)
   markup='<pages index="'+spec['index']+'" from='+str(spec['first'])+' to='+str(spec['last'])+' />'
   params=dict(action='parse',text=markup,title=spec['title'],contentmodel='wikitext',prop='text|wikitext',format='json',maxlag=5)
   url='https://es.wikisource.org/w/api.php?'+urllib.parse.urlencode(params)
   req=urllib.request.Request(url,headers={'User-Agent':'Capitulo0-educational-reader/1.0 (bounded educational collection)'})
   with urllib.request.urlopen(req,timeout=60) as response: raw=response.read(4000001)
   if len(raw)>4000000: raise ValueError('Export size bound')
   data=json.loads(raw)
   if 'error' in data: raise ValueError(data['error'])
   anchor=json.loads((CACHE/key(spec['anchor'])).read_text(encoding='utf-8'))['parse']
   data['parse']['revid']=anchor['revid']
   data['export_spec']=spec
   data['retrieved_at']=datetime.now(timezone.utc).isoformat()
   path.write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
  data=json.loads(path.read_text(encoding='utf-8')); parser=LiteraryText(); parser.feed(data['parse']['text']['*']); text=parser.text()
  print(json.dumps(dict(key=spec['key'],characters=len(text),pages=len(parser.pages),beginning=text[:1500],ending=text[-1500:]),ensure_ascii=True),flush=True)

def prepare(config):
 works=json.loads(Path(config).read_text(encoding='utf-8'))
 for work in works:
  target=OUT/(work['slug']+'.txt'); meta=target.with_suffix('.source.json')
  if target.exists() or meta.exists(): raise ValueError('Existing output preserved: '+str(target))
  assert work['reviewed_complete'] and work['death_year']+70<2026
  assert work['edition'] and work['rights_evidence'] and work['sections']
  records=[]; texts=[]
  for section in work['sections']:
   cached=(CACHE/key(section['page'])).read_bytes(); d=json.loads(cached); p=d['parse']
   parser,text=extract(p,section.get('extraction','scan'))
   assert (parser.pages or section.get('extraction')=='page') and len(text)>(20 if section.get('extraction','').startswith('poem:') else 500), 'No literary body'
   assert text.startswith(section['beginning']) and text.endswith(section['ending']), 'Boundary review failed'
   assert not re.search(r'(?i)texto incompleto|faltan p[áa]ginas|por transcribir',text)
   texts.append(text)
   history_title=d.get('export_spec',{}).get('anchor',section['page'])
   records.append(dict(export_spec=d.get('export_spec'),extraction=section.get('extraction','scan'),section=section['label'],page=section['page'],revision=p['revid'],source_pages=parser.pages,page_history_urls=['https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=page,action='history')) for page in parser.pages],characters=len(text),beginning=text[:100],ending=text[-180:],text_sha256=digest(text.encode()),source_snapshot_sha256=digest(cached),retrieved_at=d['retrieved_at'],permanent_url='https://es.wikisource.org/w/index.php?oldid='+str(p['revid']),history_url='https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=history_title,action='history'))))
  body='\n\n'.join(texts)
  credits='\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n'+work['title']+' — '+work['author']+'\n'+work['edition']+'\nObra original de dominio público en Chile; autor fallecido en '+str(work['death_year'])+'.\nTranscripción: comunidad de Wikisource en español. Conversión por Capítulo 0.\nTranscripción y conversión: CC BY-SA 4.0 cuando corresponda.\nhttps://creativecommons.org/licenses/by-sa/4.0/\nCambios: HTML a UTF-8; eliminación de navegación, estilos y paginación; normalización de espacios. Sin traducción, resumen ni ilustraciones.\n'
  for r in records: credits+=r['section']+': '+r['permanent_url']+'\nHistorial y colaboradores: '+r['history_url']+'\n'
  if work.get('parent_work_id'): credits+='Fuente de la edición y del poema: '+work['source']+'\nPoema autónomo completo, incluido también en Rimas. Revisión ancla del índice; la instantánea HTML exacta y los historiales de sus páginas se conservan en el manifiesto.\n'
  data=(body+credits).encode(); units=len((body+credits).encode('utf-16-le'))//2
  assert len(data)<=8388608 and units<=2097152, 'Reader limits; never truncate'
  m={**work,'id':'wikisource-es-'+work['slug'],'language':'es','source':work.get('source') or 'https://es.wikisource.org/wiki/'+urllib.parse.quote(work['sections'][0]['page'].replace(' ','_'),safe='/'),'sections':records,'bytes':len(data),'utf16_units':units,'sha256':digest(data),'literary_body_sha256':digest(body.encode()),'license':'CC BY-SA 4.0 (transcripción/conversión cuando corresponda); original dominio público','license_url':'https://creativecommons.org/licenses/by-sa/4.0/','complete':True}
  OUT.mkdir(exist_ok=True); target.write_bytes(data); meta.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
  print(work['slug'],len(data),m['sha256'],flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser(); p.add_argument('mode',choices=['inspect','prepare','export']); p.add_argument('inputs',nargs='+'); a=p.parse_args()
 if a.mode=='inspect': inspect(a.inputs)
 elif a.mode=='export':
  for config in a.inputs: export(config)
 else:
  for config in a.inputs: prepare(config)
