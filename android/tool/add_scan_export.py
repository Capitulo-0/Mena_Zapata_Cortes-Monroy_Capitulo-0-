from pathlib import Path
p=Path('tool/prepare_collection.py');s=p.read_text(encoding='utf-8'); pos=s.index('def prepare(config):')
s=s[:pos]+'''def export(config):
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

'''+s[pos:]
s=s.replace("choices=['inspect','prepare']","choices=['inspect','prepare','export']")
s=s.replace(" if a.mode=='inspect': inspect(a.inputs)\n else:"," if a.mode=='inspect': inspect(a.inputs)\n elif a.mode=='export':\n  for config in a.inputs: export(config)\n else:")
s=s.replace("'https://es.wikisource.org/wiki/'+urllib.parse.quote(work['sections'][0]['page'].replace(' ','_'),safe='/')","work.get('source') or 'https://es.wikisource.org/wiki/'+urllib.parse.quote(work['sections'][0]['page'].replace(' ','_'),safe='/')")
s=s.replace("records.append(dict(section=section['label']", "records.append(dict(export_spec=d.get('export_spec'),section=section['label']")
p.write_text(s,encoding='utf-8')
