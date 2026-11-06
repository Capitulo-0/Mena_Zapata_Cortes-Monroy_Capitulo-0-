# Migraciones

La fuente ejecutable única es `backend/src/main/resources/db/migration/`.
Se respeta la convención de Spring Boot/Flyway para incluir los SQL en el JAR.
Esta carpeta del equipo se conserva como referencia; no contiene copias que
puedan divergir de los SQL del backend.

Primera migración: `V1__initialize_backend.sql`.
Crea solo la tabla técnica `backend_bootstrap` y un marcador de inicialización.
No crea entidades de negocio ni autentica usuarios.

Flyway guarda las versiones aplicadas en `flyway_schema_history`. No modificar
una migración aplicada: crear una nueva `V2__...sql` para cualquier cambio futuro.
`database/seeds/` y `database/diagrams/` permanecen sin cambios.

## Bloque 2

`backend/src/main/resources/db/migration/V2__create_users_books_library.sql`
crea users, books y library_entries con sus restricciones. V1 no se modifica.
No se duplican scripts en esta carpeta ni se agregan seeds de datos personales.
