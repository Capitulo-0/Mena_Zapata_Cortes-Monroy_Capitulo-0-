# Algoritmo de recomendaciones literarias - Capítulo 0

## Objetivo
Explicar el proceso utilizado para generar recomendaciones
bibliográficas a partir de las preferencias del lector.

## Entrada
El algoritmo utiliza los libros guardados en la biblioteca
del usuario y los metadatos disponibles de esas obras.

## Procesamiento
1. Recupera las obras de la biblioteca personal.
2. Construye un perfil utilizando autores y categorías.
3. Genera consultas de búsqueda a Google Books.
4. Recupera libros candidatos en español.
5. Evalúa y ordena los candidatos.
6. Selecciona las recomendaciones disponibles.
7. Almacena temporalmente el resultado para evitar
   consultas repetidas innecesarias.

## Límites de búsqueda
La implementación define:
- Objetivo de cinco recomendaciones.
- Máximo de ocho solicitudes de búsqueda.
- Presupuesto de búsqueda de ocho segundos.
- Detención anticipada cuando existen suficientes resultados.
- Detención ante tres errores consecutivos del proveedor.

## Personalización
Si la biblioteca contiene información suficiente,
las recomendaciones consideran los autores y géneros
asociados al perfil de lectura.

Cuando faltan datos, se utiliza una estrategia de
descubrimiento general de obras.

## Manejo de errores
El servicio registra fallos del proveedor y evita
completar artificialmente las recomendaciones con
obras que no cumplan los criterios de selección.

## Aplicación en la defensa
Este algoritmo permite explicar cómo Capítulo 0
combina datos bibliográficos, reglas de búsqueda,
personalización, límites de tiempo y manejo de errores.
