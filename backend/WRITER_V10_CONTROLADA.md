# Writer V10: verificación y aplicación controlada

Este procedimiento sustituye la preparación pendiente de WRITER_NEON_JDBC_Y_V10.md.
El usuario ya confirmó conexión JDBC real a la rama perfil-v9-notifications, V10 no
registrada y ausencia de writer_stories. Este nuevo preflight verifica además
historial/checksums y esquema. No inicia Spring Boot.

## 1. Ejecutar AHORA: solo verificación previa

En la MISMA PowerShell de backend que ya contiene DB_URL, DB_USERNAME y DB_PASSWORD:

```powershell
$env:WRITER_NEON_BRANCH = 'perfil-v9-notifications'
$env:WRITER_NEON_EXPECTED_HOST = [System.Net.NetworkCredential]::new('', (Read-Host 'Pega solo el hostname de Connect de Neon V9, sin URL ni puerto' -AsSecureString)).Password
mvn -o "-Dtest=WriterV10ControlledMigrationTests" "-Dwriter.v10.mode=preflight" test
```

El hostname se introduce oculto. Copiarlo desde Connect de perfil-v9-notifications;
NO calcularlo ni copiarlo de DB_URL. Debe ser el mismo endpoint exacto (incluido
-pooler si corresponde). No introducir usuario, URL JDBC ni contraseña en ese campo.
La comparación es exacta; rechaza mayúsculas, espacios, protocolo, puerto o ruta.

Las credenciales se leen dentro de la JVM iniciada desde esta PowerShell. No se
pasan como argumentos ni se imprimen. No usar Maven -X ni trazas JDBC.
No requiere psql, Docker, instalaciones ni servicios locales nuevos.

Sin la propiedad writer.v10.mode, el test operacional se OMITE; no significa éxito.
El modo preflight jamás llama migrate. Usa conexiones con readOnlyMode=always,
readOnly=true, verificación server-side de transaction_read_only=on y protección
contra desactivar readOnly/unwrap. Las consultas explícitas son SELECT. Flyway
info/validate y Hibernate SchemaValidator usan también ese datasource protegido.
Solo hay cambios de sesión/conexión, no DDL, DML ni historial de migraciones.
Los artefactos locales de Maven/Surefire sí se actualizan normalmente.

## 2. Qué debe mostrar la verificación real

Ejemplo de salida esperada; NO es un resultado obtenido por Codex en Neon:

```text
WRITER_V10: PREFLIGHT_SOLO_LECTURA=OK
WRITER_V10: HOST_INDEPENDIENTE_COINCIDE=OK
WRITER_V10: RAMA_DECLARADA=perfil-v9-notifications
WRITER_V10: V1_A_V9_Y_CHECKSUMS=OK
WRITER_V10: UNICA_PENDIENTE=V10
WRITER_V10: ESQUEMA_REQUERIDO=OK
WRITER_V10: WRITER_STORIES=NO_EXISTE
WRITER_V10: HUELLA=<64 caracteres hexadecimales>
WRITER_V10: APTO_PARA_SOLICITAR_AUTORIZACION=SI
WRITER_V10: MIGRACIONES_EJECUTADAS=NINGUNA
```

Compartir únicamente las líneas WRITER_V10 y BUILD SUCCESS/FAILURE.
La HUELLA no contiene credenciales: vincula destino/configuración de conexión,
rama y versiones/scripts/checksums Flyway. Guardarla para el paso autorizado.

Si aparece RESULTADO=BLOQUEADO, no aplicar V10 ni reparar/baselinear el historial.
El código identifica la condición sin imprimir causas SQL, URL, usuario o secretos.
Ejemplos: HOST_NO_COINCIDE_ABORTADO, V1_A_V9_NO_VALIDAS, FLYWAY_VALIDACION_FALLIDA,
ESQUEMA_ENTIDADES_INCOMPATIBLE, OBJETOS_WRITER_PREEXISTENTES o
PERMISOS_MIGRACION_INSUFICIENTES. Revisar el resultado antes de continuar.

El nombre de rama es una declaración explícita del operador; JDBC no expone una
prueba independiente del nombre de rama Neon. La garantía de destino depende del
hostname copiado de Connect de la rama correcta, que el usuario debe confirmar.
El ejecutor no consulta la API de administración de Neon ni inventa esa comprobación.

## 3. Guardas implementadas

- Rama declarada exactamente perfil-v9-notifications; production rechazada.
- Host esperado separado y obligatorio; coincidencia exacta con DB_URL; puerto
  predeterminado o 5432. Se reutiliza la validación JDBC/TLS del verificador anterior.
- Flyway usa exclusivamente el datasource suministrado, esquema public, tabla
  flyway_schema_history y classpath:db/migration. No carga archivos de configuración
  externos ni envVars de Flyway.
- V1 a V9 deben estar SUCCESS; todas presentes, sin duplicados, baseline, fallos,
  missing, out-of-order, repeatables ni versiones extra/futuras.
- V10 debe ser la única pendiente y llamarse V10__create_writer_stories.sql.
- validateWithResult verifica checksums, tipos y descripciones del historial.
  Se permite pending en validate porque V10 está pendiente; checkPlan exige
  independientemente que sea exactamente V10 y ninguna otra.
- users.id debe ser BIGINT NOT NULL y PK de una sola columna.
- Se validan tablas/columnas/tipos de las cinco entidades preexistentes mediante
  Hibernate SchemaValidator; no se construye SessionFactory ni se genera DDL.
- Se rechazan restricciones no validadas e índices inválidos de public.
- Se comprueban permisos de schema USAGE/CREATE, REFERENCES sobre users y
  SELECT/INSERT/UPDATE sobre el historial. Comprobar permisos no ejecuta escrituras.
- writer_stories no debe existir, ni los nombres de su secuencia/índices previstos.
- La validación no pretende demostrar la corrección de todos los datos o reglas
  funcionales del sistema: comprueba migraciones y estructura requerida.
- Flyway/driver/Hibernate tienen logs sensibles silenciados; el wrapper reemplaza
  excepciones por códigos fijos, sin causas originales.
- La aplicación repite el preflight y exige la misma huella antes de crear un
  datasource de escritura. Falta de consentimiento se rechaza antes de conectar.
- Callback adicional permite exclusivamente V10 con el script y checksum verificados.
- target=10; cleanDisabled=true; createSchemas=false; baselineOnMigrate=false;
  outOfOrder=false; validateOnMigrate=true; executeInTransaction=true; group=true;
  mixed=false; sin sustitución de placeholders ni callbacks automáticos.
- No hay llamadas a repair, baseline, undo ni edición manual del historial.

## 4. Aplicación: PREPARADA, NO EJECUTAR TODAVÍA

Primero entregar el resultado real del preflight y recibir autorización explícita
para aplicar V10 en perfil-v9-notifications. La aprobación del preflight no autoriza
escrituras ni los datos de la demostración.

Una vez autorizado, mantener las mismas variables de rama, hostname y DB_*.
En la MISMA PowerShell de backend:

```powershell
$env:WRITER_V10_PREFLIGHT_TOKEN = Read-Host 'Pega la HUELLA del preflight aprobado'
$env:WRITER_V10_CONFIRMATION = Read-Host 'Escribe exactamente AUTORIZO_V10_EN_perfil-v9-notifications'
try {
    mvn -o "-Dtest=WriterV10ControlledMigrationTests" "-Dwriter.v10.mode=apply" test
} finally {
    Remove-Item Env:\WRITER_V10_CONFIRMATION -ErrorAction SilentlyContinue
    Remove-Item Env:\WRITER_V10_PREFLIGHT_TOKEN -ErrorAction SilentlyContinue
}
```

La frase debe escribirse explícitamente. No se rellena automáticamente.
Si cambia el destino o un checksum, se bloquea y exige nuevo preflight/autorización.
No iniciar otro migrador/backend ni editar scripts mientras se realiza este paso.

El ejecutor espera una sola migración ejecutada y targetSchemaVersion=10.
Después comprueba en nuevas conexiones de solo lectura la tabla, historial,
checksums y mapping Writer junto a las otras entidades.
Salida de éxito: APLICACION_Y_POST_VALIDACION=OK y MIGRACIONES_EJECUTADAS=1_VERSION_10.
Si falla durante apply, revisar historial/tabla antes de repetir. Un fallo del
post-check no implica que una migración ya confirmada se haya deshecho.
No se usa clean, repair ni escritura manual para “solucionar” un fallo.

V10 original permanece intacta. Crea tabla writer_stories, identidad, FK users(id)
ON DELETE CASCADE, unicidad de story_key e índice owner/updated. Flyway registra
normalmente la ejecución. No incluye datos de demostración ni DML de historias.

## 5. Validación local del ejecutor

Comando ejecutado por Codex desde backend:
```powershell
mvn -o "-Dtest=WriterV10MigrationRunnerTests,WriterV10ControlledMigrationTests,WriterJdbcReadOnlyProbeTests" test
```
BUILD SUCCESS, exit 0; 17 pruebas aprobadas, 0 fallidas/errores y 1 omitida.
WriterV10MigrationRunnerTests: 11 casos; WriterJdbcReadOnlyProbeTests: 6 casos.
WriterV10ControlledMigrationTests: 1 omitido porque no se activó ningún modo Neon.
Maven: 25.750 s. Compilación de 39 fuentes de prueba.
Se probaron rechazo de destino distinto/production, consentimiento/huella ausentes,
huella cambiada, planes inválidos, callback exclusivo, protección read-only,
consultas PostgreSQL simuladas, preflight Flyway/Hibernate sin escrituras, V10 sola
en H2, deriva de checksum y columna ausente. No se ejecutó el preflight real Neon
desde Codex: debe ejecutarse con las variables de tu PowerShell.

Las pruebas de Flyway se realizan en H2 temporal. Como H2 no soporta los dos
índices parciales PostgreSQL de V9, únicamente sus recursos de fixture en memoria
usan índices completos. No se modifica V9 en disco; el modo real de Neon siempre
usa todos los scripts originales. V10 se ejecuta sin adaptación en las pruebas.
Por tanto esto no certifica el resultado real del preflight PostgreSQL.

## 6. Siguiente etapa, después de aplicar con autorización

Iniciar Spring Boot con --server.port=8080, --spring.flyway.enabled=false y
--spring.jpa.hibernate.ddl-auto=validate; CORS http://localhost:7357.
Luego Flutter Web con API_BASE_URL=http://localhost:8080, puerto 7357 y configuración
cliente Firebase del mismo proyecto. No se inició ninguno de esos servicios aquí.
Autorizar datos de prueba y comprobar con dos cuentas: crear, guardar dos capítulos,
salir/reabrir, recuperar desde Neon, publicar, descubrir/leer con cuenta B, impedir
ediciones ajenas y retirar/eliminar. Mantener production fuera de toda la prueba.
