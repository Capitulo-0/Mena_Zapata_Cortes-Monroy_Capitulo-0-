# Docker - Capítulo 0

Esta configuración dockeriza únicamente la build web del frontend Flutter actual.

Docker **no reemplaza** el flujo normal de desarrollo que tenemos actualmente con Flutter:

```bash
flutter run -d edge
```

o el uso del emulador de Android Studio.

## Archivos Docker

```text
Capitulo-0-/
├── .env.example
├── docker-compose.yml
└── android/
    ├── Dockerfile
    ├── .dockerignore
    └── nginx.conf
```

## Primer uso

Desde la raíz del repositorio:

```bash
docker compose up --build
```

Luego abrir:

```text
http://localhost:8080
```

Para detener los contenedores:

```bash
docker compose down
```

## Variables de entorno

Si se desea cambiar el puerto:

1. Copiar `.env.example` y crear `.env`.
2. Cambiar `FRONTEND_PORT`.

Ejemplo:

```env
FRONTEND_PORT=8085
```

La app va a estar disponible en `http://localhost:8085`.

El archivo `.env` SIEMPRE debe permanecer fuera de Git.

## Desarrollo diario

No es necesario reconstruir Docker cada vez que se modifica una pantalla de Flutter si se está desarrollando con `flutter run`.

Docker se debe volver a construir cuando tengamos que tenemos nuestra APT dockerizada:

```bash
docker compose up --build
```

## Futuro

Cuando exista Spring Boot y una base de datos, se agregarán los servicios nuevos al mismo `docker-compose.yml`:

```text
frontend
backend
db
```

