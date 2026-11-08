# Backend authentication ? Firebase ID tokens

The API verifies Firebase Authentication ID tokens using Firebase Admin 9.11.0.
Spring Security 7.1.1 is managed by Spring Boot 4.1.1; no custom JWT issuer or password authentication is configured.

## Request flow

`Authorization: Bearer <Firebase ID token>` -> `FirebaseBearerFilter` ->
`FirebaseTokenVerifier` -> Admin SDK `verifyIdToken(token, checkRevoked)` ->
`AuthenticatedFirebaseUser` -> `SecurityContext` -> `CurrentUserService` ->
`UserRepository.findByFirebaseUid` -> PostgreSQL user with its existing numeric ID.

The raw token is not retained in Authentication credentials, returned or logged.
UID, email and display name in the principal come only from the verified token.
Client-supplied userId/firebaseUid values do not determine identity.

## Credentials and startup

Keep credentials OUTSIDE the repository. Use Application Default Credentials (ADC).
For local Windows development, set variables only in the backend process terminal:

```powershell
$env:FIREBASE_PROJECT_ID = '<firebase-project-id>'
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\private\credentials\firebase-service-account.json'
# DB_URL / DB_USERNAME / DB_PASSWORD remain required for normal PostgreSQL startup.
mvn -B spring-boot:run
```

On managed hosting, ADC may instead use the workload/service identity; avoid long-lived keys when the platform supports it.
No JSON is read from src/main/resources. Do not paste secrets into application.properties or command arguments.
The Firebase project ID is nonsecret; it must match the project issuing the ID tokens.
This implementation requires FIREBASE_PROJECT_ID explicitly rather than guessing a project.

FirebaseApp/FirebaseAuth are lazy: missing Firebase configuration does not prevent
health/catalog and local H2 tests from starting. A protected request with a Bearer token
gets sanitized HTTP 503 if Admin cannot initialize. It never receives authenticated access.
Requests without credentials to protected paths get 401, independently of ADC availability.
A named app per project is reused under a process-wide lock across DevTools restarts.
The shared app is retained on context shutdown to support reuse, not recreated for every request.
The Firebase Auth emulator is deliberately rejected by production initialization; mock the verifier in tests.

Revocation/disabled-user checks default to true (`FIREBASE_CHECK_REVOKED=true`).
These checks may add Firebase network calls/latency. Setting false opts out of revocation checks,
not signature/audience/issuer/expiry validation; do not change without a session policy.
Invalid/revoked/expired tokens produce 401. Initialization/unavailable/internal identity service failures produce 503.

## HTTP policy and changed contracts

| Endpoint | Policy |
| --- | --- |
| GET /api/health | Public |
| GET /api/books | Public |
| GET /api/books/{id} | Public |
| POST /api/books | Verified Firebase identity required |
| GET/POST /api/users | Disabled: 401 without identity, 403 with identity |
| GET /api/me | Verified identity and linked internal user required |
| GET/POST /api/me/library | Verified identity and linked internal user required |
| PATCH/DELETE /api/me/library/{bookId} | Same, always own user |
| GET/POST /api/users/{userId}/library | Legacy route retained, own internal user only |
| PATCH/DELETE /api/users/{userId}/library/{bookId} | Legacy route retained, own internal user only |

All other requests require authentication by default; unknown paths then keep MVC behavior.
Public GET paths intentionally ignore Authorization headers, even invalid ones; they do not initialize Firebase.
Public catalog data is the current minimal bibliographic DTO. If publication/private works are introduced,
revisit these read permissions rather than exposing drafts under the same rule.

Legacy user management is denied for all identities: no admin role or provisioning API exists yet.
The old create/list methods remain internal domain operations; no public client can assign a UID.
Catalog POST is authenticated but does not yet have an editorial/admin role requirement.
Existing library path requests with another userId return 403 before LibraryService accesses that user's data.

## Linked user requirement

A valid token does not automatically create/link a PostgreSQL user.
GET /api/me returns the existing UserResponse without Firebase UID.
If the token UID has no linked user, return controlled HTTP 404 (Usuario no encontrado).
Email equality NEVER links a legacy account. Email/name returned by /me are the domain record,
not overwrites from token claims. A safe explicit provisioning/link process is a future block.
No new migration was required; V1/V2/V3 remain intact.

## REST errors and stateless behavior

Errors use status/message/details/timestamp, including filter-level 401/403/503.
401 includes WWW-Authenticate: Bearer. No stack traces, SDK messages, tokens or credential paths are returned.
Spring sessions are STATELESS, request cache disabled, no form login/HTTP Basic/logout/password user service.
CSRF is disabled for this Authorization-header API; no authentication cookie is used.
The filter is instantiated only in SecurityFilterChain, avoiding servlet registration twice.
Do not expose the API over plain HTTP outside local development; deploy using HTTPS.
No permissive CORS policy was added; Flutter Web integration needs a future explicit origin policy.

## Tests and deployment limits

Run `mvn -B test`, then `mvn -B -DskipTests package`.
HTTP tests replace only FirebaseTokenVerifier with a Mockito bean and exercise the real security chain.
SDK adapter tests mock FirebaseAuth; configuration lifecycle tests use a synthetic offline credential,
never call Google services and delete their test-only FirebaseApp.
MVP fixtures now create test users internally and associate synthetic test-only UIDs,
while production endpoints for arbitrary account creation remain denied.

PostgresConnectionTests is still conditional on DB_URL and can run Flyway on that database.
Do not set DB_URL to a shared/production database for ordinary local tests.
The local validation for this block uses H2 and no Neon credentials.
A real Firebase project/ADC and a legitimately linked user are required for a later live smoke test.

## Sources

- https://firebase.google.com/docs/admin/setup
- https://firebase.google.com/docs/auth/admin/verify-id-tokens
- https://firebase.google.com/support/release-notes/admin/java
- https://docs.spring.io/spring-security/reference/servlet/architecture.html
- https://docs.spring.io/spring-security/reference/servlet/authentication/session-management.html
