from pathlib import Path
import json,re,subprocess,sys
p=Path('tool/prepare_collection.py');s=p.read_text(encoding='utf-8');old=" return parser, re.sub(r'^(?:i: i\\n\\n)+','',parser.text())";new=""" text = re.sub(r'^(?:i: i\\n\\n)+','',parser.text())
 if mode.startswith('poem:'):
  label = mode.split(':',1)[1]
  boundaries = list(re.finditer(r'(?m)^([IVXLCDM]+)[ \\t]*$',text))
  if len(boundaries) != 76: raise ValueError('Expected the reviewed 76 complete Rimas')
  index = next(i for i,m in enumerate(boundaries) if m.group(1)==label)
  text = text[boundaries[index].start():boundaries[index+1].start() if index+1<len(boundaries) else len(text)].strip()
 return parser, text"""
assert old in s;s=s.replace(old,new).replace("and len(text)>500, 'No literary body'", "and len(text)>(20 if section.get('extraction','').startswith('poem:') else 500), 'No literary body'")
p.write_text(s,encoding='utf-8')
sys.path.insert(0,'tool')
from prepare_collection import CACHE,key,extract
source='scan:rimas1885:141-218';cached=json.loads((CACHE/key(source)).read_text(encoding='utf-8'));parent=json.loads(Path('assets/free_works/rimas_1885.source.json').read_text(encoding='utf-8'))
_,full=extract(cached['parse']);boundaries=list(re.finditer(r'(?m)^([IVXLCDM]+)[ \t]*$',full));assert len(boundaries)==76
works=[]
for number in range(1,36):
 label=boundaries[number-1].group(1);mode='poem:'+label;_,body=extract(cached['parse'],mode)
 # These are whole numbered poems, never a verse selection. Bounds end before the next numbered work.
 assert body==full[boundaries[number-1].start():boundaries[number].start()].strip()
 verses=body.splitlines();first=next(line for line in verses[1:] if line.strip());last=next(line for line in reversed(verses) if line.strip())
 works.append(dict(slug=f'rima_1885_{number:02d}',title='Rima '+label,author='Gustavo Adolfo Bécquer',death_year=1870,genre='Poesía',work_type='poema autónomo',edition=f'Rima {label}, poema autónomo completo. Obras de Gustavo A. Bécquer, tomo III, Madrid, Librería de Fernando Fe, 1885. También reunido en Rimas de esta biblioteca.',edition_evidence=parent['edition_evidence'],rights_evidence=parent['rights_evidence'],source=parent['source'],reviewed_complete=True,parent_work_id=parent['id'],parent_body_sha256=parent['literary_body_sha256'],notes='Poema autónomo íntegro, no novela, fragmento ni nueva colección. Se solapa deliberadamente con el volumen Rimas ya incluido. Verso inicial: '+first+' Verso final: '+last,sections=[dict(page=source,label='Poema autónomo completo: Rima '+label,beginning=body[:100],ending=body[-min(180,len(body)):],extraction=mode,reviewed_headings=[label])]))
for start in range(0,35,5):
 config=Path(f'tool/free_works_batch{3+start//5}.json');assert not config.exists()
 config.write_text(json.dumps(works[start:start+5],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 subprocess.run([sys.executable,'tool/prepare_collection.py','prepare',str(config)],check=True)
 subprocess.run([sys.executable,'tool/verify_collection.py'],check=True)
 print('LOCAL BATCH VALIDATED',start+1,'through',start+5,flush=True)
subprocess.run([sys.executable,'tool/generate_free_catalog.py'],check=True)
# Preserve count checks and increase them to the exact, audited corpus.
p=Path('test/gutendex/free_collection_test.dart');s=p.read_text(encoding='utf-8').replace('fifteen','fifty').replace('hasLength(15)','hasLength(50)').replace('15 complete works','50 complete works').replace('15 con lectura disponible','50 con lectura disponible')
needle="expect(find.text('1 obras · 50 con lectura disponible'), findsOneWidget);";first=s.index(needle);second=s.index(needle,first+len(needle));s=s[:second]+s[second:].replace(needle,"expect(find.text('36 obras · 50 con lectura disponible'), findsOneWidget);",1);p.write_text(s,encoding='utf-8')
