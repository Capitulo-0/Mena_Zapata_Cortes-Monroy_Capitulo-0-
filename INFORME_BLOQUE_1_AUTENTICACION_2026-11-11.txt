# Bloque 1 — Autenticación y aprovisionamiento

Fecha: 11/11/2026. Rama: feature/backend-core-completion.
No se hizo commit, push, migración en Neon ni cambio en Firebase Console.
V1/V2/V3 permanecen intactas. La auditoría TXT anterior es una fotografía del estado previo y no se sobrescribió.

## Resultado y alcance

Se implementó el recorrido Android/Flutter -> Firebase Auth -> ID token -> API Bearer ->
Firebase Admin -> principal verificado -> aprovisionamiento -> usuario SQL -> GET /api/me.
La implementación y las comprobaciones locales están completas; la prueba con Firebase y Neon reales no se ejecutó.
La navegación principal requiere confirmación del backend; autenticarse en Firebase por sí solo no abre main.

Se mantienen las pantallas y módulos existentes. Se conectaron sus controles de Auth y logout.
La recuperación conserva cabecera, estilo y formulario, pero sustituye el código ficticio por un enlace real.
Se añadió una pantalla funcional de preparación/verificación/error con los componentes visuales existentes.
No se conectó biblioteca ni Writer al backend, ni se implementaron los otros bloques.

## 1. Archivos creados

Backend:
- backend/src/main/java/com/capitulo0/backend/auth/service/UserProvisioningService.java
- backend/src/test/java/com/capitulo0/backend/ProvisioningEndpointTests.java
- backend/src/test/java/com/capitulo0/backend/UserProvisioningServiceTests.java

Flutter (rutas relativas a android/):
- lib/core/network/api_client.dart
- lib/core/session/local_account_scope.dart
- lib/features/auth/domain/auth_repository.dart
- lib/features/auth/domain/domain_user.dart
- lib/features/auth/data/firebase_auth_repository.dart
- lib/features/auth/data/account_repository.dart
- lib/features/auth/presentation/controllers/session_controller.dart
- lib/features/auth/presentation/screens/session_preparation_screen.dart
- test/support/auth_fakes.dart
- test/api_client_test.dart
- test/auth_session_test.dart
- test/auth_navigation_test.dart
- test/local_account_storage_test.dart

Documentación:
- BLOQUE_1_AUTENTICACION.md (este archivo).

El TXT AUDITORIA_TECNICA_INTEGRAL_CAPITULO_0_2026-11-10.txt ya existía al iniciar este bloque.

## 2. Archivos modificados

Backend:
- auth/model/AuthenticatedFirebaseUser.java: emailVerified y constructor compatible que NO lo presupone verificado.
- auth/service/FirebaseAdminTokenVerifier.java: copia isEmailVerified() exclusivamente del token validado.
- auth/service/CurrentUserService.java: expone requireIdentity para el caso sin usuario interno aún.
- auth/controller/MeController.java: añade POST /api/me/provision.
- src/test/java/com/capitulo0/backend/FirebaseAdminTokenVerifierTests.java: verificación explícita del claim.
- AUTHENTICATION.md: contrato, política y comandos seguros.

Flutter, bajo android/:
- pubspec.yaml y pubspec.lock.
- .gitignore: ignora únicamente la nueva caché nativa /android/.kotlin/; no la borra.
- lib/main.dart: inicialización Firebase y error de arranque sanitizado con reintento.
- lib/app.dart: sesión observable, gate de preparación, invitado, logout, claves por cuenta y limpieza de stores.
- lib/features/auth/presentation/controllers/auth_controller.dart.
- lib/features/auth/presentation/controllers/forgot_password_controller.dart.
- lib/features/auth/presentation/screens/auth_screen.dart.
- lib/features/auth/presentation/screens/forgot_password_screen.dart.
- lib/features/auth/presentation/widgets/auth_common_widgets.dart.
- lib/features/auth/presentation/widgets/auth_login_form.dart.
- lib/features/auth/presentation/widgets/auth_register_form.dart.
- lib/features/auth/presentation/widgets/forgot_password_widgets.dart.
- lib/features/home/presentation/screens/main_shell_screen.dart: nombre del usuario actual y servicio local con scope; eliminación de cuenta no simula una eliminación real.
- lib/features/library/presentation/widgets/book_interaction_store.dart: limpieza de memoria al salir/cambiar cuenta.
- lib/features/writer/services/writer_local_service.dart: namespace opcional por cuenta.
- lib/features/writer/presentation/screens/writer_screen.dart.
- lib/features/writer/presentation/screens/create_story_screen.dart.
- lib/features/writer/presentation/screens/manage_story_screen.dart.
- lib/features/writer/presentation/screens/chapter_editor_screen.dart.
- lib/features/writer/presentation/screens/published_story_screen.dart.
  Los cambios Writer solo propagan el scope a datos locales; no eliminan su funcionalidad ni añaden API.
- android/app/src/debug/AndroidManifest.xml: HTTP de desarrollo explícito solo en debug.

User, UserRepository, UserService, UserResponse, UserMapper, SecurityConfiguration,
FirebaseBearerFilter y las migraciones se reutilizan sin cambios de comportamiento/esquema.

## 3. Dependencias agregadas

Versiones directas resueltas por pub:
- firebase_core ^5.1.0
- firebase_auth ^7.0.1
- google_sign_in ^7.2.0
- http ^1.6.0 (ya existía transitivamente; ahora es directa).

Pub resolvió las dependencias con el Flutter/Dart instalado. No se añadió SDK Firebase manual a Gradle,
BOM nativo ni service account en la aplicación. Los plugins oficiales gestionan los SDK nativos.

## 4. Arquitectura final

AuthRepository define las operaciones sin obligar a los tests a inicializar Firebase.
FirebaseAuthRepository adapta el SDK y transforma errores en AuthFailure, sin exponer excepciones internas.
SessionController observa authStateChanges y coordina:
signedOut / verificationRequired / preparing / backendFailure / ready / guest.
ApiAccountRepository ejecuta POST provision y luego GET me.
ApiClient incorpora el token de la identidad actual, valida URL, aplica timeout y trata errores sanitizados.
DomainUser contiene únicamente id interno, email y displayName.

AppStage se deriva de la sesión. Conserva splash y tema, pero no usa un bool como autoridad de autenticación.
Cambiar de identidad o salir dispone las rutas secundarias y la pantalla principal de la cuenta.
Una respuesta tardía de otra sesión no puede activar ready para la cuenta actual.

## 5. Aprovisionamiento seguro

POST /api/me/provision no recibe un DTO de identidad.
Los atributos vienen del Authentication creado por FirebaseBearerFilter y Firebase Admin.

- UID encontrado: 200 con el usuario existente; no sobrescribe email/nombre de dominio.
- UID nuevo + email válido/verificado sin colisión: crea User y devuelve 200.
- Email ausente, no verificado o inválido: 400 controlado; no inventa email.
- Email de una cuenta legacy sin UID: 409, sin modificarla.
- Email de otro UID: 409, sin reasignación.
- Ninguna coincidencia de email autoriza vinculación.

Se conservan ID numérico y restricciones UNIQUE de V2/V3.
La escritura se realiza en una transacción independiente. Si falla por unicidad, se completa el rollback
antes de consultar de nuevo el UID en otra transacción.
También se reconsulta el UID cuando el email aparece ocupado entre las consultas previas al insert.
Esto resuelve la ventana de concurrencia detectada durante los tests sin vincular por email.

La política actual no importa ni migra usuarios legacy. Ese proceso requiere un diseño explícito posterior.
No se almacena emailVerified en SQL ni hace falta una nueva migración para este bloque.

## 6. Endpoints

Nuevo:
POST /api/me/provision
Authorization: Bearer <Firebase ID token>
Sin body necesario. Query/JSON con userId/firebaseUid/email/nombre no determina identidad.
200 UserResponse tanto al crear como al repetir.

GET /api/me conserva selección exclusivamente por UID autenticado y no tiene side effects de alta.
Antes de provisionar puede responder 404; tras alta correcta responde 200.
UserResponse no incluye firebase_uid.
GET/POST /api/users permanecen denegados; las rutas legacy de biblioteca conservan requireOwner.
La seguridad sigue STATELESS y no se creó JWT propio, sesión servidor ni almacenamiento de contraseñas.

## 7. Flutter Auth y verificación de correo

Los controles visuales se conservan y ejecutan operaciones Firebase reales.
simulateLogin/simulateRegister/simulateGuest dejan de ser fuente de identidad.
Registro crea la cuenta Firebase, actualiza su nombre y solicita un correo de verificación.
No se envían fecha de nacimiento/género a la API porque el esquema de perfil aún no existe; los controles
visuales permanecen. Su persistencia corresponde al bloque de perfil, no se simula como guardada en SQL.

Una cuenta Email/Password nueva necesita verificar el correo para el primer aprovisionamiento:
abrir enlace -> regresar -> “Ya verifiqué mi correo” -> reload -> refresh de ID token -> provision -> me.
Se puede reenviar el enlace. No se elimina una cuenta Firebase por fallo temporal de la API o del envío.
En una restauración de sesión también se aplica el gate de preparación.

## 8. Google Sign-In

Android usa google_sign_in 7.2.0:
GoogleSignIn.instance.initialize() una vez -> authenticate() -> account.authentication.idToken
-> GoogleAuthProvider.credential -> FirebaseAuth.signInWithCredential.
El token que se envía al backend es el Firebase ID token posterior, nunca el Google token.
No hay tratamiento especial del proveedor en Spring.

El cliente OAuth web requerido por la integración Android se detectó presente en el JSON local;
solo se comprobó un booleano, sin imprimir IDs, claves o contenido del archivo.
No se comprobó la configuración remota ni los certificados de Console.
Para web se usa el popup oficial Firebase GoogleAuthProvider; Firebase web/iOS requieren configuración
de plataforma adicional que no se generó aquí. El primer objetivo validado por compilación es Android.

## 9. Recuperación

ForgotPasswordController usa AuthRepository.sendPasswordResetEmail.
La interfaz tiene solicitud de enlace y confirmación de envío; desaparecen el código de seis dígitos
y el cambio de contraseña falsos dentro de la app.
El cambio de contraseña ocurre en el enlace Firebase.
La confirmación de envío no afirma haber cambiado la contraseña.

## 10. Logout y datos locales

FirebaseAuth.signOut es autoritativo. La limpieza Google es best effort y no bloquea el signOut Firebase.
Se limpia DomainUser y se reinician privacidad, bloqueos, género y respuestas en memoria.
La pantalla principal/rutas se recrean por cuenta y el modo invitado tiene su propio scope.

Writer usa writer_stories_<uid> y respuestas published_story_replies_<uid>_<storyId>
en la ejecución real de la app. El scope también envuelve el Navigator para alcanzar rutas secundarias.
Los servicios capturan su scope al construirse, evitando escribir bajo otra cuenta al completar una operación tardía.
Los consumidores sin scope mantienen compatibilidad con las claves anteriores (incluidos tests existentes).
No se borran ni se asignan automáticamente a una cuenta los borradores legacy de writer_stories.
No se almacenan tokens ni contraseñas en SharedPreferences.

Esto no sustituye un backend Writer ni cifra el contenido local. Se necesita definir importación explícita
de datos anteriores, sincronización y gestión local cuando se desarrollen los siguientes bloques.

## 11. API client y configuración

No existe base URL por defecto ni una URL de producción hardcodeada.
Se suministra por compilación:

flutter run --dart-define=API_BASE_URL=https://<host-del-backend>
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=https://<host-del-backend>

Ejemplo SOLO de desarrollo con backend local ya autorizado:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

10.0.2.2 es el host del equipo desde Android Emulator; un dispositivo físico requiere otra dirección alcanzable.
Estos valores son ejemplos de ejecución, no constantes de la aplicación.
API_BASE_URL debe apuntar a la raíz/base de despliegue; los endpoints ya añaden /api/....
Se rechazan URLs con userinfo, query o fragment y se exige HTTPS fuera de debug.
El manifest de debug permite HTTP; no se habilita cleartext globalmente para release.

Cada request obtiene getIdToken de la cuenta actual, añade Authorization y, cuando hay body, JSON.
Ante 401 renueva una sola vez y repite; no hace bucles ilimitados.
No sigue redirecciones para evitar reenviar Bearer a otro origen.
Fija el UID de la petición y rechaza el resultado si la cuenta cambió.
Aplica timeout al envío/lectura y no muestra ni registra body de error, tokens o detalles internos.

El APK generado con el comando solicitado SIN dart-define prueba compilación; para el E2E hay que ejecutar
o compilar con API_BASE_URL del entorno. Sin esa definición la app conserva Firebase pero explica que falta la API.

## 12. Errores

Auth: email inválido/en uso, contraseña débil, credenciales incorrectas/usuario no encontrado,
cuenta deshabilitada, cancelación Google, red, límite de intentos y desconocidos.
La respuesta de credenciales es deliberadamente genérica.
API: 400/422, 401, 403, 404, 409, 503, timeout y respuesta inválida.
Login Firebase correcto + fallo API produce backendFailure con reintento y cierre de sesión;
no borra la cuenta Firebase ni presenta main como listo.
Un conflicto legacy explica la necesidad de vinculación segura, sin ofrecer tomar control por email.

## 13. Tests backend

Sin credenciales reales, Firebase mock y H2:
- UID nuevo y claims verificados.
- Repetición con mismo ID.
- Body/query no seleccionan identidad.
- Email ausente, inválido o no verificado.
- Colisión legacy y UID diferente.
- GET me después de provision y DTO sin UID.
- /api/users sigue bloqueado.
- Concurrencia mismo UID y dos UID para mismo email.
- Recuperación determinista de la carrera antes del insert.
- Recuperación tras rollback de restricción UNIQUE.
- Propagación real del claim email_verified en el adaptador mockeado.
- Tests anteriores de ownership de biblioteca permanecen.

Una repetición detectó una carrera antes del insert; se corrigió y se añadieron las pruebas deterministas.
La última suite backend seleccionada pasó 58 tests. PostgresConnectionTests se excluyó explícitamente.
H2 y mocks no prueban PostgreSQL ni un JWT real de Firebase.

## 14. Tests Flutter

Sin Firebase real: AuthRepository/AccountRepository fake y MockClient HTTP.
Se conservaron los 20 casos anteriores y se añadieron 31, para 51 tests:
sesión inicial, login/error, Google/cancelación, logout, email verificado, aprovisionamiento,
401/409/503, refresh único, URLs inseguras, timeout, cambio de cuenta, modo invitado,
gate de navegación, rutas secundarias y aislamiento/conservación de Writer local.
Los tests de widgets reutilizan fuentes locales y no descargan tipografías.

## 15. Resultados de validación

| Comando | Resultado final |
| --- | --- |
| mvn -o -B "-Dtest=*,!PostgresConnectionTests" test | BUILD SUCCESS; 58 tests, 0 fallos, 0 errores; PostgreSQL excluido explícitamente |
| mvn -o -B -DskipTests package | BUILD SUCCESS; JAR reempaquetado |
| flutter pub get | Correcto; dependencias resueltas |
| flutter analyze --no-pub | No issues found |
| flutter test --no-pub | 51 tests aprobados |
| flutter build apk --debug --no-pub | Correcto; APK debug generado |
| git diff --check | Correcto, código 0 |
| Diff V1/V2/V3 | Vacío; migraciones intactas |

APK: android/build/app/outputs/flutter-apk/app-debug.apk.
Último build final: 11/11/2026 00:24 America/Santiago; tamaño observado 205410907 bytes.
JAR: backend/target/backend-0.0.1-SNAPSHOT.jar.
No se instaló ni ejecutó la app ni el JAR. Los builds/tests escribieron únicamente artefactos locales.
La compilación por sí sola no valida ADC, certificados ni conectividad real con Firebase/Neon.

El build Android mostró avisos sobre Kotlin Gradle Plugin en plugins Firebase y versiones del procesador XML
del Android SDK; compiló correctamente en la ejecución inicial. No se agregó SDK Firebase manualmente.
Gradle instaló la plataforma Android 34 requerida en el SDK local durante el build.
Maven avisa de native access/Unsafe/Mockito; Flyway de la versión H2 verificada; no fueron fallos funcionales.
Un test usa API de conversión Jackson marcada deprecada; no afecta al código de producción.

## 16. Comprobaciones de seguridad

- V1/V2/V3 sin modificar; ninguna migración nueva.
- No se inició backend normal con variables Neon ni se ejecutó PostgresConnectionTests.
- No hay llamadas reales Firebase en tests, ni usuarios reales creados durante la validación.
- google-services.json y secrets.properties permanecen ignorados.
- Ninguna service account nueva se creó/copió al repositorio.
- Ningún project ID o API URL real se hardcodeó.
- No hay logs de tokens ni persistencia de contraseña en el código añadido.
- UID y email_verified provienen exclusivamente del token verificado en Spring.
- No auto-link por email, /api/users cerrado y /api/me sin selector cliente.
- Los SDK manejan las credenciales Firebase; no se creó JWT propio.
- Sin commit ni push.

## 17. Riesgos y deuda pendiente

- Falta probar Firebase Admin/ADC, certificados Google y claims reales en el proyecto remoto.
- Falta probar esquema y concurrencia PostgreSQL en un entorno dedicado autorizado; H2 no lo acredita.
- Usuarios legacy con mismo email seguirán recibiendo 409 hasta diseñar vinculación segura.
- Política de email obligatorio/verificado es explícita; no se admiten altas nuevas sin ese claim.
- Perfil completo, DOB/género, avatar y username todavía no tienen persistencia de dominio.
- Biblioteca y otros módulos siguen con su estado demo/local; este bloque no los conecta.
- Writer antiguo no se migra automáticamente a la cuenta actual, ni se elimina.
- CORS explícito y configuración Firebase para web/iOS siguen pendientes para esas plataformas.
- No hay eliminación de cuenta real ni revocación global de sesiones; logout cliente no equivale a revocar todos los tokens emitidos.
- No se añadió rate limiting ni rol editorial/admin; las restricciones previas se conservan.
- No hay despliegue del backend dentro de este trabajo.

## 18. Pasos exactos pendientes para E2E real Firebase + Neon

NO ejecutados:
1. Autorizar expresamente el arranque/prueba sobre la base seleccionada.
   El arranque normal ejecuta Flyway y el primer provision inserta en users.
2. Confirmar que la base autorizada está en V3 y preparar DB_URL/DB_USERNAME/DB_PASSWORD
   exclusivamente fuera del repositorio. No hay una migración nueva que aplicar para este bloque.
3. Preparar FIREBASE_PROJECT_ID y ADC/GOOGLE_APPLICATION_CREDENTIALS fuera del repo,
   del mismo proyecto que emite los tokens Android.
4. Iniciar backend en el entorno autorizado, comprobar conectividad y endpoint health.
5. Ejecutar/compilar Android con API_BASE_URL alcanzable. El APK de validación sin define no configura una API.
6. Cuenta Email/Password nueva: registro -> enlace de verificación -> regreso -> preparar cuenta.
7. Confirmar POST provision 200 y GET me 200, mismo ID interno tras repetir/reabrir.
8. Probar Google en el dispositivo/emulador con certificados correspondientes y el mismo flujo.
9. Verificar conflicto legacy controlado sin alteración de su UID; segunda cuenta aislada.
10. Probar desconexión API, reintento, cierre/reapertura y logout.
No pegar tokens, credenciales, service accounts o contenido del JSON en logs ni en este informe.

Referencias oficiales consultadas para el SDK:
- https://pub.dev/packages/firebase_core
- https://pub.dev/packages/firebase_auth
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/http
- https://firebase.google.com/docs/auth/flutter/federated-auth
