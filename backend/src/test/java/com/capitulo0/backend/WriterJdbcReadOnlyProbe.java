package com.capitulo0.backend;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

/** Test utility only. Does not initialize any application framework. */
final class WriterJdbcReadOnlyProbe {
    private WriterJdbcReadOnlyProbe() {}

    // Deliberately not a record: its generated toString would expose the JDBC URL.
    static final class Configuration {
        private final String url;
        private final Properties properties;
        Configuration(String url, Properties properties) {
            this.url = url;
            this.properties = properties;
        }
        String url() { return url; }
        Properties properties() { return properties; }
        @Override public String toString() { return "JDBC configuration [REDACTED]"; }
    }

    record Report(boolean historyExists, String v10, boolean storiesExist) {}

    static Configuration configuration(Map<String, String> environment) {
        String url = required(environment, "DB_URL");
        String username = required(environment, "DB_USERNAME");
        String password = required(environment, "DB_PASSWORD");
        if (!url.startsWith("jdbc:postgresql://")) {
            throw new IllegalArgumentException("CONFIGURACION_INVALIDA");
        }
        var uri = URI.create(url.substring("jdbc:".length()));
        String host = uri.getHost();
        if (host == null || !host.endsWith(".neon.tech") || uri.getUserInfo() != null
                || uri.getFragment() != null || uri.getPath() == null || uri.getPath().length() < 2) {
            throw new IllegalArgumentException("CONFIGURACION_INVALIDA");
        }
        // Reject embedded credentials, logging options and connection/session options
        // that could bypass the separate credential inputs or disclose their values.
        Set<String> allowed = Set.of("sslmode", "channelBinding", "connectTimeout",
            "socketTimeout", "tcpKeepAlive", "sslrootcert");
        Set<String> seen = new HashSet<>();
        String sslmode = null;
        if (uri.getRawQuery() != null) {
            for (String part : uri.getRawQuery().split("&")) {
                String[] pair = part.split("=", 2);
                String key = URLDecoder.decode(pair[0], StandardCharsets.UTF_8);
                if (pair.length != 2 || !allowed.contains(key) || !seen.add(key)) {
                    throw new IllegalArgumentException("CONFIGURACION_INVALIDA");
                }
                if ("sslmode".equals(key)) {
                    sslmode = URLDecoder.decode(pair[1], StandardCharsets.UTF_8);
                }
            }
        }
        if (sslmode != null && !Set.of("require", "verify-ca", "verify-full").contains(sslmode)) {
            throw new IllegalArgumentException("CONFIGURACION_INVALIDA");
        }
        Properties properties = new Properties();
        properties.setProperty("user", username);
        properties.setProperty("password", password);
        properties.setProperty("sslmode", sslmode == null ? "verify-full" : sslmode);
        properties.setProperty("connectTimeout", "10");
        properties.setProperty("socketTimeout", "15");
        properties.setProperty("readOnly", "true");
        properties.setProperty("readOnlyMode", "transaction");
        return new Configuration(url, properties);
    }

    private static String required(Map<String, String> environment, String name) {
        String value = environment.get(name);
        if (value == null || value.isBlank()) {
            // Fixed identifier only. Never include the missing/invalid value.
            throw new IllegalArgumentException("VARIABLE_AUSENTE_" + name);
        }
        return value;
    }

    static Report inspect(Connection suppliedConnection) throws SQLException {
        try (Connection connection = suppliedConnection) {
            connection.setReadOnly(true);
            connection.setAutoCommit(false);
            try (Statement statement = connection.createStatement()) {
                statement.setQueryTimeout(10);
                // PostgreSQL JDBC starts BEGIN READ ONLY for this transaction.
                // Verify on the server before even inspecting application metadata.
                try (var rows = statement.executeQuery("SELECT current_setting('transaction_read_only')")) {
                    if (!rows.next() || !"on".equals(rows.getString(1))) {
                        throw new SQLException("Read-only transaction required", "25006");
                    }
                }
                try (var rows = statement.executeQuery("SELECT 1")) {
                    if (!rows.next() || rows.getInt(1) != 1) {
                        throw new SQLException("Unexpected probe result", "P0001");
                    }
                }
                boolean history = exists(statement, "SELECT to_regclass('public.flyway_schema_history') IS NOT NULL");
                String v10 = "NO_REGISTRADA";
                if (history) {
                    int count = 0;
                    boolean successful = true;
                    try (var rows = statement.executeQuery(
                            "SELECT success FROM public.flyway_schema_history WHERE version IN ('10', '10.0', '10.0.0')")) {
                        while (rows.next()) {
                            count++;
                            successful &= rows.getBoolean(1);
                        }
                    }
                    if (count > 1) v10 = "REGISTROS_MULTIPLES_REVISAR";
                    else if (count == 1) v10 = successful ? "APLICADA" : "REGISTRO_FALLIDO";
                }
                boolean stories = exists(statement, "SELECT to_regclass('public.writer_stories') IS NOT NULL");
                return new Report(history, v10, stories);
            } finally {
                // Never commit, including on query, timeout or permissions errors.
                connection.rollback();
            }
        }
    }

    private static boolean exists(Statement statement, String sql) throws SQLException {
        try (var rows = statement.executeQuery(sql)) {
            if (!rows.next()) throw new SQLException("Missing probe result", "P0001");
            return rows.getBoolean(1);
        }
    }

    static String safeFailure(Exception error) {
        if (error instanceof IllegalArgumentException) {
            String message = error.getMessage();
            if (Set.of("VARIABLE_AUSENTE_DB_URL", "VARIABLE_AUSENTE_DB_USERNAME",
                    "VARIABLE_AUSENTE_DB_PASSWORD").contains(message == null ? "" : message)) {
                return message;
            }
            return "CONFIGURACION_INVALIDA_REVISAR_JDBC_Y_TLS_SIN_COMPARTIR_VALORES";
        }
        if (error instanceof SQLException sql) {
            String state = sql.getSQLState();
            if (state != null && state.matches("[A-Z0-9]{5}")) {
                return "FALLO_JDBC_SQLSTATE_" + state;
            }
        }
        return "FALLO_JDBC_SIN_DETALLES_SENSIBLES";
    }
}
