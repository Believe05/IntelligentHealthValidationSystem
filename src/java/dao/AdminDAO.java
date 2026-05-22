package dao;

import model.User;
import model.Appointment;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import util.DBConnection;

public class AdminDAO {

    // ================================================================
    // USER STATISTICS
    // ================================================================
    public int getTotalUsers() {
        return getCount("SELECT COUNT(*) as count FROM users WHERE is_active=1");
    }

    public int getTotalPatients() {
        return getCount(
            "SELECT COUNT(*) as count FROM patients p " +
            "JOIN users u ON p.user_id = u.user_id WHERE u.is_active=1");
    }

    public int getTotalDoctors() {
        return getCount(
            "SELECT COUNT(*) as count FROM doctors d " +
            "JOIN users u ON d.user_id = u.user_id WHERE u.is_active=1");
    }

    public int getHighRiskPatients() {
        return getCount(
            "SELECT COUNT(*) as count FROM patients WHERE reliability_score < 60");
    }

    // ================================================================
    // APPOINTMENT STATISTICS
    // ================================================================
    public int getTotalAppointments() {
        return getCount("SELECT COUNT(*) as count FROM appointments");
    }

    public int getTodayAppointments() {
        return getCount(
            "SELECT COUNT(*) as count FROM appointments " +
            "WHERE appointment_date = CURRENT_DATE");
    }

    public int getAppointmentsByStatus(String statusName) {
        String sql = "SELECT COUNT(*) as count FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE s.status_name = ?";
        return getCountParam(sql, statusName);
    }

    // ================================================================
    // FIXED: MONTHLY STATISTICS - Derby compatible
    // ================================================================
    public int[] getMonthlyStats(int year, int month) {
    int[] stats = new int[6];

    String sql = 
        "SELECT s.status_name, COUNT(*) AS count " +
        "FROM appointments a " +
        "JOIN appointment_status s ON a.status_id = s.status_id " +
        "WHERE {fn YEAR(a.appointment_date)} = ? " +
        "AND {fn MONTH(a.appointment_date)} = ? " +
        "GROUP BY s.status_name";

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, year);
        ps.setInt(2, month);
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            String status = rs.getString("status_name");
            int count = rs.getInt("count");

            switch (status) {
                case "pending":     stats[0] = count; break;
                case "confirmed":   stats[1] = count; break;
                case "cancelled":   stats[2] = count; break;
                case "rescheduled": stats[3] = count; break;
                case "completed":   stats[4] = count; break;
                case "no-show":     stats[5] = count; break;
            }
        }
        
        // Debug output - check server console
        System.out.println("=== Monthly Stats Debug ===");
        System.out.println("Year/Month: " + year + "/" + month);
        System.out.println("Pending: " + stats[0]);
        System.out.println("Confirmed: " + stats[1]);
        System.out.println("Cancelled: " + stats[2]);
        System.out.println("Completed: " + stats[4]);
        System.out.println("No-Show: " + stats[5]);
        System.out.println("Total: " + (stats[0]+stats[1]+stats[2]+stats[3]+stats[4]+stats[5]));

    } catch (SQLException e) {
        System.err.println("Error in getMonthlyStats: " + e.getMessage());
        e.printStackTrace();
    }
    return stats;
}

    // ================================================================
    // FIXED: APPOINTMENTS BY DATE RANGE
    // ================================================================
    public List<Appointment> getAppointmentsByDateRange(String startDate, String endDate) {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.appointment_date >= ? AND a.appointment_date <= ? " +
                     "ORDER BY a.appointment_date, a.appointment_time";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, startDate);
            ps.setString(2, endDate);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Appointment apt = new Appointment();
                apt.setAppointmentId(rs.getInt("appointment_id"));
                apt.setPatientId(rs.getInt("patient_id"));
                apt.setDoctorId(rs.getInt("doctor_id"));
                apt.setPatientName(rs.getString("patient_name"));
                apt.setDoctorName(rs.getString("doctor_name"));
                apt.setAppointmentDate(rs.getString("appointment_date"));
                apt.setAppointmentTime(rs.getString("appointment_time"));
                apt.setStatus(rs.getString("status_name"));
                apt.setValidationStatus(rs.getString("validation_status"));
                apt.setNotes(rs.getString("notes"));
                apt.setMedicalAidProvider(rs.getString("medical_aid_provider"));
                list.add(apt);
            }
        } catch (SQLException e) {
            System.err.println("Error in getAppointmentsByDateRange: " + e.getMessage());
            e.printStackTrace();
        }
        return list;
    }

    // ================================================================
    // PRIVATE HELPERS
    // ================================================================
    private int getCount(String sql) {
        try (Connection con = DBConnection.getConnection();
             Statement stmt = con.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt("count");
        } catch (SQLException e) { 
            System.err.println("Error in getCount: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }

    private int getCountParam(String sql, String param) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, param);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("count");
        } catch (SQLException e) { 
            System.err.println("Error in getCountParam: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
}