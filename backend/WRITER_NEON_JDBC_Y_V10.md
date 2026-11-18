# Writer: comprobación JDBC y aplicación controlada de V10

## Comando inmediato, desde la PowerShell que YA tiene las credenciales

Directorio actual: backend. No abrir otra terminal para ejecutar este comando.

```powershell
mvn -o "-Dtest=WriterNeonReadOnlyTests" "-Dwriter.jdbc.check=true" test
```

Usa únicamente dependencias Maven existentes, incluido el controlador PostgreSQL.
No necesita psql, Docker, PostgreSQL local ni Spring Boot. Si Maven no está en PATH,
usar .\mvnw.cmd con los mismos argumentos (el wrapper debe estar disponible en caché).

DB_URL, DB_USERNAME y DB_PASSWORD se leen con System.getenv() dentro de la JVM
iniciada por Maven desde ESA PowerShell. No se pasan como argumentos ni se imprimen.
GOOGLE_BOOKS_API_KEY no es necesaria para esta prueba.
No usar -X, trazas JDBC ni valores secretos en la línea de comandos.

El test está desactivado por defecto: sin writer.jdbc.check=true se OMITIRÁ.
Una omisión NO confirma conexión.

## Qué hace

1. Exige variables presentes y una URL JDBC PostgreSQL con hostname Neon.
2. Rechaza credenciales embebidas, parámetros de logging y opciones de sesión
   arbitrarias. Acepta sslmode=require/verify-ca/verify-full, channelBinding,
   connectTimeout, socketTimeout, tcpKeepAlive y sslrootcert. Si sslmode no está en
   la URL, solicita verify-full. No debilitar TLS para sortear un error.
3. Abre DriverManager.getConnection con las credenciales del proceso.
4. Establece readOnly=true y autoCommit=false; comprueba en PostgreSQL que
   transaction_read_only sea on antes de consultar datos de aplicación.
5. Ejecuta SELECT 1, verifica public.flyway_schema_history, el registro de versión
   10 y public.writer_stories.
6. Hace rollback, cierra la conexión y solo entonces imprime el resultado.
   No ejecuta commit, migraciones, DML ni DDL.

Los errores se sustituyen por mensajes fijos y SQLState, sin mensaje/cause JDBC.
El logger PostgreSQL se desactiva durante la prueba. El resultado no incluye URL,
usuario, contraseña, nombre de base ni tokens.

## Salida esperada para el estado que confirmó el usuario

Ejemplo esperado, NO resultado real obtenido por Codex:

```text
WRITER_JDBC: CONEXION_Y_AUTENTICACION=OK
WRITER_JDBC: TRANSACCION_SOLO_LECTURA=OK
WRITER_JDBC: SELECT_1=OK
WRITER_JDBC: FLYWAY_HISTORY=EXISTE
WRITER_JDBC: V10=NO_REGISTRADA
WRITER_JDBC: PUBLIC_WRITER_STORIES=NO_EXISTE
WRITER_JDBC: ROLLBACK_Y_CIERRE=OK
WRITER_JDBC: RAMA=CONFIRMAR_EN_CONSOLA_NEON_NO_INFERIBLE_POR_JDBC
WRITER_JDBC: MIGRACIONES_EJECUTADAS=NINGUNA
```

V10 puede indicar APLICADA, REGISTRO_FALLIDO o REGISTROS_MULTIPLES_REVISAR.
El test confirma conectividad/autenticación aunque V10 o su tabla no existan:
esa ausencia es precisamente el estado esperado antes de migrar.
Una discrepancia entre V10 y tabla requiere revisión; NO reparar ni migrar a ciegas.
Si FLYWAY_HISTORY=NO_EXISTE, detener la preparación de V10: no asumir V1-V9 aplicadas.

Compartir únicamente las líneas WRITER_JDBC y BUILD SUCCESS/FAILURE, nunca variables
ni mensajes de otras herramientas con datos de conexión.
Errores orientativos: 28P01 autenticación, 42501 permisos, 08001 establecimiento de
conexión (puede ser DNS/TLS/red), 25006 transacción de solo lectura no confirmada.
SQLState orienta la siguiente revisión; por sí solo no determina la causa exacta.

## V10 revisada, todavía NO autorizada ni aplicada en esta etapa

Archivo existente: src/main/resources/db/migration/V10__create_writer_stories.sql.
Compatible por inspección con PostgreSQL: identity BIGINT, timestamps con zona,
TEXT, FK, UNIQUE e índice. users(id) de V2 es BIGINT, compatible con owner_id.
No hay otra V10 ni definiciones de writer_stories en V1-V9 del repositorio.
La prueba WriterPersistenceTests existente verifica el mapping/FK/cascade en H2;
no sustituye comprobar el esquema PostgreSQL real.

Efectos de V10: crear tabla writer_stories y su secuencia identity, FK a users con
ON DELETE CASCADE, unicidad story_key e índice por propietario/actualización.
Los capítulos y estados se almacenan dentro de payload TEXT.
No cambia datos existentes ni borra tablas; la FK cascada afectaría futuras
eliminaciones de usuarios que tengan historias. Flyway registra la ejecución.
No cambiar manualmente flyway_schema_history ni editar V10 después de aplicada.

## Procedimiento para autorizar y ejecutar Flyway en el siguiente paso

Aún NO ejecutar Spring Boot, flyway:migrate, scripts SQL ni pruebas de escritura.
El resultado del test JDBC debe revisarse primero.

1. En Connect de la rama perfil-v9-notifications, confirmar de nuevo el endpoint y
   el nombre de rama. JDBC no permite deducir de forma fiable el nombre de rama.
   El usuario ya confirmó ese destino; para la operación de escritura se volverá
   a fijar el endpoint independientemente de DB_URL.
2. Solicitar confirmación explícita: “Confirmo la rama perfil-v9-notifications y
   autorizo aplicar exclusivamente V10 en ella”. La autorización para comprobar
   conexión NO autoriza la migración ni datos de prueba.
3. Preparar un ejecutor independiente de Spring que use Flyway de las dependencias
   actuales. Debe exigir activación explícita, la rama autorizada y un hostname
   esperado obtenido de Connect, comparar ese hostname con DB_URL y abortar si
   difieren. Nunca obtener el valor esperado de la propia DB_URL. No imprimirlo.
   Si no puede demostrarse la identidad del endpoint, no ejecutar.
4. El ejecutor debe comprobar en solo lectura que V1-V9 estén aplicadas y válidas,
   que V10 sea la ÚNICA pendiente y que writer_stories no exista. Si no se cumple,
   abortar. No usar baseline, repair, clean ni outOfOrder.
5. Usar una única configuración explícita Flyway: dataSource con DB_* del proceso,
   locations=classpath:db/migration, schemas/defaultSchema=public, target=10,
   cleanDisabled=true, baselineOnMigrate=false, outOfOrder=false,
   validateOnMigrate=true. No arrancar el contexto Spring ni usar su datasource
   configurable por otros perfiles. Fijar/verificar el destino antes de migrate.
6. Tras autorización, ejecutar migrate una vez; registrar versión, éxito y existencia
   de tabla sin datos de conexión. No modificar historial a mano. Detener ante errores.
7. Después iniciar Spring Boot con Flyway desactivado y ddl-auto=validate; recién
   entonces autorizar/usar datos de prueba para validar Writer real con dos cuentas.

No se incluye ahora un comando ejecutable que cambie Neon: el ejecutor de migración
se concretará al recibir el resultado JDBC y la autorización explícita. Esto impide
aplicar V10 accidentalmente al ejecutar la suite normal.

## Después de la migración autorizada

En la misma terminal backend, con DB_* y Firebase Admin/ADC del proyecto correcto:

```powershell
$env:APP_CORS_ALLOWED_ORIGINS='http://localhost:7357'
mvn spring-boot:run "-Dspring-boot.run.arguments=--server.port=8080 --spring.flyway.enabled=false --spring.jpa.hibernate.ddl-auto=validate"
```

Solo usar después de esquema validado en V9; no ejecutado por esta preparación.
En android, con configuración cliente Firebase Web del mismo proyecto:

```powershell
flutter run -d chrome --web-hostname=localhost --web-port=7357 --dart-define-from-file=config/firebase_web.local.json --dart-define=API_BASE_URL=http://localhost:8080
```

Usar cuentas/datos de prueba autorizados. Cuenta A: crear historia, guardar dos
capítulos, recargar app y recuperar, publicar. Cuenta B: descubrir en comunidad,
leer y verificar que no puede editarla. A: retirar/eliminar. B: actualizar y
confirmar desaparición/404. El procedimiento detallado está también en
INFORME_CIERRE_WRITER_CAPITULO0_20261117.txt.
