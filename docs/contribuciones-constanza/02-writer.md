# Módulo Writer - Capítulo 0

## Objetivo
Permitir que los usuarios desarrollen y compartan sus propias
historias dentro de la plataforma literaria.

## Funcionalidades desarrolladas
- Creación de historias con título y sinopsis.
- Organización de obras mediante capítulos.
- Edición y actualización del contenido.
- Guardado de historias como borradores.
- Publicación de obras para la comunidad.
- Visualización de historias de otros escritores.
- Selección y previsualización de portadas.
- Integración del asistente Gemini como apoyo creativo.

## Persistencia y seguridad
Se integró Writer con el backend de Spring Boot y la base de
datos PostgreSQL alojada en Neon.

Se implementaron controles de autenticación y propiedad
para proteger las historias y capítulos privados.

## Validaciones
Se realizaron pruebas de creación, edición, consulta,
persistencia y publicación de historias.

También se verificó el acceso a las publicaciones desde
otras cuentas y el comportamiento de las portadas.

## Limitaciones conocidas
El almacenamiento permanente de portadas personalizadas
requiere configurar un servicio de almacenamiento remoto seguro.
