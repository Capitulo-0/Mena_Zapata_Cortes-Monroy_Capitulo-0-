# Base de datos — backend MVP, pasos 1 y 2

PostgreSQL es la base de ejecución prevista; Neon puede usarse mediante su URL
JDBC y TLS. No se almacenan credenciales en esta carpeta.

## Estructura existente

- `migrations/`: documentación de migraciones y referencia a los SQL ejecutables.
- `seeds/`: reservada; el paso 1 no añade datos de dominio.
- `diagrams/`: reservada para diagramas del equipo.

Se conservan las carpetas y `.gitkeep` creados por el equipo.

## Fuente única de migraciones

Flyway ejecuta las migraciones empaquetadas en:
`backend/src/main/resources/db/migration/`.

No se duplican los SQL en `database/migrations/`: eso evitará mantener dos copias
con checksums o contenido diferente. Consulta `migrations/README.md`.

La primera versión, `V1__initialize_backend.sql`, crea `backend_bootstrap` y un
marcador del servicio. Flyway crea también su tabla técnica `flyway_schema_history`.
V2 agrega `users`, `books` y `library_entries`, con claves foráneas, unicidad
y restricciones de páginas y estados. No se implementa autenticación.

## Verificación en la base configurada

```sql
SELECT version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;

SELECT id, service_name, initialized_at FROM backend_bootstrap;
```

Se esperan las versiones 1 y 2 exitosas y el marcador `capitulo-0-backend` con id 1.
Reiniciar la aplicación no debe duplicar ese registro.

Variables de conexión, comandos de ejecución y límites de las pruebas:
`backend/README.md`.
