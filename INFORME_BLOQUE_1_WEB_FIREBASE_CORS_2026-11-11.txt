# Bloque 1 — Firebase Web, Chrome y CORS

Fecha: 11/11/2026.
Rama: feature/backend-core-completion.
Este informe complementa el Bloque 1 anterior; no reemplaza la auditoría original.

## Resultado

Se implementó inicialización Firebase diferenciada Web/nativa, configuración Web externa,
diagnóstico específico de campos faltantes y CORS con lista de orígenes exactos.
Se conservan las pantallas, navegación, servicios, aprovisionamiento y funcionamiento Android.
Se generaron Web, APK Android y JAR actualizados.

El login real desde Chrome sigue pendiente de cargar los valores auténticos de la app Web
del proyecto y permitir el origen del frontend en el proceso backend activo.
No se inventaron valores ni se registraron aplicaciones en Firebase Console.
No se crearon usuarios Firebase reales ni se ejecutó aprovisionamiento contra Neon.

## 1. Causa exacta encontrada antes de editar

main.dart ejecutaba Firebase.initializeApp() sin options para todas las plataformas.
Eso funciona en Android porque Google Services aporta recursos nativos.
En Web no existe ese mecanismo: google-services.json no configura Chrome.

No se encontraron FirebaseOptions, firebase_options.dart ni bootstrap Firebase en web/index.html.
Tampoco se encontró configuración Web local o variables de entorno Firebase Web disponibles.
El SDK instalado firebase_core_web 4.1.0 comprueba options != null al crear la app Web por defecto
y señala “FirebaseOptions cannot be null when creating the default app.”
El catch genérico de main ocultaba esa causa tras el mensaje general mostrado por la app.

CORS es un segundo problema independiente: ocurre después de inicializar Firebase, cuando
el navegador quiere enviar Authorization al backend. No es la causa del mensaje inicial.

## 2. Qué se pudo y qué no se pudo comprobar sobre el proyecto

Se confirmó la integración Android local y que google-services.json sigue ignorado.
No se imprimió su contenido, IDs, claves o tokens.

No hay un archivo config/firebase_web.local.json con configuración Web real en el repositorio.
La única configuración Web creada aquí es una plantilla con valores vacíos.
No se dispone de acceso de lectura a Firebase Console para acreditar si la aplicación Web ya existe.
Ausencia de archivo local NO prueba ausencia de registro remoto.

La presencia de un cliente OAuth web en configuración Android no equivale a tener configurada
la aplicación Firebase Web de Flutter.
No se reutiliza appId Android ni se deduce authDomain/API key a partir de otros valores.

Se añadió scripts/check_firebase_web_config.ps1:
- compara projectId, número de proyecto y messagingSenderId Web con google-services.json Android;
- exige appId de tipo Web y campos completos;
- imprime únicamente estado y nombres de campos, nunca valores;
- no contacta Firebase ni confirma validez de la API key o registro remoto;
- permite comprobar la coincidencia una vez que el responsable complete el archivo local.

Con los archivos reales actuales no puede acreditarse esa coincidencia porque falta la parte Web.
Con fixtures sin validez real se probó aceptación de coincidencia y rechazo de proyecto diferente.

## 3. Archivos de este cambio

Nuevos, relativos a android/:
- lib/core/config/firebase_configuration.dart
- config/firebase_web.example.json
- scripts/check_firebase_web_config.ps1
- test/firebase_configuration_test.dart
- test/firebase_web_auth_test.dart

Modificados, relativos a android/:
- lib/main.dart: opciones Web explícitas y error de configuración sanitizado.
- lib/features/auth/data/firebase_auth_repository.dart: mensajes específicos de errores del navegador.
- .gitignore: ignora /config/*.local.json.
- .dockerignore: excluye config/*.local.json del contexto de construcción.

Backend:
- Nuevo src/main/java/com/capitulo0/backend/config/cors/ApiCorsConfiguration.java.
- Modificado config/security/SecurityConfiguration.java: integra CORS antes de autenticación.
- Modificado src/main/resources/application.properties: propiedad externa de orígenes.
- Modificado .env.example: documenta APP_CORS_ALLOWED_ORIGINS.
- Nuevo src/test/java/com/capitulo0/backend/CorsConfigurationTests.java.
- Nuevo src/test/java/com/capitulo0/backend/CorsEndpointTests.java.

Documentación:
- BLOQUE_1_WEB_FIREBASE_CORS.md
- INFORME_BLOQUE_1_WEB_FIREBASE_CORS_2026-11-11.txt (mismo contenido).

No se añadieron dependencias ni SDK manuales.
Los cambios anteriores del Bloque 1 ya estaban en el working tree y se conservaron.
No se modificaron las migraciones V1/V2/V3 ni se crearon otras.
No se modificaron pantallas visuales ni se eliminaron módulos.

## 4. Inicialización multiplataforma

FirebaseWebConfiguration.fromEnvironment lee:
- FIREBASE_WEB_API_KEY
- FIREBASE_WEB_APP_ID
- FIREBASE_WEB_MESSAGING_SENDER_ID
- FIREBASE_WEB_PROJECT_ID
- FIREBASE_WEB_AUTH_DOMAIN

En Web se construye FirebaseOptions únicamente con esos valores externos.
Si faltan campos, la pantalla de error existente explica cuáles y cómo suministrarlos.
Se rechaza appId Android, incoherencia appId/sender y authDomain con protocolo/ruta/puerto.
Los mensajes nunca incluyen valores introducidos.

En Android se pasan options=null, conservando la resolución nativa anterior de Google Services.
No se copia configuración Android a Web ni se cambia applicationId.
iOS u otras plataformas nativas conservan sus requisitos de configuración propios.

La verificación sintáctica local no acredita registro remoto, permisos o conectividad.

## 5. Acciones manuales en Firebase Console

No ejecutadas por el asistente:

1. Abrir Firebase Console y seleccionar exactamente el proyecto que contiene la app Android.
   Comparar internamente el ID/número de proyecto; no pegarlos en logs o informes.
2. Ir a Configuración del proyecto -> General -> Tus apps.
3. Si YA existe una app Web, utilizarla. Si NO existe, registrar una app con el icono Web </>.
   No crear un proyecto Firebase distinto y no sustituir la app Android.
   No hace falta activar Firebase Hosting para estas pruebas locales.
4. Abrir la configuración SDK de la app Web (opción de configuración).
5. Copiar sus valores al archivo local privado siguiendo esta correspondencia:

| Campo de Console | Campo del archivo local |
| --- | --- |
| apiKey | FIREBASE_WEB_API_KEY |
| appId | FIREBASE_WEB_APP_ID |
| messagingSenderId | FIREBASE_WEB_MESSAGING_SENDER_ID |
| projectId | FIREBASE_WEB_PROJECT_ID |
| authDomain | FIREBASE_WEB_AUTH_DOMAIN |

No se requieren measurementId ni storageBucket para el alcance actual de Authentication.
No agregar service account, private_key, contraseña, access token o ID token a ese archivo.

6. En Authentication -> Settings/Configuración -> Authorized domains/Dominios autorizados,
   comprobar localhost y agregarlo si falta.
   Firebase puede no incluir localhost automáticamente en proyectos recientes.
   Allí se introduce el DOMINIO, sin http:// ni puerto.
7. Confirmar Email/Password y Google habilitados, como indicó el responsable.
   No es necesario recrear el proveedor ni cambiar SHA de Android para inicializar Web.
8. Permitir popups de la app en Chrome para Google y revisar bloqueo de almacenamiento si aparece ese error.

No se incluyeron valores auténticos ni se modificó Console automáticamente.

## 6. Crear y comprobar el archivo local

Desde android/, solo si el archivo local aún no existe:

Copy-Item config/firebase_web.example.json config/firebase_web.local.json

Abrir config/firebase_web.local.json en el editor y completar únicamente con los cinco valores
exactos de la app Web del mismo proyecto. No enviar su contenido al chat ni imprimirlo.

Validación local sin mostrar valores:

powershell -NoProfile -File scripts/check_firebase_web_config.ps1

Un resultado positivo confirma estructura/coincidencia LOCAL con Android, no login remoto.
El archivo queda ignorado por Git y Docker. La plantilla versionada permanece vacía.

Los parámetros Firebase Web son configuración pública del cliente y necesariamente llegan al navegador
para que funcione el SDK; no son una service account ni secretos de Firebase Admin.
Usar archivo externo evita poner valores reales en fuentes y reportes, pero no puede convertir
la configuración del navegador en un secreto inaccesible para quien ejecuta esa aplicación.

## 7. CORS del backend

Propiedad:
app.cors.allowed-origins=${APP_CORS_ALLOWED_ORIGINS:}

Se utiliza una lista de orígenes EXACTOS separada por comas, sin comodines.
Valor vacío significa no permitir accesos cross-origin del navegador.
Se rechazan orígenes con credenciales, rutas, query, fragment o puertos inválidos.
Los errores de configuración no repiten la URL recibida.

Se permite GET/POST/PATCH/DELETE/OPTIONS y headers Authorization/Content-Type/Accept.
Se expone WWW-Authenticate para errores de sesión.
allowCredentials=false: el API usa Bearer explícito, no cookies de autenticación.
CORS se procesa antes de FirebaseBearerFilter/Spring Security para el preflight.
No se abre una regla genérica OPTIONS permitAll ni se relaja el control de los endpoints.

El token sigue siendo obligatorio para /api/me/provision y /api/me.
GET/POST /api/users siguen bloqueados y biblioteca conserva ownership.
Las llamadas nativas Android sin Origin siguen funcionando.

## 8. Aplicar el origen y ejecutar Chrome

Elegir un puerto fijo del frontend para evitar cambiar la lista CORS en cada ejecución.
En la terminal/proceso que vaya a iniciar el backend, configurar:

$env:APP_CORS_ALLOWED_ORIGINS = "http://localhost:7357"

Cambiar la variable en otra terminal no reconfigura un proceso Java ya iniciado.
Spring no carga .env automáticamente: el archivo example solo documenta el nombre.
El responsable debe aplicar/reiniciar el backend en su entorno autorizado para cargar la propiedad.
El arranque normal puede ejecutar Flyway; no se inició ni se reinició ese servidor como parte de esta validación.

Desde android/, con archivo Web real ya completado:

flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=API_BASE_URL=http://localhost:8080 --dart-define-from-file=config/firebase_web.local.json

No se conserva el puerto aleatorio del comando anterior: CORS requiere el origen exacto.
No mezclar localhost con 127.0.0.1; son orígenes diferentes.
API_BASE_URL es el backend; APP_CORS_ALLOWED_ORIGINS es el FRONTEND.
La API local HTTP se permite en debug; para despliegue release debe utilizarse HTTPS.

## 9. Estado del servidor activo

Se envió únicamente un OPTIONS local a /api/me/provision:
- Origin: http://localhost:7357.
- Preflight para POST con authorization/content-type.
- Sin Authorization, sin body y sin ejecutar aprovisionamiento.
- Respuesta observada: HTTP 403, sin permitir ese origen.

Por tanto, el servidor activo todavía NO permite el origen propuesto.
No se verificó GET /api/me real ni se envió un token real.
No se realizó ninguna petición de datos a Neon ni modificación de sus tablas.
Los tests del API se ejecutaron en H2 en memoria y puertos aleatorios, no en localhost:8080.

## 10. Authentication y Google en Chrome

FirebaseAuthRepository ya diferenciaba Web/nativo y se conservó ese diseño:
- Web: FirebaseAuth.signInWithPopup(GoogleAuthProvider()).
- Android: GoogleSignIn.initialize/authenticate -> credencial Firebase.
- En ambos: el API recibe un Firebase ID token posterior, nunca un Google token como sustituto.

No se utiliza la API nativa google_sign_in.authenticate en Chrome.
No se agrega meta Google client ID ni un SDK JavaScript duplicado al HTML.
No hay endpoint backend especial para Google ni JWT propio.

Se añadieron mensajes seguros para unauthorized-domain, popup-blocked,
web-storage-unsupported, entorno no admitido y configuración no autorizada.
Los mensajes originales de SDK no se imprimen.

El registro Email/Password sigue requiriendo verificación de correo para el primer aprovisionamiento.
Una falla API después de Firebase login conserva la sesión y bloquea main hasta preparar /api/me.

## 11. Pruebas y resultados

| Validación | Resultado |
| --- | --- |
| mvn -o -B "-Dtest=*,!PostgresConnectionTests" test | 70 tests aprobados, 0 fallos/errores; PostgreSQL excluido |
| mvn -o -B -DskipTests package | BUILD SUCCESS; JAR actualizado sin ejecutarlo |
| flutter analyze --no-pub | No issues found |
| flutter test --no-pub | 65 aprobados y 1 omitido exclusivo de Chrome |
| Tests de configuración/mensajes reforzados en VM | 14 aprobados y 1 omitido exclusivo de Chrome |
| flutter build web --no-pub | Correcto; build/web; también pasó Wasm dry run |
| flutter build apk --debug --no-pub | Correcto; build/app/outputs/flutter-apk/app-debug.apk |
| Verificador local con fixtures | Coincidencia aceptada; proyecto distinto rechazado |
| Verificador con configuración real actual | Error esperado: falta archivo Web local |
| OPTIONS al backend activo | 403, origen local propuesto todavía no autorizado |
| git diff --check | Correcto, código 0 |
| Flyway V1-V3 | Sin cambios |

Nuevos tests backend: 4 de configuración y 8 HTTP/CORS.
Cubren origen exacto, puertos distintos, headers/métodos, preflight sin token,
401/403 con headers CORS, aprovisionamiento H2 y peticiones nativas sin Origin.

Los archivos generados de compilación son locales e ignorados. No se desplegó ninguna aplicación.

La prueba popup usa un FirebaseAuth fake, nunca abre Google ni crea usuarios.
La suite CORS usa H2 y FirebaseTokenVerifier mock.
La comprobación del proyecto usa JSON ficticios sin validez real.
Los builds sin definiciones reales validan compilación, NO configuración funcional del proyecto remoto.
No se usan cuentas, claves o tokens reales en tests.

Se conservan avisos preexistentes sobre KGP en plugins Firebase y H2/Flyway/Mockito.
No se cambiaron dependencias para ocultarlos.

## 12. Limitación de la ejecución automatizada Chrome

flutter test --no-pub --platform chrome test/firebase_configuration_test.dart test/firebase_web_auth_test.dart
se quedó en la carga del arnés y se interrumpió; NO se contabiliza como prueba aprobada.

Se inspeccionó únicamente el Chrome headless creado por ese test:
el arnés y su iframe cargaban módulos, pero no llegaban a iniciar los casos.
No se inspeccionaron pestañas personales ni sesiones de la aplicación del responsable.
La versión instalada de Flutter marca --platform chrome como opción deprecada de ese runner.

Esto no acredita un fallo de Firebase del proyecto ni demuestra que el popup real funcione.
Sí quedaron acreditados compilación Web/Android, tests nativos y CORS aislado.
La prueba exclusiva kIsWeb del popup se omite en VM; queda pendiente ejecutarla en un runner Web funcional
o comprobar el flujo real manual cuando se complete la configuración.

## 13. Secuencia de prueba E2E pendiente

1. Completar/verificar archivo local Web y confirmar dominios autorizados.
2. Aplicar CORS al proceso backend autorizado y ejecutar Chrome con origen fijo.
3. Entrar con Email/Password verificado o con Google.
4. Confirmar que la preparación realiza POST /api/me/provision -> 200 y GET /api/me -> 200.
5. Confirmar acceso a main únicamente después del paso anterior.
6. Cerrar/reabrir y cerrar sesión; verificar aislamiento entre cuentas.
7. Si aparece 409, conservar el conflicto seguro de cuenta legacy: no vincular por email.
8. Si aparece 503, revisar Firebase Admin/ADC y backend, sin borrar automáticamente la cuenta Firebase.

Este paso real crea/consulta el usuario interno en Neon y debe realizarlo el responsable en su entorno autorizado.
No compartir ID tokens o headers Authorization en capturas, archivos o reportes.

## 14. Seguridad y límites

- Sin migraciones nuevas y V1-V3 intactas.
- Sin cambios en Firebase Console.
- Sin login real, cuentas nuevas remotas ni escrituras Neon durante esta validación.
- Sin service account o contraseña en fuentes, archivo Web, logs o informes.
- Sin hardcodear proyecto Firebase real, API key real o URL de producción.
- Configuración Web local no creada con datos inventados: solo plantilla vacía.
- Sin cambios al aprovisionamiento seguro, claims, ownership o API stateless.
- Sin rediseño ni eliminación de módulos.
- Sin commit ni push.

Fuentes oficiales consultadas:
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/auth/faq-and-troubleshooting
- https://docs.spring.io/spring-security/reference/servlet/integrations/cors.html
- https://docs.spring.io/spring-framework/reference/web/webmvc-cors.html
