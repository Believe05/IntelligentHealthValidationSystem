package dao;

import model.AuditLog;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AuditLogDAO {

    public boolean logAction(int userId, String action, String details, String ipAddress) {
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address, log_time) " +
                     "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, action);
            ps.setString(3, details);
            ps.setString(4, ipAddress);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error logging action: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public List<AuditLog> getRecentLogs(int limit) {
        List<AuditLog> list = new ArrayList<>();
        String sql = "SELECT a.*, u.username, u.full_name FROM audit_log a " +
                     "LEFT JOIN users u ON a.user_id = u.user_id " +
                     "ORDER BY a.log_time DESC FETCH FIRST ? ROWS ONLY";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                AuditLog log = new AuditLog();
                log.setLogId(rs.getInt("log_id"));
                log.setUserId(rs.getInt("user_id"));
                log.setUsername(rs.getString("username"));
                log.setUserFullName(rs.getString("full_name"));
                log.setAction(rs.getString("action"));
                log.setDetails(rs.getString("details"));
                log.setIpAddress(rs.getString("ip_address"));
                log.setLogTime(rs.getString("log_time"));
                list.add(log);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    public List<AuditLog> getLogsByUser(int userId, int limit) {
        List<AuditLog> list = new ArrayList<>();
        String sql = "SELECT a.*, u.username, u.full_name FROM audit_log a " +
                     "LEFT JOIN users u ON a.user_id = u.user_id " +
                     "WHERE a.user_id = ? " +
                     "ORDER BY a.log_time DESC FETCH FIRST ? ROWS ONLY";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, limit);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                AuditLog log = new AuditLog();
                log.setLogId(rs.getInt("log_id"));
                log.setUserId(rs.getInt("user_id"));
                log.setUsername(rs.getString("username"));
                log.setUserFullName(rs.getString("full_name"));
                log.setAction(rs.getString("action"));
                log.setDetails(rs.getString("details"));
                log.setIpAddress(rs.getString("ip_address"));
                log.setLogTime(rs.getString("log_time"));
                list.add(log);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    /**
     * Delete all audit logs for a specific user
     */
    public boolean deleteLogsByUser(int userId) {
        String sql = "DELETE FROM audit_log WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            int rows = ps.executeUpdate();
            System.out.println("Deleted " + rows + " audit logs for user ID: " + userId);
            return true;
        } catch (SQLException e) {
            System.err.println("Error deleting audit logs for user: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Delete old audit logs (older than specified days)
     */
    public int deleteOldLogs(int daysOld) {
        // FIX: Derby does not support "CURRENT_TIMESTAMP - ? DAYS" with a bind parameter.
        // Use TIMESTAMPADD with a negated interval instead.
        String sql = "DELETE FROM audit_log WHERE log_time <= {fn TIMESTAMPADD(SQL_TSI_DAY, ?, CURRENT_TIMESTAMP)}";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, -daysOld); // negative = subtract days
            return ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }
}