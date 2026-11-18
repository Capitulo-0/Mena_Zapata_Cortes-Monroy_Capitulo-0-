# Biblioteca gratuita: edición y crecimiento

Colección revisada: 15 obras completas en español. Los dos assets iniciales y sus manifiestos no se regeneran.

## Preparación (Python 3, biblioteca estándar)

Desde android:

- `python tool/prepare_collection.py inspect "Título explícito"`: consulta una página concreta de la API MediaWiki y conserva respuesta, revisión y fecha en `tool/free_work_sources`. No rastrea enlaces. Doce segundos entre solicitudes nuevas. Ante HTTP 403/429/maxlag u otro error se detiene: respetar Retry-After y revisar antes de volver a consultar; nunca cambiar identidad ni eludir bloqueos.
- `python tool/prepare_collection.py export tool/free_work_exports.json`: exportación MediaWiki de un rango explícito de páginas del escaneo. No es WSexport. No se requiere este servicio durante lectura.
- Revisar título, autor, edición, derechos en Chile, traducción/editorial, TODOS los capítulos, continuidad, inicio y final. Registrar la decisión en un manifiesto JSON como `free_works_batch1.json` o `free_works_batch2.json`. No basta una página de índice ni que el primer y último párrafo existan. Un escaneo puede contener páginas sin transcribir.
- `python tool/prepare_collection.py prepare archivo_nuevo.json`: conversión offline de fuentes ya conservadas. Se niega a sobrescribir TXT o manifiestos existentes. Los lotes de esta entrega son evidencia reproducible, no deben ejecutarse sobre sus salidas ya presentes.
- `python tool/verify_collection.py`: verificación offline SHA-256 del asset, cuerpo, secciones y respuesta fuente; UTF-8, tamaño UTF-16, orden, límites, IDs y textos distintos. Ejecutar sin `-O` (utiliza aserciones).
- `python tool/generate_free_catalog.py`: genera SOLO metadatos pequeños en `prepared_free_works.dart`, después de verificar integridad. No incluye el cuerpo en Dart.
- `flutter test --no-pub`: incluye la auditoría Python anterior; Python 3 debe estar en PATH. No añade paquetes Flutter.

## Evidencia y límites editoriales

Las instantáneas JSON preservan el HTML realmente recibido. Las revisiones de las páginas principales no congelan las revisiones de páginas transcluidas; por ello también se registra SHA-256 de la instantánea exacta. En las exportaciones de escaneo, `export_spec.anchor` identifica el índice cuya revisión se registra: NO se presenta ese número como revisión de cada página literaria. Los rangos de páginas están declarados.

Los diez relatos de Bécquer son obras breves autónomas completas, no una edición íntegra de todas las Leyendas ni capítulos sueltos de una novela. Rimas contiene I–LXXVI de la edición de 1885, no todo poema publicado por el autor. Fuenteovejuna y El capitán Veneno usan la edición digital identificada por revisiones: la edición impresa base no está documentada y no se inventa. No se incluyen traducciones modernas ni prólogos editoriales ajenos. Pueden existir erratas de transcripción; integridad no equivale a una edición crítica corregida.

Se conservaron los cuerpos literarios de las fuentes. El conversor elimina navegación, estilos y paginación, conserva letras capitulares representadas como imágenes con alt alfabético, normaliza espacios y une cortes con guion discrecional. Atribución comunitaria, autor original, enlace de licencia e historiales figuran al final de cada texto y en los manifiestos. Las instantáneas públicas también se reutilizan bajo CC BY-SA 4.0 cuando corresponda: fuente y revisión se conservan dentro de cada JSON; son material de preparación, NO assets de ejecución.

Dominio público original en Chile: Ley 17.336, artículos 10 y 11; autores fallecidos en 1870, 1635 y 1891, ampliamente fuera del plazo de vida más 70 años. Se mantienen nombres y texto, respetando atribución e integridad. Reutilización de transcripción/conversión: CC BY-SA 4.0 cuando corresponda, con atribución, cambios indicados y compartir igual. Fuentes de comprobación:

- https://www.bcn.cl/leychile/navegar?idNorma=28933
- https://www.propiedadintelectual.gob.cl/faq
- https://es.wikisource.org/wiki/Wikisource:Derechos_de_autor
- https://creativecommons.org/licenses/by-sa/4.0/

Descartadas: Marianela (1878), cuyo rango exportado tiene lagunas de transcripción; páginas de índices y ediciones enlazadas pero inexistentes. La primera exportación corta de Rimas no se incorporó: se revisó el cierre y se amplió explícitamente hasta la última estrofa. Las fuentes descartadas solo permanecen como evidencia en tool, nunca como lectura disponible.

## Contrato actual

`FreeWork` identifica una edición, independientemente de Gutendex. `isComplete` es falso por defecto: tener una ruta de asset no basta. Solo las ediciones revisadas se marcan completas. `AssetReaderSource` abre únicamente assets UTF-8 aprobados; no descarga ni persiste. Lista, búsqueda por título/autor y filtro de clasificación verificada trabajan con metadatos. El cuerpo se carga al pulsar Leer ahora. El lector compartido permanece intacto; límites 8 MiB y 2.097.152 unidades UTF-16 por obra. No truncar ni dividir una obra para ocultar esos límites.

## Metadatos futuros (diseño, no servicio implementado)

Mantener un catálogo versionado y paginado de metadatos pequeños:

```json
{
  "schemaVersion": 1,
  "id": "edicion-estable-independiente-del-proveedor",
  "title": "Título", "author": "Autor", "language": "es",
  "genre": "clasificación verificada o null",
  "edition": "edición y responsables",
  "completeness": "reviewed-complete",
  "provenance": {"sourceUrl": "https://fuente-autorizada/obra", "revision": "revisión", "license": "licencia", "attribution": "créditos", "rightsChileEvidence": "evidencia"},
  "content": {"kind": "authorizedDownload", "version": "versión-inmutable", "url": "https://servicio-propio/edicion.txt", "sha256": "huella-esperada", "bytes": 12345, "utf16Units": 12000, "encoding": "utf-8"}
}
```

Actualmente `content.kind` equivale a `bundledAsset` con `assetPath`, y toda lectura pasa por AssetReaderSource. En el futuro un adaptador autorizado resolvería una edición descargada a `ReaderSource.utf8`, conservando el lector. `available` no debe significar URL existente: distinguir descargable, descargando, verificada en caché y error. Descargar solo al abrir; HTTPS y dominios permitidos; verificar licencia vigente, bytes, UTF-8, UTF-16 y SHA antes de lectura; escritura temporal y promoción atómica; cancelación, reintento explícito, cuota/LRU, borrado de caché y versiones inmutables. Mantener créditos offline. Obras mayores requerirían un contrato nuevo de lectura por segmentos, validado como obra completa, sin fraccionamiento silencioso.

Para miles de obras faltan alojamiento autorizado con licencias y atribuciones, catálogo paginado/indexado en servidor, autenticidad del manifiesto, política de actualizaciones y retirada, almacenamiento local por plataforma, conectividad/errores, cacheado con cuotas y pruebas de integridad y rendimiento. Nada de ello se implementa en esta entrega. Gutendex sigue siendo consulta remota opcional y no determina la disponibilidad local.
