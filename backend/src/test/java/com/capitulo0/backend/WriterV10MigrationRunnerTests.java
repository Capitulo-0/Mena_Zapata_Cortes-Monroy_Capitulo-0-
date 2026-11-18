package com.capitulo0.backend;

import java.lang.reflect.*;
import java.sql.*;
import java.util.*;
import java.util.logging.Logger;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import org.flywaydb.core.api.resource.LoadableResource;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.*;
import org.flywaydb.core.api.callback.Callback;
import org.flywaydb.core.api.callback.Context;
import org.flywaydb.core.api.callback.Event;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class WriterV10MigrationRunnerTests {
    @BeforeAll static void quiet() { WriterV10ControlledMigrationTests.silenceSensitiveLibraryLogs(); }

    private Map<String, String> environment() {
        return new HashMap<>(Map.of("DB_URL", "jdbc:postgresql://fixture.neon.tech/example?sslmode=require",
            "DB_USERNAME", "fixture", "DB_PASSWORD", "fixture-secret",
            "WRITER_NEON_BRANCH", "perfil-v9-notifications",
            "WRITER_NEON_EXPECTED_HOST", "fixture.neon.tech"));
    }

    @Test void requiresIndependentHostAndExactAuthorizedBranch() {
        var env = environment();
        assertThat(WriterV10MigrationRunner.target(env).toString()).doesNotContain("fixture", "secret", "jdbc");
        for (String host : new String[]{"production.neon.tech", "fixture.neon.tech ", "https://fixture.neon.tech",
                "FIXTURE.neon.tech", ""}) {
            env.put("WRITER_NEON_EXPECTED_HOST", host);
            assertThatThrownBy(() -> WriterV10MigrationRunner.target(env))
                .isInstanceOf(WriterV10MigrationRunner.GuardFailure.class);
        }
        var missing = environment(); missing.remove("WRITER_NEON_EXPECTED_HOST");
        assertThatThrownBy(() -> WriterV10MigrationRunner.target(missing))
            .hasMessage("HOST_ESPERADO_INDEPENDIENTE_REQUERIDO");
        var production = environment(); production.put("WRITER_NEON_BRANCH", "production");
        assertThatThrownBy(() -> WriterV10MigrationRunner.target(production)).hasMessage("RAMA_NO_AUTORIZADA");
    }

    @Test void applyCannotEvenConnectWithoutExplicitConsentAndToken() {
        assertThatThrownBy(() -> WriterV10MigrationRunner.apply(Map.of()))
            .hasMessage("APLICACION_NO_AUTORIZADA");
        var env = environment(); env.put("WRITER_V10_CONFIRMATION", WriterV10MigrationRunner.CONFIRMATION);
        assertThatThrownBy(() -> WriterV10MigrationRunner.apply(env)).hasMessage("HUELLA_PREFLIGHT_REQUERIDA");
        env.put("WRITER_V10_PREFLIGHT_TOKEN", "not-a-token");
        assertThatThrownBy(() -> WriterV10MigrationRunner.apply(env)).hasMessage("HUELLA_PREFLIGHT_REQUERIDA");
    }

    @Test void changedPreflightFingerprintCannotAuthorizeMigration() {
        var checked = new WriterV10MigrationRunner.Preflight("a".repeat(64), 123);
        WriterV10MigrationRunner.requireMatchingToken(checked, Map.of("WRITER_V10_PREFLIGHT_TOKEN", "a".repeat(64)));
        assertThatThrownBy(() -> WriterV10MigrationRunner.requireMatchingToken(checked,
            Map.of("WRITER_V10_PREFLIGHT_TOKEN", "b".repeat(64))))
            .hasMessage("HUELLA_CAMBIO_REPETIR_PREFLIGHT");
    }

    private MigrationInfo info(String version, MigrationState state, String script, int checksum) {
        var info = mock(MigrationInfo.class);
        when(info.getVersion()).thenReturn(version == null ? null : MigrationVersion.fromVersion(version));
        when(info.getState()).thenReturn(state);
        when(info.getScript()).thenReturn(script);
        when(info.getChecksum()).thenReturn(checksum);
        return info;
    }

    private MigrationInfo[] plan() {
        var infos = new MigrationInfo[10];
        for (int i = 0; i < 9; i++) infos[i] = info("" + (i + 1), MigrationState.SUCCESS, "V" + (i + 1) + "__fixture.sql", i);
        infos[9] = info("10", MigrationState.PENDING, WriterV10MigrationRunner.SCRIPT, 123);
        return infos;
    }

    @Test void strictPlanRequiresExactlyNineSuccessfulMigrationsAndOnlyPendingTen() {
        assertThat(WriterV10MigrationRunner.checkPlan(plan())).isEqualTo(123);
        for (MigrationState state : new MigrationState[]{MigrationState.FAILED, MigrationState.MISSING_SUCCESS,
                MigrationState.OUT_OF_ORDER, MigrationState.BASELINE, MigrationState.PENDING}) {
            var infos = plan(); infos[3] = info("4", state, "V4__fixture.sql", 3);
            assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(infos))
                .isInstanceOf(WriterV10MigrationRunner.GuardFailure.class);
        }
        var repeatable = plan(); repeatable[3] = info(null, MigrationState.PENDING, "R__unexpected.sql", 3);
        assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(repeatable))
            .hasMessage("VERSION_DUPLICADA_O_REPEATABLE");
        var duplicate = plan(); duplicate[3] = duplicate[2];
        assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(duplicate))
            .hasMessage("VERSION_DUPLICADA_O_REPEATABLE");
        var future = Arrays.copyOf(plan(), 11); future[10] = info("11", MigrationState.ABOVE_TARGET, "V11__future.sql", 3);
        assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(future))
            .hasMessage("PLAN_DEBE_CONTENER_SOLO_V1_A_V10");
        var applied = plan(); applied[9] = info("10", MigrationState.SUCCESS, WriterV10MigrationRunner.SCRIPT, 123);
        assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(applied)).hasMessage("V10_NO_ES_UNICA_PENDIENTE");
        var wrongFile = plan(); wrongFile[9] = info("10", MigrationState.PENDING, "V10__unexpected.sql", 123);
        assertThatThrownBy(() -> WriterV10MigrationRunner.checkPlan(wrongFile)).hasMessage("V10_NO_ES_UNICA_PENDIENTE");
    }

    @Test void migrationCallbackRejectsWrongVersionChecksumScriptAndForbiddenOperations() {
        var callback = new WriterV10MigrationRunner.OnlyV10(123);
        var context = mock(Context.class);
        doReturn(plan()[9]).when(context).getMigrationInfo();
        callback.handle(Event.BEFORE_EACH_MIGRATE, context);
        for (MigrationInfo bad : new MigrationInfo[]{
                info("9", MigrationState.PENDING, WriterV10MigrationRunner.SCRIPT, 123),
                info("10", MigrationState.PENDING, WriterV10MigrationRunner.SCRIPT, 999),
                info("10", MigrationState.PENDING, "V10__unexpected.sql", 123)}) {
            when(context.getMigrationInfo()).thenReturn(bad);
            assertThatThrownBy(() -> callback.handle(Event.BEFORE_EACH_MIGRATE, context))
                .hasMessage("SOLO_V10_VERIFICADA_PUEDE_EJECUTARSE");
        }
        for (Event forbidden : new Event[]{Event.BEFORE_CLEAN, Event.BEFORE_BASELINE, Event.BEFORE_REPAIR, Event.BEFORE_UNDO}) {
            assertThat(callback.supports(forbidden, context)).isTrue();
            assertThatThrownBy(() -> callback.handle(forbidden, context)).hasMessage("OPERACION_FLYWAY_PROHIBIDA");
        }
    }

    @Test void readOnlyProxyPreventsDowngradeUnwrapAndLeaks() throws Exception {
        var connection = mock(Connection.class);
        var protectedConnection = WriterV10MigrationRunner.protectReadOnly(connection);
        assertThatThrownBy(() -> protectedConnection.setReadOnly(false)).isInstanceOf(SQLException.class);
        assertThatThrownBy(() -> protectedConnection.unwrap(Connection.class)).isInstanceOf(SQLException.class);
        assertThat(protectedConnection.toString()).doesNotContain("jdbc", "secret");
        verify(connection, never()).setReadOnly(false);
        protectedConnection.close();
        verify(connection).rollback();
        verify(connection).close();
        verify(connection, never()).commit();
    }

    private record PgFixture(DataSource source, Connection connection, List<String> queries) {}
    private PgFixture postgresMetadata(String overrideFragment, String overrideValue) throws Exception {
        var source = mock(DataSource.class);
        var connection = mock(Connection.class);
        var statement = mock(Statement.class);
        var queries = new ArrayList<String>();
        when(source.getConnection()).thenReturn(connection);
        when(connection.createStatement()).thenReturn(statement);
        when(statement.executeQuery(anyString())).thenAnswer(call -> {
            String sql = call.getArgument(0); queries.add(sql);
            String value = sql.startsWith("SELECT current_setting") ? "on"
                : sql.contains("to_regclass('public.writer_stories') IS NOT NULL") ? "false"
                : sql.contains("count(*)") ? "0" : "true";
            if (overrideFragment != null && sql.contains(overrideFragment)) value = overrideValue;
            var rows = mock(ResultSet.class);
            when(rows.next()).thenReturn(true, false);
            when(rows.getString(1)).thenReturn(value);
            return rows;
        });
        return new PgFixture(source, connection, queries);
    }

    @Test void postgresPrerequisitesUseOnlySelectAndRollbackBeforeClosing() throws Exception {
        var fixture = postgresMetadata(null, null);
        WriterV10MigrationRunner.checkPostgresPrerequisites(fixture.source(), false);
        assertThat(fixture.queries()).isNotEmpty().allMatch(sql -> sql.startsWith("SELECT"));
        verify(fixture.connection()).rollback(); verify(fixture.connection()).close();
        verify(fixture.connection(), never()).commit();
    }

    @Test void postgresMissingHistoryTableConflictsPermissionsAndInvalidSchemaBlock() throws Exception {
        String[][] faults = {
            {"flyway_schema_history') IS NOT NULL", "false", "HISTORIAL_NO_EXISTE"},
            {"to_regclass('public.writer_stories') IS NOT NULL", "true", "TABLA_WRITER_ESTADO_INESPERADO"},
            {"to_regclass('public.ix_writer_stories_owner_updated')", "false", "OBJETOS_WRITER_PREEXISTENTES"},
            {"has_schema_privilege", "false", "PERMISOS_MIGRACION_INSUFICIENTES"},
            {"c.contype='p'", "false", "USERS_PK_INCOMPATIBLE"},
            {"NOT convalidated", "1", "RESTRICCIONES_NO_VALIDAS"},
            {"NOT i.indisvalid", "1", "INDICES_NO_VALIDOS"},
            {"transaction_read_only", "off", "PREFLIGHT_NO_ES_SOLO_LECTURA"}
        };
        for (String[] fault : faults) {
            var fixture = postgresMetadata(fault[0], fault[1]);
            assertThatThrownBy(() -> WriterV10MigrationRunner.checkPostgresPrerequisites(fixture.source(), false))
                .hasMessage(fault[2]);
            verify(fixture.connection()).rollback(); verify(fixture.connection()).close();
            verify(fixture.connection(), never()).commit();
        }
    }

    private FluentConfiguration fixtureConfigure(DataSource source, Integer checksum) {
        return WriterV10MigrationRunner.configure(source, checksum).resourceProvider(new H2FixtureResources());
    }

    /** Test-only in-memory adaptation: H2 has no partial indexes. V9's two indexes
     * are full indexes here. Production resources and the V10 SQL remain unchanged. */
    static final class H2FixtureResources implements ResourceProvider {
        private final Map<String, LoadableResource> resources = new LinkedHashMap<>();
        H2FixtureResources() { this(false); }
        H2FixtureResources(boolean alteredV4) {
            String[] files = {"V1__initialize_backend.sql", "V2__create_users_books_library.sql",
                "V3__add_firebase_identity_to_users.sql", "V4__add_google_books_metadata.sql",
                "V5__add_user_profile_fields.sql", "V6__add_annual_reading_goal.sql",
                "V7__add_profile_privacy.sql", "V8__create_user_follows.sql",
                "V9__create_user_notifications.sql", WriterV10MigrationRunner.SCRIPT};
            for (String filename : files) {
                try (var stream = getClass().getClassLoader().getResourceAsStream("db/migration/" + filename)) {
                    if (stream == null) throw new IllegalStateException("Fixture SQL missing");
                    String sql = new String(stream.readAllBytes(), StandardCharsets.UTF_8);
                    if (filename.startsWith("V9__")) {
                        sql = sql.replace("WHERE read_at IS NULL", "").replace("WHERE follow_id IS NOT NULL", "");
                    }
                    if (alteredV4 && filename.startsWith("V4__")) {
                        sql += "\nALTER TABLE books ADD COLUMN fixture_drift_marker INTEGER;\n";
                    }
                    final String content = sql;
                    resources.put(filename, new LoadableResource() {
                        @Override public Reader read() { return new StringReader(content); }
                        @Override public String getAbsolutePath() { return "h2-fixture/" + filename; }
                        @Override public String getAbsolutePathOnDisk() { return getAbsolutePath(); }
                        @Override public String getFilename() { return filename; }
                        @Override public String getRelativePath() { return filename; }
                    });
                } catch (java.io.IOException error) { throw new IllegalStateException("Fixture unreadable"); }
            }
        }
        @Override public LoadableResource getResource(String name) { return resources.get(name); }
        @Override public Collection<LoadableResource> getResources(String prefix, String[] suffixes) {
            return resources.values().stream().filter(r -> r.getFilename().startsWith(prefix)
                && Arrays.stream(suffixes).anyMatch(suffix -> r.getFilename().endsWith(suffix))).toList();
        }
    }

    private JdbcDataSource fixtureV9Database() {
        var source = new JdbcDataSource();
        source.setURL("jdbc:h2:mem:v10-guard-" + UUID.randomUUID() +
            ";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        source.setUser("sa");
        fixtureConfigure(source, null).target("9").load().migrate();
        return source;
    }

    private long count(DataSource source, String sql) throws Exception {
        try (var c = source.getConnection(); var statement = c.createStatement(); var rows = statement.executeQuery(sql)) {
            rows.next(); return rows.getLong(1);
        }
    }

    @Test void actualFlywayPreflightAndSchemaValidationDoNotWriteToIsolatedH2() throws Exception {
        var source = fixtureV9Database();
        var readOnly = new NoWritesDataSource(source);
        long originalHistoryRows = count(source, "SELECT COUNT(*) FROM public.flyway_schema_history");
        var flyway = fixtureConfigure(readOnly, null).load();
        var first = WriterV10MigrationRunner.inspectFlyway(flyway, "test-target");
        WriterV10SchemaValidation.validate(readOnly, false, "org.hibernate.dialect.H2Dialect");
        var second = WriterV10MigrationRunner.inspectFlyway(flyway, "test-target");
        assertThat(first.token()).matches("[a-f0-9]{64}").isEqualTo(second.token());
        assertThat(WriterV10MigrationRunner.inspectFlyway(flyway, "another-target").token()).isNotEqualTo(first.token());
        assertThat(count(source, "SELECT COUNT(*) FROM public.flyway_schema_history WHERE version IS NOT NULL")).isEqualTo(9);
        assertThat(count(source, "SELECT COUNT(*) FROM public.flyway_schema_history")).isEqualTo(originalHistoryRows);
        assertThat(count(source, "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='writer_stories'")).isZero();
        assertThat(readOnly.queries).isNotEmpty();
    }

    @Test void guardedFlywayExecutesOnlyV10InMemoryAndRejectsAnotherPreflight() throws Exception {
        var source = fixtureV9Database();
        var preflight = WriterV10MigrationRunner.inspectFlyway(fixtureConfigure(source, null).load(), "test");
        var flyway = fixtureConfigure(source, preflight.checksum()).load();
        var config = flyway.getConfiguration();
        assertThat(config.isCleanDisabled()).isTrue();
        assertThat(config.isCreateSchemas()).isFalse();
        assertThat(config.isBaselineOnMigrate()).isFalse();
        assertThat(config.isOutOfOrder()).isFalse();
        assertThat(config.isExecuteInTransaction()).isTrue();
        assertThat(config.getTarget()).isEqualTo(MigrationVersion.fromVersion("10"));
        assertThat(config.isSkipDefaultCallbacks()).isTrue();
        var result = flyway.migrate();
        assertThat(result.success).isTrue();
        assertThat(result.migrationsExecuted).isEqualTo(1);
        assertThat(result.targetSchemaVersion).isEqualTo("10");
        WriterV10SchemaValidation.validate(new NoWritesDataSource(source), true, "org.hibernate.dialect.H2Dialect");
        assertThat(count(source, "SELECT COUNT(*) FROM public.flyway_schema_history WHERE version IS NOT NULL")).isEqualTo(10);
        assertThatThrownBy(() -> WriterV10MigrationRunner.inspectFlyway(flyway, "test"))
            .hasMessage("V10_NO_ES_UNICA_PENDIENTE");
        assertThatThrownBy(flyway::clean).isInstanceOf(Exception.class);
    }

    @Test void historyChecksumMismatchAndPhysicalSchemaDriftBlockPreparation() throws Exception {
        var source = fixtureV9Database();
        // Alter only a resource used for read-only validation, never the history table.
        assertThatThrownBy(() -> WriterV10MigrationRunner.inspectFlyway(
            fixtureConfigure(new NoWritesDataSource(source), null)
                .resourceProvider(new H2FixtureResources(true)).load(), "test"))
            .hasMessage("FLYWAY_VALIDACION_FALLIDA");
        var drifted = fixtureV9Database();
        try (var c = drifted.getConnection(); var statement = c.createStatement()) {
            statement.execute("ALTER TABLE public.users DROP COLUMN biography");
        }
        assertThatThrownBy(() -> WriterV10SchemaValidation.validate(
            new NoWritesDataSource(drifted), false, "org.hibernate.dialect.H2Dialect"))
            .isInstanceOf(Exception.class);
        assertThat(count(drifted, "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='writer_stories'")).isZero();
    }

    /** H2 cannot enforce PostgreSQL read-only mode. This independent test guard rejects
     * every persistent-write SQL while exercising real Flyway info/validate and Hibernate. */
    static final class NoWritesDataSource implements DataSource {
        final DataSource source;
        final List<String> queries = new ArrayList<>();
        NoWritesDataSource(DataSource source) { this.source = source; }
        private void check(String sql) throws SQLException {
            String normalized = sql.stripLeading().toUpperCase(Locale.ROOT);
            if (!(normalized.startsWith("SELECT") || normalized.startsWith("CALL SCHEMA")
                    || normalized.startsWith("SET SCHEMA") || normalized.startsWith("SET SEARCH_PATH"))) {
                throw new SQLException("Write blocked in local preflight test");
            }
            queries.add(sql);
        }
        private Object statement(Object statement, Class<?> type) {
            return Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[]{type}, (p, m, args) -> {
                if (m.getName().startsWith("execute") && args != null && args.length > 0 && args[0] instanceof String sql) check(sql);
                try { return m.invoke(statement, args); }
                catch (InvocationTargetException e) { throw e.getCause(); }
            });
        }
        @Override public Connection getConnection() throws SQLException {
            var c = source.getConnection();
            return (Connection) Proxy.newProxyInstance(Connection.class.getClassLoader(), new Class<?>[]{Connection.class}, (p, m, args) -> {
                if ((m.getName().equals("prepareStatement") || m.getName().equals("prepareCall"))
                        && args != null && args[0] instanceof String sql) check(sql);
                try {
                    Object result = m.invoke(c, args);
                    if (m.getName().equals("createStatement")) return statement(result, Statement.class);
                    return result;
                } catch (InvocationTargetException e) { throw e.getCause(); }
            });
        }
        @Override public Connection getConnection(String user, String password) throws SQLException { throw new SQLException("Not supported"); }
        @Override public PrintWriter getLogWriter() { return null; }
        @Override public void setLogWriter(PrintWriter writer) {}
        @Override public void setLoginTimeout(int seconds) {}
        @Override public int getLoginTimeout() { return 0; }
        @Override public Logger getParentLogger() { return Logger.getLogger("test"); }
        @Override public boolean isWrapperFor(Class<?> type) { return false; }
        @Override public <T> T unwrap(Class<T> type) throws SQLException { throw new SQLException("Not supported"); }
    }
}
