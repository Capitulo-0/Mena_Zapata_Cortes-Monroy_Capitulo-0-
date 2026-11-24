# Pruebas y validaciones - Capítulo 0

## Objetivo
Registrar los procedimientos de validación aplicados
durante el desarrollo e integración de Capítulo 0.

## Análisis estático
Se utilizó flutter analyze para identificar problemas
en el código y comprobar su consistencia.

## Pruebas del frontend
- Navegación entre pantallas.
- Visualización de portadas y fichas bibliográficas.
- Adaptación de interfaces a diferentes resoluciones.
- Comportamiento de la biblioteca y el lector digital.
- Estados de carga y presentación de errores.

## Pruebas de integración
- Comunicación entre Flutter y Spring Boot.
- Consultas a servicios externos.
- Autenticación y separación de usuarios.
- Persistencia de historias y capítulos en Writer.
- Manejo de errores y cuotas del asistente Gemini.

## Consideraciones
Las pruebas automatizadas se complementaron con
comprobaciones manuales durante la integración.

Las solicitudes de Gemini están sujetas a cuotas del
proveedor, por lo que no todos los escenarios pueden
validarse continuamente con el servicio real.
