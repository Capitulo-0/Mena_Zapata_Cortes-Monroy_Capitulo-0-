CAPÍTULO 0 — INFORME TÉCNICO BLOQUE 2
Fecha: 11/11/2026
Rama: feature/backend-core-completion

1. RESULTADO

Se conectaron Home, Biblioteca y los accesos pertinentes del perfil con los endpoints existentes de biblioteca privada. Se preservaron las pantallas, navegación, estilo y autenticación Web/Android. No se necesitó modificar código productivo Java, dependencias ni migraciones.

La biblioteca usa IDs SQL y respuestas confirmadas del servidor. Permite consultar, agregar, actualizar estados/páginas/formato/editorial y eliminar pertenencias. Hay carga, vacío, error y reintento, sin éxitos falsos.

Implementación y validación local completadas. NO se declara validado el E2E real del Bloque 2: faltan las pruebas manuales contra Firebase/Spring/Neon. No se realizaron escrituras automatizadas sobre Neon, cambios en Firebase Console, commit ni push.

2. CONTEXTO Y CONSERVACIÓN DEL BLOQUE 1

El usuario informó validación manual satisfactoria del Bloque 1 en Chrome el 11/11/2026: Google/Firebase, Spring, Neon, health UP, provision y me 200, dos IDs internos distintos, restauración de sesión, logout/reingreso y ausencia de duplicados. Es evidencia aportada por el usuario, no ejecución de esta entrega.

Se conservaron las configuraciones Firebase Web/Android, la sesión preparada, el aprovisionamiento y el aislamiento local por cuenta. No se reinició el backend con Neon.

El working tree ya contenía cambios y archivos nuevos del Bloque 1. git status incluye ese trabajo anterior; la lista exclusiva de cambios del Bloque 2 figura abajo. No se ejecutaron operaciones Git de escritura.

3. ENDPOINTS UTILIZADOS

GET /api/me/library -> 200, lista de entradas propias.
POST /api/me/library -> 201, agregar bookId SQL.
PATCH /api/me/library/{bookId} -> 200, registro normalizado.
DELETE /api/me/library/{bookId} -> 204, quitar pertenencia.
GET /api/books -> 200, catálogo compartido.
POST /api/books -> 201, registro manual básico de metadatos.

Se reutilizan Controller, DTO, Mapper, Service y Repository Java existentes. Identidad privada resuelta por CurrentUserService a partir del Firebase token verificado. userId/firebaseUid no se envían como selector de propietario. bookId identifica el libro.

Campos: status POR_LEER/LEYENDO/LEIDO; readingFormat FISICO/EBOOK/OTRA_PLATAFORMA; currentPage, totalPages y publisherOverride. Se consume progressPercentage calculado por el backend.

Registrar metadatos manuales permite comenzar con catálogo vacío usando el endpoint existente. No implementa Google Books, contenido externo, autopublicación ni Writer backend. El catálogo es compartido; pertenencia y progreso son privados. DELETE no borra el catálogo.

4. ARQUITECTURA Y AISLAMIENTO

Firebase Auth -> SessionController preparado -> repositorio vinculado al UID -> ApiClient Bearer -> biblioteca propia -> CurrentUserService -> capas existentes -> PostgreSQL.

ApiClient incorpora requestJson para objetos/listas y 204, conservando request de objetos compatible con Auth. Se conserva un refresco de token ante 401 y mensajes controlados para errores HTTP.

ApiLibraryRepository fija ownerUid. Las peticiones comprueban que esa cuenta sigue activa; ApiClient comprueba expectedUid antes/después del HTTP. Respuestas tardías de otra cuenta se descartan. Al cambiar de cuenta se reemplaza el árbol de navegación y se libera el controlador anterior con su memoria y cliente.

LibraryController publica exclusivamente entradas confirmadas, serializa mutaciones y distingue carga/fallo/vacío. Una carga fallida inicial no aparece como biblioteca vacía. Durante una actualización fallida pueden seguir visibles los datos previamente confirmados junto con el error.

La biblioteca real no usa SharedPreferences: cada sesión consulta GET y puede recargarse explícitamente. Una cuenta nueva no hereda los libros privados demo. El invitado no instancia el controlador remoto ni llama a endpoints privados; el backend mantiene su propia exigencia de autenticación.

Writer no se modificó en este bloque. Se conserva su aislamiento local por UID anterior. No se borraron ni reasignaron preferencias heredadas y no se migraron obras a Neon.

5. CAMBIOS DE INTERFAZ

Se conserva el diseño y se añade una barra compacta de sincronización y un diálogo para elegir un libro SQL o registrar metadatos básicos.

Home utiliza catálogo SQL en sesiones autenticadas y progreso confirmado. Biblioteca mantiene filtros/detalles; el diálogo existente guarda páginas exactas, formato y editorial. Finalizar espera PATCH y comprueba LEIDO antes del mensaje de éxito. Eliminar espera DELETE antes de retirar la entrada.

Reanudar un libro SQL abre el registro manual de seguimiento: no muestra el contenido demo como contenido real. El origen backend se propaga a los detalles.

La aplicación productiva inyecta repositorio real para usuarios autenticados. El modo sin repositorio se conserva para fixtures/pruebas y demo de invitado, sin importar sus IDs simulados a SQL.

Reseñas, favoritos y otras funciones no incluidas siguen fuera de la persistencia backend de este bloque.

6. ERRORES Y REINTENTOS

- Red/401/403/404/409/400/422/503 se manejan mediante ApiFailure y mensajes comprensibles.
- Un fallo no convierte el cambio solicitado en confirmado.
- Respuesta malformada es error, nunca falso vacío.
- POST de pertenencia con 409 consulta biblioteca propia y solo confirma si encuentra la entrada.
- DELETE con 404 consulta biblioteca propia y solo confirma ausencia demostrada.
- Si el catálogo se creó pero falló agregar la entrada, el reintento reutiliza el ID SQL.
- Si la respuesta de creación de catálogo es ambigua por red, se solicita recarga antes de repetir; no se crea otra entrada automáticamente.
- El endpoint existente no garantiza deduplicación de metadatos creados deliberadamente en paralelo.
- Tokens/contraseñas no se imprimen ni guardan. No se agregaron secretos ni configuración Firebase real al código.

7. ARCHIVOS CREADOS EN ESTE BLOQUE

Rutas relativas a la raíz:
android/lib/features/library/models/library_entry.dart
android/lib/features/library/data/library_repository.dart
android/lib/features/library/presentation/controllers/library_controller.dart
android/lib/features/library/presentation/widgets/library_sync_bar.dart
android/lib/features/library/presentation/dialogs/add_library_book_dialog.dart
android/test/support/library_fakes.dart
android/test/library_controller_test.dart
android/test/library_repository_test.dart
android/test/library_remote_widgets_test.dart
backend/src/test/java/com/capitulo0/backend/MyLibraryPersistenceTests.java
BLOQUE_2_BIBLIOTECA_PROGRESO.md
INFORME_BLOQUE_2_BIBLIOTECA_PROGRESO_2026-11-11.txt

8. ARCHIVOS MODIFICADOS EN ESTE BLOQUE

Algunos ya estaban nuevos/modificados por el Bloque 1:
android/lib/core/network/api_client.dart — listas/204/identidad esperada, compatible con Auth.
android/lib/app.dart — repositorio por cuenta e inyección.
android/lib/features/home/presentation/screens/main_shell_screen.dart — controlador real y sincronización.
android/lib/features/home/presentation/screens/home_screen.dart — catálogo SQL, callbacks async.
android/lib/features/home/presentation/screens/home_book_detail_screen.dart — esperar confirmación, origen SQL.
android/lib/features/library/models/library_book.dart — marcador backend.
android/lib/features/library/models/reading_record.dart — total desconocido.
android/lib/features/library/presentation/dialogs/reading_record_dialog.dart — páginas exactas y total opcional.
android/lib/features/library/presentation/screens/library_screen.dart — carga disponible y mutaciones async.
android/lib/features/library/presentation/screens/library_book_detail_screen.dart — estado confirmado.
android/lib/features/library/presentation/widgets/reading_status_field.dart — espera/restauración ante fallo.
android/lib/features/profile/presentation/screens/profile_screen.dart — callbacks async.
android/lib/features/profile/presentation/widgets/profile_mark_read_sheet.dart — éxito solo confirmado.
android/lib/features/profile/presentation/widgets/profile_works_badges_section.dart — origen SQL y alta confirmada.

Dependencias agregadas: ninguna.
Código productivo Java modificado: ninguno.
Migraciones nuevas/aplicadas: ninguna.
V1/V2/V3: intactas.
Archivos Writer: sin modificaciones en este bloque.

9. TESTS AÑADIDOS

Backend: MyLibraryPersistenceTests, cinco tests H2 con FirebaseTokenVerifier simulado:
- Alta/PATCH/GET conserva páginas, formato, editorial y porcentaje.
- Dos usuarios independientes; no pueden editar/eliminar la pertenencia del otro.
- DELETE conserva libro del catálogo.
- Cuerpo/query no eligen identidad; invitado obtiene 401 en operaciones privadas.
- Páginas inválidas no cambian registro; total desconocido sigue nulo.

Flutter: 25 tests nuevos (13 controlador, 6 repositorio, 6 widgets/App):
Carga/error/reintento; IDs SQL frente a demo; recuperación con controlador/pantalla recreados; páginas exactas/formato; normalización; petición pendiente/fallida sin falso éxito; eliminación sin borrar catálogo; cuentas separadas/respuesta tardía; invitado; recuperación de creación/alta; total desconocido; JSON lista/204; conflicto409; refresco401; respuesta malformada; registro manual; cambio de cuenta a nivel de aplicación.

Sin credenciales Firebase reales ni escrituras a PostgreSQL compartido. Tests anteriores conservados.

10. RESULTADOS

mvn -o -B "-Dtest=*,!PostgresConnectionTests" test
BUILD SUCCESS: 75 tests aprobados.

mvn -o -B -DskipTests package
BUILD SUCCESS.

flutter analyze --no-pub
No issues found.

flutter test --no-pub
90 aprobados, 1 omitido, cero fallos. El omitido requiere navegador.

flutter build web --no-pub
Correcto.

flutter build apk --debug --no-pub
Correcto, APK debug generado.

git diff --check
Correcto.

Diff de migraciones
Sin cambios.

No se ejecutó PostgresConnectionTests. Puede existir un XML histórico omitido de esa clase en target; no integra los 75 tests de esta ejecución. Advertencias preexistentes Java/Android no impidieron empaquetar.

Compilar Android no equivale a validar autenticación real en dispositivo. Los tests con H2/dobles no equivalen a validar Neon compartido.

11. LIMITACIONES Y DEUDA

- Pendiente aceptación manual Chrome/Neon y Android real.
- No hay sincronización en tiempo real entre dispositivos; recarga explícita consulta servidor.
- No hay cola offline; una operación fallida requiere reintento.
- PATCH existente conserva campos nulos/omitidos: no permite borrar un total conocido. La UI lo rechaza en lugar de simular guardado.
- Total desconocido no produce páginas/porcentajes inventados; LEIDO representa 100%.
- Volver de LEIDO a LEYENDO respeta normalización del backend; no inventa una página previa.
- No hay contenido real de lectura para libros SQL; seguimiento manual.
- Reseñas/favoritos/listas/Writer remoto/Google Books/Cloudinary/social quedan fuera.
- Migración de datos locales heredados sin propietario necesita estrategia específica futura.
- Catálogo compartido no debe confundirse con biblioteca privada.
- No se cambiaron archivos locales Firebase ni secretos; siguen fuera de esta entrega.

12. VALIDACIÓN MANUAL PENDIENTE

Estas acciones escriben únicamente lo que la persona decide registrar. No se ejecutaron automáticamente contra Neon.

1) Usar backend y configuración Firebase Web externa del Bloque 1 ya validado, API_BASE_URL accesible y origen local permitido por CORS. No publicar valores de configuración ni cabeceras.
2) Entrar con A, abrir Biblioteca y confirmar GET propio. Sin entradas: vacío real, sin libros privados demo.
3) Añadir libro del catálogo. Si está vacío, registrar metadatos básicos con el diálogo. Confirmar POST satisfactorio y bookId SQL.
4) Actualizar Chrome: la entrada debe recuperarse.
5) Cambiar a Leyendo, guardar por ejemplo 73/300 páginas, formato y editorial. Confirmar PATCH/GET y que no se pierde precisión por redondeo.
6) Cerrar sesión/reingresar con A y reiniciar: recuperar páginas/formato. Probar Por leer y Leído.
7) Entrar con B: no debe ver biblioteca privada de A. Puede ver el catálogo compartido. Agregar el mismo libro con progreso diferente; volver a A y comprobar independencia.
8) Ownership: cubierto por tests H2; cualquier solicitud manual adicional contra Neon debe estar expresamente autorizada. B no puede editar/borrar una pertenencia exclusiva de A.
9) Eliminar con A: desaparece de biblioteca, permanece en catálogo. Recargar. La pertenencia independiente de B debe mantenerse.
10) Invitado: sin operaciones privadas ni peticiones de biblioteca.
11) Simular offline/fallo del backend al guardar: sin éxito falso, valor confirmado intacto. Recuperar conexión y reintentar.
12) Sesión inválida: refresco una vez; si falla, informar sin publicar cambios. Nunca copiar tokens.
13) Android: configurar URL alcanzable desde dispositivo; emulador usa 10.0.2.2 para host. Mantener Firebase Android existente y repetir alta/progreso/recarga/logout.
14) Comprobar Writer A/B sin borrar/migrar datos locales.

13. MATRIZ DE ACEPTACIÓN

Agregar/persistir: cubierto H2 + controlador/repositorio/widgets; pendiente Chrome/Neon.
Estado/páginas/formato/reinicio: cubierto H2 + recreación local; pendiente reinicio real.
Eliminar sin borrar catálogo: cubierto H2/controlador; pendiente entorno real.
Aislamiento A/B: cubierto H2/guardas/repositorio/App; pendiente dos cuentas reales.
Invitado: cubierto 401 H2 y widgets sin llamadas; pendiente comprobación UI real.
Errores red/autenticación: cubierto cliente/controlador/widgets; pendiente offline/expiración real.

Bloque 2 implementado y validado localmente; cierre E2E real pendiente del procedimiento manual.
