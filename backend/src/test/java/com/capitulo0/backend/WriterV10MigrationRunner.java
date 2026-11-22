package com.capitulo0.backend;

import java.io.PrintWriter;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;
import java.util.*;
import java.util.logging.Logger;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.*;
import org.flywaydb.core.api.callback.Callback;
import org.flywaydb.core.api.callback.Context;
import org.flywaydb.core.api.callback.Event;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import org.flywaydb.core.api.output.MigrateResult;

/** Independent, opt-in operational utility. Never loads Spring. */
final class WriterV10MigrationRunner {
    static final String BRANCH = "perfil-v9-notifications";
    static final String SCRIPT = "V10__create_writer_stories.sql";
    static final String CONFIRMATION = "AUTORIZO_V10_EN_perfil-v9-notifications";
    private WriterV10MigrationRunner() {}

    static final class Target {
        final WriterJdbcReadOnlyProbe.Configuration jdbc;
        private Target(WriterJdbcReadOnlyProbe.Configuration jdbc) { this.jdbc = jdbc; }
        @Override public String toString() { return "V10 target [REDACTED]"; }
    }

    record Preflight(String token, int checksum) {}

    static Target target(Map<String, String> environment) {
        require(BRANCH.equals(environment.get("WRITER_NEON_BRANCH")), "RAMA_NO_AUTORIZADA");
        String expected = environment.get("WRITER_NEON_EXPECTED_HOST");
        require(expected != null && expected.matches("[a-z0-9][a-z0-9.-]*\\.neon\\.tech"),
            "HOST_ESPERADO_INDEPENDIENTE_REQUERIDO");
        var jdbc = WriterJdbcReadOnlyProbe.configuration(environment);
        var uri = URI.create(jdbc.url().substring(5));
        require(expected.equals(uri.getHost()), "HOST_NO_COINCIDE_ABORTADO");
        require(uri.getPort() == -1 || uri.getPort() == 5432, "PUERTO_NEON_NO_ESPERADO");
        return new Target(jdbc);
    }

    static void requireConfirmation(Map<String, String> environment) {
        require(CONFIRMATION.equals(environment.get("WRITER_V10_CONFIRMATION")),
            "APLICACION_NO_AUTORIZADA");
        require(environment.getOrDefault("WRITER_V10_PREFLIGHT_TOKEN", "").matches("[a-f0-9]{64}"),
            "HUELLA_PREFLIGHT_REQUERIDA");
    }

    static Preflight preflight(Target target) throws Exception {
        var source = new PinnedDataSource(target, true);
        checkPostgresPrerequisites(source, false);
        try {
            WriterV10SchemaValidation.validate(source, false, "org.hibernate.dialect.PostgreSQLDialect");
        } catch (Exception error) { throw new GuardFailure("ESQUEMA_ENTIDADES_INCOMPATIBLE"); }
        return inspectFlyway(configure(source, null).load(), target.jdbc.url());
    }

    /** Read-only Flyway APIs plus strict policy. Pending is ignored ONLY by validate:
     * the complete info list below independently requires precisely V1..V9 + pending V10. */
    static Preflight inspectFlyway(Flyway flyway, String targetIdentity) throws Exception {
        var validation = flyway.validateWithResult();
        require(validation.validationSuccessful, "FLYWAY_VALIDACION_FALLIDA");
        var infos = flyway.info().all();
        int checksum = checkPlan(infos);
        var digest = MessageDigest.getInstance("SHA-256");
        digest.update((BRANCH + "\n" + targetIdentity + "\n").getBytes(StandardCharsets.UTF_8));
        for (int version = 1; version <= 10; version++) {
            final int v = version;
            var info = Arrays.stream(infos).filter(i -> MigrationVersion.fromVersion("" + v).equals(i.getVersion()))
                .findFirst().orElseThrow();
            digest.update((version + ":" + info.getScript() + ":" + info.getChecksum() + "\n")
                .getBytes(StandardCharsets.UTF_8));
        }
        return new Preflight(HexFormat.of().formatHex(digest.digest()), checksum);
    }

    static int checkPlan(MigrationInfo[] infos) {
        require(infos.length == 10, "PLAN_DEBE_CONTENER_SOLO_V1_A_V10");
        Set<MigrationVersion> found = new HashSet<>();
        Integer checksum = null;
        for (MigrationInfo info : infos) {
            var version = info.getVersion();
            require(version != null && found.add(version), "VERSION_DUPLICADA_O_REPEATABLE");
            if (MigrationVersion.fromVersion("10").equals(version)) {
                require(info.getState() == MigrationState.PENDING && SCRIPT.equals(info.getScript()),
                    "V10_NO_ES_UNICA_PENDIENTE");
                checksum = info.getChecksum();
                require(checksum != null, "V10_SIN_CHECKSUM");
            } else {
                require(version.compareTo(MigrationVersion.fromVersion("1")) >= 0
                    && version.compareTo(MigrationVersion.fromVersion("9")) <= 0
                    && info.getState() == MigrationState.SUCCESS, "V1_A_V9_NO_VALIDAS");
            }
        }
        for (int version = 1; version <= 10; version++) {
            require(found.contains(MigrationVersion.fromVersion("" + version)), "VERSION_REQUERIDA_AUSENTE");
        }
        require(checksum != null, "V10_AUSENTE");
        return checksum;
    }

    static void apply(Map<String, String> environment) throws Exception {
        // Consent is checked BEFORE any connection or writable datasource is constructed.
        requireConfirmation(environment);
        Target target = target(environment);
        Preflight checked = preflight(target);
        requireMatchingToken(checked, environment);
        Flyway flyway = configure(new PinnedDataSource(target, false), checked.checksum()).load();
        MigrateResult result = flyway.migrate();
        require(result.success && result.migrationsExecuted == 1
            && "10".equals(result.targetSchemaVersion), "APLICACION_NO_CONFIRMADA_REVISAR_SIN_REINTENTAR");
        // Fresh, read-only post-check. A post-check failure does not imply rollback of migrate.
        var readOnly = new PinnedDataSource(target, true);
        checkPostgresPrerequisites(readOnly, true);
        WriterV10SchemaValidation.validate(readOnly, true, "org.hibernate.dialect.PostgreSQLDialect");
        var post = configure(readOnly, null).load();
        require(post.validateWithResult().validationSuccessful, "POST_VALIDACION_FALLIDA");
        var infos = post.info().all();
        require(infos.length == 10 && Arrays.stream(infos).allMatch(i -> i.getState() == MigrationState.SUCCESS),
            "POST_HISTORIAL_INCONSISTENTE");
    }

    static void requireMatchingToken(Preflight checked, Map<String, String> environment) {
        require(checked.token().equals(environment.get("WRITER_V10_PREFLIGHT_TOKEN")),
            "HUELLA_CAMBIO_REPETIR_PREFLIGHT");
    }

    static FluentConfiguration configure(DataSource source, Integer allowedChecksum) {
        var config = Flyway.configure()
            .dataSource(source).locations("classpath:db/migration").defaultSchema("public").schemas("public")
            .table("flyway_schema_history").target("10").cleanDisabled(true).createSchemas(false)
            .baselineOnMigrate(false).outOfOrder(false).validateOnMigrate(true).validateMigrationNaming(true)
            .failOnMissingLocations(true).executeInTransaction(true).group(true).mixed(false)
            .placeholderReplacement(false).connectRetries(0).lockRetryCount(5)
            .ignoreMigrationPatterns("*:pending").skipDefaultCallbacks(true).loggers("com.capitulo0.backend.WriterV10SilentLogCreator");
        // No file callbacks or external config files/envVars are loaded.
        if (allowedChecksum != null) config.callbacks(new OnlyV10(allowedChecksum));
        return config;
    }

    static final class OnlyV10 implements Callback {
        private final int checksum;
        OnlyV10(int checksum) { this.checksum = checksum; }
        @Override public boolean supports(Event event, Context context) {
            return Set.of(Event.BEFORE_EACH_MIGRATE, Event.BEFORE_CLEAN, Event.BEFORE_BASELINE,
                Event.BEFORE_REPAIR, Event.BEFORE_UNDO).contains(event);
        }
        @Override public boolean canHandleInTransaction(Event event, Context context) { return true; }
        @Override public void handle(Event event, Context context) {
            require(event == Event.BEFORE_EACH_MIGRATE, "OPERACION_FLYWAY_PROHIBIDA");
            var info = context.getMigrationInfo();
            require(info != null && MigrationVersion.fromVersion("10").equals(info.getVersion())
                && SCRIPT.equals(info.getScript()) && Objects.equals(checksum, info.getChecksum()),
                "SOLO_V10_VERIFICADA_PUEDE_EJECUTARSE");
        }
        @Override public String getCallbackName() { return "writer-only-verified-v10"; }
    }

    static void checkPostgresPrerequisites(DataSource source, boolean applied) throws SQLException {
        try (var connection = source.getConnection()) {
            connection.setAutoCommit(false);
            try (var statement = connection.createStatement()) {
                statement.setQueryTimeout(15);
                require("on".equals(text(statement, "SELECT current_setting('transaction_read_only')")),
                    "PREFLIGHT_NO_ES_SOLO_LECTURA");
                require("true".equals(text(statement,
                    "SELECT (to_regclass('public.flyway_schema_history') IS NOT NULL)::text")),
                    "HISTORIAL_NO_EXISTE");
                require(Boolean.toString(applied).equals(text(statement,
                    "SELECT (to_regclass('public.writer_stories') IS NOT NULL)::text")),
                    "TABLA_WRITER_ESTADO_INESPERADO");
                // Also catch conflicting index/identity sequence names left by manual DDL.
                if (!applied) {
                    require("true".equals(text(statement,
                        "SELECT (to_regclass('public.ix_writer_stories_owner_updated') IS NULL "
                        + "AND to_regclass('public.writer_stories_id_seq') IS NULL "
                        + "AND to_regclass('public.writer_stories_pkey') IS NULL "
                        + "AND to_regclass('public.writer_stories_story_key_key') IS NULL)::text")),
                        "OBJETOS_WRITER_PREEXISTENTES");
                }
                require("true".equals(text(statement,
                    "SELECT (has_schema_privilege(current_user,'public','USAGE') "
                    + "AND has_schema_privilege(current_user,'public','CREATE') "
                    + "AND has_table_privilege(current_user,'public.users','REFERENCES') "
                    + "AND has_table_privilege(current_user,'public.flyway_schema_history','SELECT') "
                    + "AND has_table_privilege(current_user,'public.flyway_schema_history','INSERT') "
                    + "AND has_table_privilege(current_user,'public.flyway_schema_history','UPDATE'))::text")),
                    "PERMISOS_MIGRACION_INSUFICIENTES");
                require("true".equals(text(statement,
                    "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' "
                    + "AND table_name='users' AND column_name='id' AND data_type='bigint' AND is_nullable='NO')::text")),
                    "USERS_ID_INCOMPATIBLE");
                require("true".equals(text(statement,
                    "SELECT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_attribute a "
                    + "ON a.attrelid=c.conrelid AND a.attname='id' WHERE c.conrelid='public.users'::regclass "
                    + "AND c.contype='p' AND c.conkey=ARRAY[a.attnum] AND c.convalidated)::text")),
                    "USERS_PK_INCOMPATIBLE");
                require("0".equals(text(statement,
                    "SELECT count(*)::text FROM pg_constraint WHERE connamespace='public'::regnamespace AND NOT convalidated")),
                    "RESTRICCIONES_NO_VALIDAS");
                require("0".equals(text(statement,
                    "SELECT count(*)::text FROM pg_index i JOIN pg_class c ON c.oid=i.indrelid "
                    + "JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT i.indisvalid")),
                    "INDICES_NO_VALIDOS");
            } finally {
                connection.rollback();
            }
        }
    }

    private static String text(Statement statement, String sql) throws SQLException {
        try (var rows = statement.executeQuery(sql)) {
            require(rows.next(), "CONSULTA_SIN_RESULTADO");
            return rows.getString(1);
        }
    }

    static void require(boolean condition, String code) {
        if (!condition) throw new GuardFailure(code);
    }
    static final class GuardFailure extends RuntimeException {
        GuardFailure(String code) { super(code, null, false, false); }
    }

    /** PG server enforces read-only even if Flyway temporarily uses autocommit.
     * The proxy also refuses switching readOnly off or unwrapping the connection. */
    static Connection protectReadOnly(Connection connection) {
        return (Connection) Proxy.newProxyInstance(Connection.class.getClassLoader(),
            new Class<?>[]{Connection.class}, (proxy, method, args) -> {
                String name = method.getName();
                if (name.equals("setReadOnly") && Boolean.FALSE.equals(args[0])) {
                    throw new SQLException("Read-only guard", "25006");
                }
                if (name.equals("unwrap")) throw new SQLException("Unwrap disabled", "25006");
                if (name.equals("isWrapperFor")) return false;
                if (name.equals("toString")) return "Writer read-only connection [REDACTED]";
                try {
                    if (name.equals("close") && !connection.isClosed() && !connection.getAutoCommit()) connection.rollback();
                    return method.invoke(connection, args);
                } catch (InvocationTargetException e) { throw e.getCause(); }
            });
    }

    static final class PinnedDataSource implements DataSource {
        private final Target target;
        private final boolean readOnly;
        PinnedDataSource(Target target, boolean readOnly) { this.target = target; this.readOnly = readOnly; }
        @Override public Connection getConnection() throws SQLException {
            Properties props = new Properties();
            props.putAll(target.jdbc.properties());
            props.setProperty("readOnly", Boolean.toString(readOnly));
            props.setProperty("readOnlyMode", "always");
            Connection connection = DriverManager.getConnection(target.jdbc.url(), props);
            try {
                connection.setReadOnly(readOnly);
                if (readOnly) {
                    try (var statement = connection.createStatement()) {
                        statement.setQueryTimeout(15);
                        require("on".equals(text(statement, "SELECT current_setting('transaction_read_only')")),
                            "PREFLIGHT_NO_ES_SOLO_LECTURA");
                    }
                    return protectReadOnly(connection);
                }
                return connection;
            } catch (Exception e) {
                connection.close();
                throw e;
            }
        }
        @Override public Connection getConnection(String user, String password) throws SQLException {
            throw new SQLException("Explicit credentials only");
        }
        @Override public PrintWriter getLogWriter() { return null; }
        @Override public void setLogWriter(PrintWriter writer) {}
        @Override public void setLoginTimeout(int seconds) {}
        @Override public int getLoginTimeout() { return 10; }
        @Override public Logger getParentLogger() { return Logger.getLogger("org.postgresql"); }
        @Override public boolean isWrapperFor(Class<?> type) { return false; }
        @Override public <T> T unwrap(Class<T> type) throws SQLException { throw new SQLException("Unwrap disabled"); }
        @Override public String toString() { return "Pinned Writer datasource [REDACTED]"; }
    }
}
