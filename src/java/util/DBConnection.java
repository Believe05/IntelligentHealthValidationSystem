package util;

import java.sql.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;


 
public class DBConnection {

    private static final String URL      = System.getProperty("ihvs.db.url",      "jdbc:derby://localhost:1527/IHVS2");
    private static final String USERNAME = System.getProperty("ihvs.db.user",     "app");
    private static final String PASSWORD = System.getProperty("ihvs.db.password", "123");

    private static final int POOL_SIZE       = 15; // Increased for better concurrency
    private static final int ACQUIRE_TIMEOUT = 2; // Reduced from 5 seconds

    private static final BlockingQueue<Connection> pool = new ArrayBlockingQueue<>(POOL_SIZE);

    static {
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            for (int i = 0; i < POOL_SIZE; i++) {
                pool.offer(DriverManager.getConnection(URL, USERNAME, PASSWORD));
            }
            System.out.println("[DBConnection] Pool initialised with " + POOL_SIZE + " connections.");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Derby JDBC driver not found.", e);
        } catch (SQLException e) {
            throw new RuntimeException("Failed to initialise connection pool.", e);
        }
    }

    /**
     * Borrow a connection from the pool.
     * Because the returned object is a PooledConnection, calling close() on it
     * returns it to the pool rather than closing the physical connection.
     * All existing try-with-resources DAO code works without any changes.
     */
    public static Connection getConnection() throws SQLException {
        try {
            Connection con = pool.poll(ACQUIRE_TIMEOUT, TimeUnit.SECONDS);
            if (con == null) {
                throw new SQLException("Connection pool exhausted — no connection available after "
                        + ACQUIRE_TIMEOUT + "s.");
            }
            if (!isValid(con)) {
                safeClose(con);
                con = DriverManager.getConnection(URL, USERNAME, PASSWORD);
            }
            return new PooledConnection(con, pool);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SQLException("Interrupted while waiting for a connection.", e);
        }
    }

    // ------------------------------------------------------------------
    // Convenience close helpers — API unchanged, all existing DAOs work
    // ------------------------------------------------------------------

    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        try { if (rs   != null) rs.close();  } catch (SQLException e) { e.printStackTrace(); }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }

    public static void close(Connection conn, Statement stmt) {
        close(conn, stmt, (ResultSet) null);
    }

    public static void close(Connection conn, PreparedStatement ps, ResultSet rs) {
        try { if (rs   != null) rs.close();  } catch (SQLException e) { e.printStackTrace(); }
        try { if (ps   != null) ps.close();  } catch (SQLException e) { e.printStackTrace(); }
        try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }

    public static void close(Connection conn, PreparedStatement ps) {
        close(conn, ps, (ResultSet) null);
    }

    public static void close(Connection conn) {
        try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    private static boolean isValid(Connection con) {
        try { return con != null && !con.isClosed() && con.isValid(1); }
        catch (SQLException e) { return false; }
    }

    private static void safeClose(Connection con) {
        try { if (con != null) con.close(); } catch (SQLException ignored) {}
    }

    // ------------------------------------------------------------------
    // PooledConnection wrapper — returns to pool on close()
    // ------------------------------------------------------------------

    private static class PooledConnection implements Connection {

        private final Connection real;
        private final BlockingQueue<Connection> pool;
        private boolean closed = false;

        PooledConnection(Connection real, BlockingQueue<Connection> pool) {
            this.real = real;
            this.pool = pool;
        }

        @Override
        public void close() throws SQLException {
            if (!closed) {
                closed = true;
                try { real.setAutoCommit(true); } catch (SQLException ignored) {}
                if (!pool.offer(real)) { real.close(); }
            }
        }

        @Override public boolean isClosed() throws SQLException { return closed || real.isClosed(); }

        @Override public Statement createStatement() throws SQLException { return real.createStatement(); }
        @Override public PreparedStatement prepareStatement(String sql) throws SQLException { return real.prepareStatement(sql); }
        @Override public PreparedStatement prepareStatement(String sql, int autoKeys) throws SQLException { return real.prepareStatement(sql, autoKeys); }
        @Override public PreparedStatement prepareStatement(String sql, int[] cols) throws SQLException { return real.prepareStatement(sql, cols); }
        @Override public PreparedStatement prepareStatement(String sql, String[] cols) throws SQLException { return real.prepareStatement(sql, cols); }
        @Override public PreparedStatement prepareStatement(String sql, int i, int j) throws SQLException { return real.prepareStatement(sql, i, j); }
        @Override public PreparedStatement prepareStatement(String sql, int i, int j, int k) throws SQLException { return real.prepareStatement(sql, i, j, k); }
        @Override public CallableStatement prepareCall(String sql) throws SQLException { return real.prepareCall(sql); }
        @Override public CallableStatement prepareCall(String sql, int i, int j) throws SQLException { return real.prepareCall(sql, i, j); }
        @Override public CallableStatement prepareCall(String sql, int i, int j, int k) throws SQLException { return real.prepareCall(sql, i, j, k); }
        @Override public Statement createStatement(int i, int j) throws SQLException { return real.createStatement(i, j); }
        @Override public Statement createStatement(int i, int j, int k) throws SQLException { return real.createStatement(i, j, k); }
        @Override public String nativeSQL(String sql) throws SQLException { return real.nativeSQL(sql); }
        @Override public void setAutoCommit(boolean b) throws SQLException { real.setAutoCommit(b); }
        @Override public boolean getAutoCommit() throws SQLException { return real.getAutoCommit(); }
        @Override public void commit() throws SQLException { real.commit(); }
        @Override public void rollback() throws SQLException { real.rollback(); }
        @Override public void rollback(Savepoint sp) throws SQLException { real.rollback(sp); }
        @Override public DatabaseMetaData getMetaData() throws SQLException { return real.getMetaData(); }
        @Override public void setReadOnly(boolean b) throws SQLException { real.setReadOnly(b); }
        @Override public boolean isReadOnly() throws SQLException { return real.isReadOnly(); }
        @Override public void setCatalog(String s) throws SQLException { real.setCatalog(s); }
        @Override public String getCatalog() throws SQLException { return real.getCatalog(); }
        @Override public void setTransactionIsolation(int i) throws SQLException { real.setTransactionIsolation(i); }
        @Override public int getTransactionIsolation() throws SQLException { return real.getTransactionIsolation(); }
        @Override public SQLWarning getWarnings() throws SQLException { return real.getWarnings(); }
        @Override public void clearWarnings() throws SQLException { real.clearWarnings(); }
        @Override public java.util.Map<String, Class<?>> getTypeMap() throws SQLException { return real.getTypeMap(); }
        @Override public void setTypeMap(java.util.Map<String, Class<?>> m) throws SQLException { real.setTypeMap(m); }
        @Override public void setHoldability(int h) throws SQLException { real.setHoldability(h); }
        @Override public int getHoldability() throws SQLException { return real.getHoldability(); }
        @Override public Savepoint setSavepoint() throws SQLException { return real.setSavepoint(); }
        @Override public Savepoint setSavepoint(String s) throws SQLException { return real.setSavepoint(s); }
        @Override public void releaseSavepoint(Savepoint sp) throws SQLException { real.releaseSavepoint(sp); }
        @Override public Clob createClob() throws SQLException { return real.createClob(); }
        @Override public Blob createBlob() throws SQLException { return real.createBlob(); }
        @Override public NClob createNClob() throws SQLException { return real.createNClob(); }
        @Override public SQLXML createSQLXML() throws SQLException { return real.createSQLXML(); }
        @Override public boolean isValid(int t) throws SQLException { return real.isValid(t); }
        @Override public void setClientInfo(String k, String v) throws java.sql.SQLClientInfoException { try { real.setClientInfo(k, v); } catch (java.sql.SQLClientInfoException e) { throw e; } }
        @Override public void setClientInfo(java.util.Properties p) throws java.sql.SQLClientInfoException { try { real.setClientInfo(p); } catch (java.sql.SQLClientInfoException e) { throw e; } }
        @Override public String getClientInfo(String k) throws SQLException { return real.getClientInfo(k); }
        @Override public java.util.Properties getClientInfo() throws SQLException { return real.getClientInfo(); }
        @Override public Array createArrayOf(String t, Object[] e) throws SQLException { return real.createArrayOf(t, e); }
        @Override public Struct createStruct(String t, Object[] a) throws SQLException { return real.createStruct(t, a); }
        @Override public void setSchema(String s) throws SQLException { real.setSchema(s); }
        @Override public String getSchema() throws SQLException { return real.getSchema(); }
        @Override public void abort(java.util.concurrent.Executor e) throws SQLException { real.abort(e); }
        @Override public void setNetworkTimeout(java.util.concurrent.Executor e, int ms) throws SQLException { real.setNetworkTimeout(e, ms); }
        @Override public int getNetworkTimeout() throws SQLException { return real.getNetworkTimeout(); }
        @Override public <T> T unwrap(Class<T> c) throws SQLException { return real.unwrap(c); }
        @Override public boolean isWrapperFor(Class<?> c) throws SQLException { return real.isWrapperFor(c); }
    }
}