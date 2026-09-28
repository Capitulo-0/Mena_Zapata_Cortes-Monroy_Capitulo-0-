# Plataforma Móvil Integral para Lectores y Autores Independientes

Proyecto desarrollado como parte de la asignatura **Capstone de Ingeniería en Informática**.

## Descripción

Aplicación móvil multiplataforma orientada a lectores y autores independientes, desarrollada con Flutter y Dart.

La plataforma integra tres pilares principales:

- Catalogación social de libros.
- Autopublicación de obras independientes.
- Georreferenciación de espacios físicos de lectura.

El objetivo es centralizar distintas herramientas relacionadas con la lectura dentro de una única plataforma móvil.

## Tecnologías

### Aplicación móvil

- Flutter
- Dart

### Backend

- Java
- Spring Boot
- Maven

### Base de datos

- PostgreSQL
- Neon.tech

### Autenticación

- Firebase Authentication
- JWT

### Servicios e integraciones

- Google Books API
- Google Maps Flutter Plugin
- Cloudinary
- Google ML Kit
- Gemini API

### Herramientas de desarrollo y gestión

- Git
- GitHub
- GitHub Projects / Trello
- Visual Studio Code
- Android Studio
- Postman
- Figma
- Discord

## Integrantes y roles

| Integrante | Rol principal |
|---|---|
| John Francis Zapata Sanchez | Líder Frontend & UI/UX |
| Eduardo Alfredo Cortes-Monroy Castro | Líder Backend & Base de Datos |
| Constanza Belen Mena Aldana | Líder Integración de Servicios, QA & Documentación |

El desarrollo del proyecto es colaborativo, por lo que los tres integrantes participan en todas las areas de frontend, backend, base de datos, integración, pruebas y documentación.

## Metodología de trabajo

El equipo utiliza **Kanban** para organizar y dar seguimiento a las tareas mediante GitHub Projects o Trello.

Las tareas se distribuyen en las siguientes columnas:

- Backlog
- En Progreso
- En Revisión
- Terminado

El desarrollo se complementa con un flujo de control de versiones basado en **GitFlow**, utilizando Pull Requests y revisión de código antes de integrar cambios a las ramas principales.

## Arquitectura de la solución

La solución utiliza una arquitectura **cliente-servidor**.

La aplicación móvil desarrollada con Flutter y Dart consume una API REST desarrollada con Java y Spring Boot.

El backend utiliza una arquitectura multicapa compuesta por:

- **Controller:** recibe y gestiona las solicitudes HTTP.
- **Service:** contiene la lógica de negocio.
- **Repository:** gestiona el acceso a los datos.

La información se almacena en una base de datos PostgreSQL alojada en Neon.tech.

La solución también integra servicios externos como Firebase Authentication, Google Books API, Google Maps, Cloudinary, Google ML Kit y Gemini API.

La arquitectura general puede representarse de la siguiente forma:

```text
Aplicación móvil
 Flutter + Dart
       │
       │ HTTP / API REST
       ▼
Backend
Java + Spring Boot
       │
       ├── Controller
       ├── Service
       └── Repository
       │
       ▼
Base de datos
PostgreSQL / Neon.tech

Servicios externos:
- Firebase Authentication
- Google Books API
- Google Maps
- Cloudinary
- Google ML Kit
- Gemini API
```

## Instrucciones para ejecutar el proyecto localmente

> El proyecto se encuentra actualmente en etapa de desarrollo (fase 2, 10%), por lo que algunas funcionalidades, módulos o integraciones pueden no estar disponibles todavía.

### Requisitos previos

Antes de ejecutar el proyecto se debe contar con:

- Git
- Visual Studio Code y/o Android Studio
- Flutter SDK
- Dart SDK
- JDK 25
- Maven
- Un emulador Android o dispositivo físico

Para verificar la instalación de Flutter:

```bash
flutter doctor
```

### Clonar el repositorio

Clonar el repositorio desde GitHub:

```bash
git clone <URL_DEL_REPOSITORIO>
cd Capitulo-0-
```

También es posible descargar el repositorio desde GitHub utilizando la opción **Download ZIP** y descomprimirlo localmente.

### Ejecutar la aplicación móvil

Abrir la carpeta correspondiente al proyecto Flutter en Visual Studio Code o Android Studio.

Instalar las dependencias:

```bash
flutter pub get
```

Verificar los dispositivos disponibles:

```bash
flutter devices
```

Luego iniciar un emulador Android o conectar un dispositivo físico y ejecutar:

```bash
flutter run
```

### Ejecutar el backend

Verificar que JDK 25 esté instalado:

```bash
java -version
```

Ingresar a la carpeta correspondiente al backend y ejecutar:

```bash
mvn spring-boot:run
```

Una vez iniciado, el backend expondrá la API REST utilizada por la aplicación móvil.

### Configuración de servicios externos

Para utilizar las funcionalidades que dependan de servicios externos será necesario configurar las variables de entorno y credenciales correspondientes.

El proyecto contempla integración con:

- Firebase Authentication
- Google Books API
- Google Maps
- Cloudinary
- Google ML Kit
- Gemini API
- PostgreSQL mediante Neon.tech

Las claves, tokens y credenciales privadas no deben almacenarse directamente en el repositorio.

## Flujo de trabajo con Git

El proyecto utiliza un flujo basado en **GitFlow**.

### Ramas principales

- `main`: contiene la versión estable del proyecto.
- `develop`: contiene los cambios integrados que todavía se encuentran en desarrollo o validación.

### Ramas temporales

Las ramas temporales se crean según el tipo de tarea:

- `feature/*`: desarrollo de nuevas funcionalidades.
- `bug-fix/*`: corrección de errores encontrados durante el desarrollo.
- `hotfix/*`: correcciones urgentes sobre la versión estable.

Ejemplos:

```text
feature/login
feature/pantalla-inicio
bug-fix/error-validacion-login
hotfix/error-autenticacion
```

Las ramas `feature/*` y `bug-fix/*` normalmente se crean desde `develop` y posteriormente se integran nuevamente en `develop`.

Las ramas `hotfix/*` se crean desde `main` y sus cambios deben quedar posteriormente reflejados también en `develop`.

## Pull Requests

Los cambios deben integrarse mediante **Pull Requests**.

### Funcionalidades y correcciones normales

1. Actualizar la rama `develop`.
2. Crear una rama temporal desde `develop`.
3. Realizar los cambios correspondientes.
4. Realizar commit y push.
5. Crear un Pull Request hacia `develop`.
6. Otro integrante debe revisar los cambios.
7. El Pull Request requiere al menos una aprobación.
8. Una vez aprobado, realizar `Squash and merge`.
9. Eliminar la rama temporal después del merge.

Ejemplo:

```text
feature/login → Pull Request → develop
```

### Paso de develop a main

Cuando `develop` contenga una versión estable y probada:

1. Crear un Pull Request desde `develop` hacia `main`.
2. Otro integrante debe revisar y aprobar los cambios.
3. Realizar `Squash and merge`.

```text
develop → Pull Request → main
```

No se realizan cambios directamente sobre `main` o `develop`. Los cambios deben pasar por Pull Request y revisión de código antes de ser integrados.

## Convención de commits

Los commits utilizan los siguientes prefijos:

- `feat:` nueva funcionalidad.
- `fix:` corrección de errores.
- `docs:` cambios de documentación.
- `test:` creación o modificación de pruebas.
- `refactor:` reorganización de código sin modificar su comportamiento.
- `chore:` configuración, mantenimiento, dependencias o archivos auxiliares.

### Ejemplos

```text
feat: agregar pantalla de inicio de sesión
fix: corregir validación del correo
docs: actualizar instrucciones del proyecto
test: agregar pruebas de autenticación
refactor: reorganizar servicio de usuarios
chore: actualizar gitignore
```