"""Prepare the three verified jornadas of one Wikisource scan; no crawling."""
import hashlib
import json
import re
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from prepare_free_works import LiteraryText, OUT

def fetch(title):
    url='https://es.wikisource.org/w/api.php?'+urllib.parse.urlencode({'action':'parse','page':title,'prop':'text|revid','format':'json'})
    with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Capitulo0-educational-reader/1.0'}),timeout=30) as response:
        raw=response.read(2000001)
    if len(raw)>2000000: raise ValueError('Source too large')
    parsed=json.loads(raw)['parse']
    parser=LiteraryText()
    parser.feed(parsed['text']['*'])
    return parsed,parser

def main():
    target=OUT/'vida_sueno.txt'
    meta=OUT/'vida_sueno.source.json'
    if target.exists() or meta.exists(): raise SystemExit('Existing output preserved')
    title='La vida es sueño'
    parsed,parser=fetch(title)
    main_text=parser.text()
    start=main_text.index('PERSONAS')
    end=re.search(r'La escena.*?campo\.',main_text,re.S)
    if end is None: raise ValueError('Missing persons and stage context')
    persons=main_text[start:end.end()]
    body=[persons]
    records=[]
    for suffix,label in [('I','Jornada primera'),('II','Jornada segunda'),('III','Jornada tercera')]:
        page=title+'/'+suffix
        parsed,parser=fetch(page)
        text=parser.text()
        if len(text)<20000 or not parser.pages: raise ValueError('Incomplete jornada')
        body.append(text)
        records.append({'section':label,'page':page,'revision':parsed['revid'],
            'url':'https://es.wikisource.org/wiki/'+urllib.parse.quote(page.replace(' ','_'),safe='/'),
            'permanent_url':'https://es.wikisource.org/w/index.php?oldid='+str(parsed['revid']),
            'history_url':'https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode({'title':page,'action':'history'}),
            'source_pages':parser.pages,'characters':len(text),'beginning':text[:100],'ending':text[-180:],
            'text_sha256':hashlib.sha256(text.encode('utf-8')).hexdigest()})
        print(suffix,len(text),len(parser.pages),'ending',ascii(text[-120:]))
    literary='\n\n'.join(body)
    pages={int(p.rsplit('/',1)[1]) for entry in records for p in entry['source_pages']}
    if pages != set(range(9,80)): raise ValueError('Incomplete scan coverage: '+str(sorted(pages)))
    if 'perdon' not in literary[-500:].lower(): raise ValueError('Missing closing speech')
    credit=('\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n'
        'La vida es sueño — Pedro Calderón de la Barca (1600–1681).\n'
        'Ejemplar: La vida es sueño.djvu, Wikisource. Portada: Insel-Verlag, Leipzig. Fecha no confirmada.\n'
        'El índice de Wikisource indica 1900/Pandora; se conserva la referencia al escaneo sin resolver esa discrepancia editorial.\n'
        'Fuente: https://es.wikisource.org/wiki/La_vida_es_sueño\n'
        'Escaneo: https://es.wikisource.org/wiki/Índice:La_vida_es_sueño.djvu\n'
        'Obra original de dominio público. Transcripción: comunidad de Wikisource en español.\n'
        'Transcripción y conversión: CC BY-SA 4.0 cuando corresponda.\n'
        'https://creativecommons.org/licenses/by-sa/4.0/\n'
        'Conversión de HTML a texto UTF-8 por Capítulo 0: personajes, localización escénica y las tres jornadas completas.\n'
        'Sin biografía editorial, navegación, estilos ni marcadores de página. Espacios normalizados; sin traducción ni resumen.\n'
        'Se conservan texto, escenas y versos de la transcripción; no la tipografía ni las columnas del impreso.\n')
    for entry in records:
        credit+=entry['section']+': '+entry['permanent_url']+'\nHistorial: '+entry['history_url']+'\n'
    complete=literary+credit
    data=complete.encode('utf-8')
    if len(data)>8388608 or len(complete.encode('utf-16-le'))//2>2097152: raise ValueError('Reader limits')
    manifest={'id':'wikisource-es-vida-sueno-djvu','title':title,'author':'Pedro Calderón de la Barca','language':'es',
        'edition':'Ejemplar La vida es sueño.djvu; portada Insel-Verlag, Leipzig; fecha no confirmada',
        'source':'https://es.wikisource.org/wiki/La_vida_es_sueño',
        'retrieved_at':datetime.now(timezone.utc).isoformat(),'license':'CC BY-SA 4.0 para transcripción/conversión, cuando corresponda; obra original de dominio público',
        'license_url':'https://creativecommons.org/licenses/by-sa/4.0/','sections':records,
        'persons_source':'https://es.wikisource.org/w/index.php?oldid=1637987',
        'bytes':len(data),'utf16_units':len(complete.encode('utf-16-le'))//2,'sha256':hashlib.sha256(data).hexdigest(),
        'literary_body_sha256':hashlib.sha256(literary.encode('utf-8')).hexdigest(),
        'scan_pages':{'first':9,'last':79,'count':len(pages)},
        'notes':'La atribución original (autor fallecido en 1681) se mantiene. Transcripción corregida, no totalmente validada en Wikisource. La ficha no afirma una fecha editorial no confirmada.'}
    target.write_bytes(data)
    meta.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('TOTAL',len(data),'bytes',len(literary),'literary chars',manifest['sha256'])
if __name__=='__main__': main()