from pathlib import Path
import json,urllib.parse,hashlib
p=Path('tool/prepare_collection.py');s=p.read_text(encoding='utf-8');s=s.replace("   texts.append(text)\n   records.append", "   texts.append(text)\n   history_title=d.get('export_spec',{}).get('anchor',section['page'])\n   records.append")
s=s.replace("dict(title=section['page'],action='history')", "dict(title=history_title,action='history')")
p.write_text(s,encoding='utf-8')
p=Path('assets/free_works/rimas_1885.source.json');m=json.loads(p.read_text(encoding='utf-8'));r=m['sections'][0];anchor=r['export_spec']['anchor'];old=r['history_url'];r['history_url']='https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=anchor,action='history'));r['revision_role']='export-index-anchor'
r['page_history_urls']=['https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode(dict(title=page,action='history')) for page in r['source_pages']]
asset=Path('assets/free_works/rimas_1885.txt');text=asset.read_text(encoding='utf-8');body=text.split('\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n')[0];assert hashlib.sha256(body.encode()).hexdigest()==m['literary_body_sha256']
text=text.replace(old,r['history_url'])
text+='Fuente de la colección: '+m['source']+'\nLa revisión indicada corresponde al índice del escaneo; el HTML exportado se conserva con SHA-256 en el manifiesto.\nContribuciones a las páginas transcritas:\n'+'\n'.join(r['page_history_urls'])+'\n'
data=text.encode();asset.write_bytes(data);m.update(bytes=len(data),utf16_units=len(text.encode('utf-16-le'))//2,sha256=hashlib.sha256(data).hexdigest());p.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Rimas: atribución corregida; cuerpo literario intacto;',len(data),'bytes')
