package util;

import java.sql.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Writes entries to the audit_log table.
 * Logging is done on a background thread so it never blocks the servlet thread.
 * FIX: Removed extra Timestamp parameter - INSERT only has 4 value slots, not 5.
 */
public class AuditLogger {

    private static final ExecutorService writer =
            Executors.newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "AuditLogger");
                t.setDaemon(true);
                return t;
            });

    public static void log(int userId, String action, String details, String ipAddress) {
        writer.submit(() -> writeLog(userId, action, details, ipAddress));
    }

    public static void log(String action, String details, String ipAddress) {
        log(0, action, details, ipAddress);
    }

    private static void writeLog(int userId, String action, String details, String ipAddress) {
        // FIX: SQL has 4 columns and 4 value placeholders - removed erroneous 5th ps.setTimestamp call
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address, log_time) " +
                     "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.setString(2, truncate(action, 100));
            ps.setString(3, truncate(details, 500));
            ps.setString(4, truncate(ipAddress, 45));
            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println("[AuditLogger] Failed to write log: " + e.getMessage());
        }
    }

    private static String truncate(String value, int maxLength) {
        if (value == null) return null;
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }
}
