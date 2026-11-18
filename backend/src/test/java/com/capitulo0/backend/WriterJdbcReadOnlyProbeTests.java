package com.capitulo0.backend;

import java.sql.*;
import java.util.Map;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class WriterJdbcReadOnlyProbeTests {
    private Map<String, String> environment() {
        return Map.of("DB_URL", "jdbc:postgresql://fixture.neon.tech/example?sslmode=require&channelBinding=require",
            "DB_USERNAME", "fixture-user", "DB_PASSWORD", "fixture-password");
    }

    @Test void credentialsAreSeparateAndConfigurationNeverPrintsThem() {
        var config = WriterJdbcReadOnlyProbe.configuration(environment());
        assertThat(config.toString()).doesNotContain("fixture", "password", "jdbc:");
        assertThat(config.properties().getProperty("readOnly")).isEqualTo("true");
        assertThat(config.properties().getProperty("readOnlyMode")).isEqualTo("transaction");
    }

    @Test void rejectsEmbeddedCredentialsAndInsecureOrUnexpectedOptions() {
        for (String query : new String[]{"user=hidden", "password=hidden", "sslmode=disable",
                "loggerFile=hidden", "options=hidden", "sslmode=require&sslmode=disable"}) {
            assertThatThrownBy(() -> WriterJdbcReadOnlyProbe.configuration(Map.of(
                "DB_URL", "jdbc:postgresql://fixture.neon.tech/example?" + query,
                "DB_USERNAME", "fixture", "DB_PASSWORD", "hidden")))
                .isInstanceOf(IllegalArgumentException.class);
        }
    }

    @Test void errorsNeverExposeDriverMessagesOrExceptionCauses() {
        var error = new SQLException("jdbc:postgresql://secret-host/secret-db user=secret password=secret", "28P01");
        assertThat(WriterJdbcReadOnlyProbe.safeFailure(error)).isEqualTo("FALLO_JDBC_SQLSTATE_28P01");
        assertThat(WriterJdbcReadOnlyProbe.safeFailure(new IllegalArgumentException("secret")))
            .doesNotContain("secret");
        assertThat(WriterJdbcReadOnlyProbe.safeFailure(new SQLException("secret", "secret-value")))
            .doesNotContain("secret");
        assertThat(WriterJdbcReadOnlyProbe.safeFailure(new IllegalArgumentException()))
            .doesNotContain("null");
    }

    @Test void missingVariablesAreReportedByNameOnly() {
        assertThatThrownBy(() -> WriterJdbcReadOnlyProbe.configuration(Map.of()))
            .hasMessage("VARIABLE_AUSENTE_DB_URL");
    }

    private ResultSet scalar(Object value) throws SQLException {
        var rows = mock(ResultSet.class);
        when(rows.next()).thenReturn(true, false);
        if (value instanceof String text) when(rows.getString(1)).thenReturn(text);
        if (value instanceof Boolean flag) when(rows.getBoolean(1)).thenReturn(flag);
        if (value instanceof Integer number) when(rows.getInt(1)).thenReturn(number);
        return rows;
    }

    @Test void absentMigrationAndTableAreNormalAndAllQueriesRemainReadOnly() throws Exception {
        var connection = mock(Connection.class);
        var statement = mock(Statement.class);
        when(connection.createStatement()).thenReturn(statement);
        doReturn(scalar("on")).when(statement).executeQuery("SELECT current_setting('transaction_read_only')");
        doReturn(scalar(1)).when(statement).executeQuery("SELECT 1");
        doReturn(scalar(true)).when(statement).executeQuery("SELECT to_regclass('public.flyway_schema_history') IS NOT NULL");
        when(statement.executeQuery("SELECT success FROM public.flyway_schema_history WHERE version IN ('10', '10.0', '10.0.0')"))
            .thenReturn(mock(ResultSet.class));
        doReturn(scalar(false)).when(statement).executeQuery("SELECT to_regclass('public.writer_stories') IS NOT NULL");
        assertThat(WriterJdbcReadOnlyProbe.inspect(connection))
            .isEqualTo(new WriterJdbcReadOnlyProbe.Report(true, "NO_REGISTRADA", false));
        var order = inOrder(connection, statement);
        order.verify(connection).setReadOnly(true);
        order.verify(connection).setAutoCommit(false);
        order.verify(connection).createStatement();
        order.verify(statement).setQueryTimeout(10);
        order.verify(statement).executeQuery("SELECT current_setting('transaction_read_only')");
        verify(connection).rollback();
        verify(connection).close();
        verify(connection, never()).commit();
        verify(statement, never()).executeUpdate(anyString());
        verify(statement, never()).execute(anyString());
    }

    @Test void nonReadOnlyServerStateStopsBeforeSelectOneAndRollsBack() throws Exception {
        var connection = mock(Connection.class);
        var statement = mock(Statement.class);
        when(connection.createStatement()).thenReturn(statement);
        doReturn(scalar("off")).when(statement).executeQuery("SELECT current_setting('transaction_read_only')");
        assertThatThrownBy(() -> WriterJdbcReadOnlyProbe.inspect(connection))
            .isInstanceOf(SQLException.class);
        verify(statement, never()).executeQuery("SELECT 1");
        verify(connection).rollback();
        verify(connection).close();
        verify(connection, never()).commit();
    }
}
