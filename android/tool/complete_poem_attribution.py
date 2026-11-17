from pathlib import Path
import json,hashlib,urllib.parse
p=Path('tool/prepare_collection.py');s=p.read_text(encoding='utf-8');s=s.replace('source_pages=parser.pages,characters=', "source_pages=parser.pages,page_history_urls=['https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=page,action='history')) for page in parser.pages],characters=")
needle="  data=(body+credits).encode();";assert needle in s
s=s.replace(needle,"  if work.get('parent_work_id'): credits+='Fuente de la edición y del poema: '+work['source']+'\\nPoema autónomo completo, incluido también en Rimas. Revisión ancla del índice; la instantánea HTML exacta y los historiales de sus páginas se conservan en el manifiesto.\\n'\n"+needle)
p.write_text(s,encoding='utf-8')
for path in Path('assets/free_works').glob('rima_1885_*.source.json'):
 m=json.loads(path.read_text(encoding='utf-8'));section=m['sections'][0];section['revision_role']='export-index-anchor';section['page_history_urls']=['https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=page,action='history')) for page in section['source_pages']]
 asset=path.with_suffix('').with_suffix('.txt');text=asset.read_text(encoding='utf-8');body=text.split('\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n')[0];assert hashlib.sha256(body.encode()).hexdigest()==m['literary_body_sha256']
 text+='Fuente de la edición y del poema: '+m['source']+'\nPoema autónomo completo, incluido también en Rimas. Revisión ancla del índice; la instantánea HTML exacta y los historiales de sus páginas se conservan en el manifiesto.\n'
 data=text.encode();asset.write_bytes(data);m.update(bytes=len(data),utf16_units=len(text.encode('utf-16-le'))//2,sha256=hashlib.sha256(data).hexdigest());path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('35 poems: attribution completed, original literary bodies unchanged')
