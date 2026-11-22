> Authentication update: Firebase Admin + Spring Security now protect personal APIs.
> GET/POST /api/users are disabled (401/403); use GET /api/me for a linked identity.
> Read [AUTHENTICATION.md](AUTHENTICATION.md) for ADC, endpoint policy and changed contracts.
> Earlier MVP examples below describe the historical unauthenticated step.

# Backend MVP — Pasos 1 y 2

Implementado: configuración PostgreSQL por entorno, Flyway y `GET /api/health`.
Incluye CRUD mínimo de usuarios de prueba, catálogo local y biblioteca.
No incluye autenticación ni integraciones externas.

## Requisitos y variables

El proyecto usa Java 25 y Spring Boot 4.1.1. Desde `backend/`, usa el Maven Wrapper
(`.\mvnw.cmd` en PowerShell, `./mvnw` en sistemas Unix) o Maven instalado.

Variables obligatorias en el proceso que ejecuta Maven/Java:

| Variable | Contenido |
| --- | --- |
| `DB_URL` | URL JDBC PostgreSQL: `jdbc:postgresql://<host>:5432/<database>` |
| `DB_USERNAME` | Usuario con permisos para conectar y ejecutar la migración inicial |
| `DB_PASSWORD` | Contraseña de ese usuario |

Para Neon utiliza sus datos de conexión con formato JDBC y TLS (`sslmode=require`);
no pegues credenciales ni URLs privadas en este repositorio. Un URI `postgresql://`
sin el prefijo `jdbc:` no es una URL válida para esta configuración JDBC.

`backend/.env.example` solo documenta nombres. Spring Boot no carga `.env`
automáticamente: exporta las variables en tu terminal o configúralas en tu IDE.
No se incluye una base ni credenciales de respaldo para el arranque normal.

## Compilar y probar

```powershell
.\mvnw.cmd compile
.\mvnw.cmd test
.\mvnw.cmd package
```

Los tests predeterminados usan H2 en memoria con modo PostgreSQL, exclusivamente
como dependencia `test`. Verifican Flyway, su repetición, disponibilidad HTTP y
respuestas UP/DOWN. H2 no demuestra compatibilidad real con PostgreSQL/Neon.

`PostgresConnectionTests` se ejecuta si `DB_URL` tiene formato JDBC PostgreSQL;
necesita también `DB_USERNAME` y `DB_PASSWORD`. Aplica las migraciones pendientes en la base indicada:
usa una base dedicada al desarrollo/pruebas, no una base productiva compartida.
Sin esas variables la prueba real se omite y debe informarse como no verificada.

## Iniciar con PostgreSQL/Neon

Una vez exportadas las tres variables, desde `backend/`:

```powershell
.\mvnw.cmd spring-boot:run
```

Alternativamente, después de empaquetar:

```powershell
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

Para comprobar la aplicación:

```powershell
Invoke-RestMethod http://localhost:8080/api/health
```

Con conexión disponible devuelve HTTP 200:

```json
{"status":"UP","service":"capitulo-0-backend","database":"UP"}
```

Si la conexión deja de estar disponible con la aplicación iniciada, devuelve
HTTP 503 con `status` y `database` en `DOWN`. No expone errores internos,
credenciales ni URL. Al iniciar, una conexión o migración fallida impide el
arranque: no existe un modo productivo que oculte esa falla y responda UP.

## Comprobación local sin credenciales (solo H2 de tests)

```powershell
.\mvnw.cmd spring-boot:test-run "-Dspring-boot.run.profiles=test"
```

El objetivo test-run incluye las clases, recursos y dependencias de tests.
Esto sirve para verificar arranque/HTTP sin PostgreSQL. No usar el perfil `test`
en producción y no interpretar este resultado como conexión real a Neon.

## Migraciones y JPA

Fuente ejecutable única: `src/main/resources/db/migration/`.
Flyway aplica `V1__initialize_backend.sql` y registra su historial en
`flyway_schema_history`. V1 crea únicamente `backend_bootstrap` con un marcador
técnico; no crea tablas de usuarios, libros o biblioteca.

Hibernate usa `ddl-auto=validate` y no crea ni actualiza el esquema. La
inicialización SQL alternativa está deshabilitada. Flyway clean está deshabilitado.
No edites V1 después de aplicarla: agrega una nueva versión para cambios futuros.

La relación con las carpetas del equipo se documenta en `../database/README.md`
y `../database/migrations/README.md`. `seeds/` y `diagrams/` permanecen reservadas.

## Bloque 2: usuarios, libros y biblioteca

V2__create_users_books_library.sql agrega users, books y library_entries.
V1 permanece intacta. Las entidades usan identidad BIGINT y fechas UTC mediante
callbacks JPA. La base aplica claves foráneas, unicidad y checks de páginas/estado.
No hay borrado en cascada del catálogo.

Endpoints provisionales SIN autenticación (no exponer públicamente antes de protegerlos):

| Método | Ruta | Respuesta |
| --- | --- | --- |
| POST | /api/users | 201, usuario creado |
| GET | /api/users | 200, usuarios |
| POST | /api/books | 201, libro creado |
| GET | /api/books | 200, libros |
| GET | /api/books/{id} | 200, libro |
| GET | /api/users/{userId}/library | 200, biblioteca |
| POST | /api/users/{userId}/library | 201, entrada |
| PATCH | /api/users/{userId}/library/{bookId} | 200, entrada actualizada |
| DELETE | /api/users/{userId}/library/{bookId} | 204, solo elimina la entrada |

Ejemplos de cuerpos JSON:

```json
{"email":"demo@example.test","displayName":"Lector demo"}
```
```json
{"title":"Libro demo","author":"Autor","publisher":"Editorial","totalPages":300}
```
```json
{"bookId":1,"status":"POR_LEER","readingFormat":"FISICO"}
```
```json
{"status":"LEYENDO","currentPage":75,"totalPages":300,"readingFormat":"EBOOK","publisherOverride":"Mi edición"}
```

Los campos de libro author, synopsis, isbn, publisher, totalPages,
publicationYear y coverUrl son opcionales. No se consulta ninguna API.
El email se normaliza a minúsculas y es único; no es una credencial de acceso.
La entrada usa totalPages del libro al crearse si no se informa otro total.
Defaults: POR_LEER, FISICO y página 0.
PATCH conserva campos omitidos o null; no borra valores con null.
Para vaciar publisherOverride puede enviarse una cadena vacía.
No se puede eliminar un total existente con este contrato mínimo.

Estados: POR_LEER, LEYENDO, LEIDO. Formatos: FISICO, EBOOK, OTRA_PLATAFORMA.
POR_LEER normaliza página a 0. LEIDO normaliza a totalPages si se conoce.
Las páginas negativas y las superiores al total se rechazan antes de normalizar.
LEYENDO admite 0 y también la página final; no cambia automáticamente de estado.
Cambiar LEIDO a LEYENDO conserva la página existente salvo que se informe otra.
El porcentaje es derivado, no se almacena: currentPage/totalPages, con 2 decimales.
Sin total conocido devuelve 0, o 100 si el estado es LEIDO, sin inventar páginas.
Formato y editorial se conservan al cambiar solo estado/progreso.

Errores uniformes: status, message, details y timestamp.
400: validación, JSON/enums inválidos o páginas incoherentes.
404: usuario, libro o entrada inexistente.
409: email/biblioteca duplicada o conflicto de integridad concurrente.
Las restricciones únicas de la base complementan las comprobaciones del servicio.
El alcance por userId evita mezclar registros, pero NO es autorización:
sin autenticación cualquier cliente que conozca el ID puede llamar esos endpoints.
Listados sin paginación, apropiados solo para este MVP mínimo.

MvpEndpointTests prueba las rutas HTTP sobre H2, con validaciones, duplicados,
aislamiento de registros, estados y eliminación que conserva el catálogo.
La prueba PostgreSQL condicional valida la migración vigente V2; falta comprobarla
contra PostgreSQL/Neon real si no están disponibles las variables de entorno.
