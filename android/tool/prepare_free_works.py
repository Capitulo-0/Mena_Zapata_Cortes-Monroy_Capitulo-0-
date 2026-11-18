"""Prepare one explicitly selected complete public-domain work, not a crawler.
Standard library only. Run from android: python tool/prepare_free_works.py
Existing outputs are preserved; review any new source revision separately.
"""
import hashlib
import json
import re
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/free_works'
BASE = 'El Lazarillo de Tormes'
SECTIONS = ['Prólogo', 'Tratado primero', 'Tratado segundo', 'Tratado tercero',
            'Tratado cuarto', 'Tratado quinto', 'Tratado sexto', 'Tratado séptimo']

class LiteraryText(HTMLParser):
    void = {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}
    blocks = {'p','div','h1','h2','h3','h4','li','tr','blockquote','section'}
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.parts = []
        self.pages = []
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        classes = set(a.get('class','').split())
        active = ('prp-pages-output' in classes) or (self.stack and self.stack[-1][1])
        skip = bool(self.stack and self.stack[-1][2]) or tag in {'script','style'} or bool(
            classes & {'ws-noexport','noprint','pagenum','mw-editsection'})
        if 'pagenum' in classes and 'title' in a:
            self.pages.append(a['title'])
        if active and not skip and (tag in self.blocks or tag == 'br'):
            self.parts.append('\n')
        if tag not in self.void:
            self.stack.append((tag, bool(active), skip))
    def handle_endtag(self, tag):
        for i in range(len(self.stack)-1,-1,-1):
            if self.stack[i][0] == tag:
                if self.stack[i][1] and not self.stack[i][2] and tag in self.blocks:
                    self.parts.append('\n')
                del self.stack[i:]
                break
    def handle_data(self, data):
        if self.stack and self.stack[-1][1] and not self.stack[-1][2]:
            self.parts.append(data)
    def text(self):
        lines = [re.sub(r'[ \t\r\f\v\u00a0]+',' ',line).strip() for line in ''.join(self.parts).split('\n')]
        return re.sub(r'\n{3,}','\n\n','\n'.join(lines)).strip()

def main():
    target = OUT / 'lazarillo_1921.txt'
    manifest_path = OUT / 'lazarillo_1921.source.json'
    if target.exists() or manifest_path.exists():
        raise SystemExit('Output exists; preserving it. Review provenance before regeneration.')
    records = []
    texts = []
    for name in SECTIONS:
        title = BASE + '/' + name
        url = 'https://es.wikisource.org/w/api.php?' + urllib.parse.urlencode({
            'action':'parse','page':title,'prop':'text|revid','format':'json'})
        request = urllib.request.Request(url, headers={'User-Agent':'Capitulo0-educational-reader/1.0'})
        with urllib.request.urlopen(request,timeout=30) as response:
            raw = response.read(2000001)
        if len(raw)>2000000: raise ValueError('Source response exceeds preparation bound')
        parsed = json.loads(raw)['parse']
        parser = LiteraryText()
        parser.feed(parsed['text']['*'])
        text = parser.text()
        if len(text)<500 or not parser.pages: raise ValueError('Missing literary section: '+name)
        texts.append(text)
        records.append({'section':name,'title':title,'revision':parsed['revid'],
            'url':'https://es.wikisource.org/wiki/'+urllib.parse.quote(title.replace(' ','_'),safe='/'),
            'permanent_url':'https://es.wikisource.org/w/index.php?oldid='+str(parsed['revid']),
            'history_url':'https://es.wikisource.org/w/index.php?'+urllib.parse.urlencode({'title':title,'action':'history'}),
            'text_sha256':hashlib.sha256(text.encode('utf-8')).hexdigest(),
            'characters':len(text),'source_pages':parser.pages,
            'beginning':text[:100],'ending':text[-160:]})
        print(name.encode('ascii','backslashreplace').decode(),len(text),len(parser.pages))
    body = '\n\n'.join(texts)
    assert 'Yo por bien tengo' in body
    assert len(body)>100000 and len(records)==8
    credits = ('\n\nPROCEDENCIA Y CONDICIONES DE ESTA COPIA\n'
        'El Lazarillo de Tormes — Anónimo. Edición: Madrid, Tipográfica Renovación / Calpe, 1921.\n'
        'Obra literaria de dominio público. Transcripción: comunidad de Wikisource en español.\n'
        'Fuente: https://es.wikisource.org/wiki/El_Lazarillo_de_Tormes\n'
        'Índice de la edición: https://es.wikisource.org/wiki/Índice:El_Lazarillo_de_Tormes_(1921).pdf\n'
        'Transcripción y conversión distribuidas bajo CC BY-SA 4.0, en lo que sea aplicable.\n'
        'Licencia: https://creativecommons.org/licenses/by-sa/4.0/\n'
        'Conversión por Capítulo 0: unión ordenada del prólogo y siete tratados; eliminación de navegación,\n'
        'estilos y marcadores de página; normalización de espacios. Sin traducción ni resumen.\n'
        'Las cursivas y otras características tipográficas no se conservan en texto plano.\n'
        'La atribución y el historial de contribuciones de cada sección figuran en el manifiesto adjunto.\n')
    for entry in records:
        credits += entry['section']+': '+entry['permanent_url']+'\nHistorial: '+entry['history_url']+'\n'
    complete = body + credits
    data = complete.encode('utf-8')
    if len(data)>8*1024*1024 or len(complete.encode('utf-16-le'))//2>2097152:
        raise ValueError('Reader limits exceeded')
    manifest = {'id':'wikisource-es-lazarillo-1921','title':BASE,'author':'Anónimo','language':'es',
        'edition':'Madrid: Tipográfica Renovación / Editorial Calpe, Colección Universal n.º 510, 1921',
        'source':'https://es.wikisource.org/wiki/El_Lazarillo_de_Tormes',
        'retrieved_at':datetime.now(timezone.utc).isoformat(), 'license':'CC BY-SA 4.0 (transcripción/conversión, cuando corresponda); obra original de dominio público',
        'license_url':'https://creativecommons.org/licenses/by-sa/4.0/', 'sections':records,
        'bytes':len(data),'utf16_units':len(complete.encode('utf-16-le'))//2,
        'sha256':hashlib.sha256(data).hexdigest(),'literary_body_sha256':hashlib.sha256(body.encode('utf-8')).hexdigest(),
        'changes':'HTML a texto UTF-8, sin navegación ni estilos; espacios normalizados; créditos añadidos después de la obra. Sin cubierta ni prólogo editorial del volumen: texto literario íntegro (prólogo original y siete tratados).'}
    OUT.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('TOTAL',len(data),'bytes',len(body),'literary characters','sha256',manifest['sha256'])

if __name__ == '__main__': main()