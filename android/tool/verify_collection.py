import json,hashlib,re
from pathlib import Path
from prepare_collection import CACHE,key,LiteraryText,extract
count=0
ids=set()
hashes=set()
for path in Path('assets/free_works').glob('*.source.json'):
 m=json.loads(path.read_text(encoding='utf-8')); assert m['id'] not in ids; ids.add(m['id']); assert m['sha256'] not in hashes; hashes.add(m['sha256']); raw=path.with_suffix('').with_suffix('.txt').read_bytes(); t=raw.decode('utf-8'); assert len(raw)==m['bytes']; assert hashlib.sha256(raw).hexdigest()==m['sha256']; assert len(t.encode('utf-16-le'))//2==m['utf16_units']; assert len(raw)<=8388608 and m['utf16_units']<=2097152
 body=t.split('\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n')[0]; assert hashlib.sha256(body.encode()).hexdigest()==m['literary_body_sha256']
 pos=0
 for s in m['sections']:
  start=t.index(s['beginning'],pos); part=t[start:start+s['characters']]; assert part.endswith(s['ending']); assert hashlib.sha256(part.encode()).hexdigest()==s['text_sha256']; pos=start+len(part)
  if 'source_snapshot_sha256' in s:
   cached=(CACHE/key(s['page'])).read_bytes(); assert hashlib.sha256(cached).hexdigest()==s['source_snapshot_sha256']; p=json.loads(cached)['parse']; parser,extracted=extract(p,s.get('extraction','scan')); assert extracted==part
   if m.get('complete'):
    assert m['reviewed_complete']
    headings=next((x.get('reviewed_headings') for x in m.get('sections',[]) if x['page']==s['page']),None)
    for config_file in Path('tool').glob('free_works_batch*.json'):
     for work in json.loads(config_file.read_text(encoding='utf-8')):
      if work['slug']==m['slug']:
       configured=next(x for x in work['sections'] if x['page']==s['page'])
       headings=configured.get('reviewed_headings', work.get('internal_sections',[]))
    cursor=0
    for heading in headings or []:
     found=part.index(heading,cursor); cursor=found+len(heading)
 assert 'https://creativecommons.org/licenses/by-sa/4.0/' in t
 count+=1
print('PASS: full UTF-8, SHA-256, body hash, ordered sections, preserved boundaries and reader limits;',count,'complete works')
