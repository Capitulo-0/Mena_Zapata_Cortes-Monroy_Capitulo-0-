# Arquitectura técnica de Capítulo 0

## Objetivo
Describir los principales componentes del sistema
y cómo se comunican entre sí.

## Frontend
La aplicación utiliza Flutter para implementar la
interfaz, navegación y experiencia de lectura.

## Backend
Spring Boot proporciona servicios REST para
gestionar las funcionalidades del sistema.

## Base de datos
PostgreSQL, alojado en Neon, permite almacenar
la información persistente de la plataforma.

## Autenticación
Firebase Authentication gestiona la identidad
de los usuarios durante el acceso a la aplicación.

## Integraciones externas
- Google Books: consulta de información bibliográfica.
- Gutendex: acceso a obras de dominio público.
- Gemini: asistencia literaria y apoyo creativo.
- Geoapify: servicios geográficos.

## Flujo general
1. El usuario interactúa con Flutter.
2. La aplicación solicita información al backend.
3. El backend valida y procesa la solicitud.
4. Consulta la base de datos o un servicio externo.
5. Devuelve una respuesta al frontend.
6. Flutter presenta los resultados al usuario.

## Aplicación en la defensa
Esta arquitectura permite explicar la separación
entre presentación, lógica de negocio, persistencia
e integraciones externas.
