package util;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class StoredProcedures {

    // Called by BOOK_APPOINTMENT_WITH_VALIDATION stored procedure
    public static void bookAppointment(int patientId, int doctorId, 
                                        Date appointmentDate, String appointmentTime, 
                                        String notes) throws SQLException {
        
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Insert appointment
            String insertSql = "INSERT INTO appointments (patient_id, doctor_id, status_id, " +
                               "appointment_date, appointment_time, validation_status, notes, created_at) " +
                               "VALUES (?, ?, (SELECT status_id FROM appointment_status WHERE status_name = 'pending'), " +
                               "?, ?, 'pending', ?, CURRENT_TIMESTAMP)";
            
            int appointmentId = -1;
            try (PreparedStatement ps = con.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, patientId);
                ps.setInt(2, doctorId);
                ps.setDate(3, appointmentDate);
                ps.setString(4, appointmentTime);
                ps.setString(5, notes);
                ps.executeUpdate();
                
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    appointmentId = keys.getInt(1);
                }
            }
            
            if (appointmentId == -1) {
                throw new SQLException("Failed to create appointment");
            }
            
            // Update patient's total appointments
            String updatePatientSql = "UPDATE patients SET total_appointments = total_appointments + 1 WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updatePatientSql)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            // Create reminders
            createReminders(con, appointmentId, appointmentDate, appointmentTime);
            
            con.commit();
            System.out.println("[StoredProcedures] Appointment booked successfully. ID=" + appointmentId);
            
        } catch (SQLException e) {
            if (con != null) try { con.rollback(); } catch (SQLException ex) {}
            throw e;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (SQLException e) {}
                try { con.close(); } catch (SQLException e) {}
            }
        }
    }

    // Called by CANCEL_APPOINTMENT_WITH_UPDATES stored procedure
    public static void cancelAppointment(int appointmentId, String cancelReason) throws SQLException {
        
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get patient_id
            int patientId = -1;
            String getPatientSql = "SELECT patient_id FROM appointments WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(getPatientSql)) {
                ps.setInt(1, appointmentId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    patientId = rs.getInt(1);
                }
            }
            
            if (patientId == -1) {
                throw new SQLException("Appointment not found: " + appointmentId);
            }
            
            // Update appointment to cancelled
            String updateSql = "UPDATE appointments SET status_id = (SELECT status_id FROM appointment_status WHERE status_name = 'cancelled'), " +
                              "cancellation_reason = ? WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setString(1, cancelReason != null ? cancelReason : "Cancelled by user");
                ps.setInt(2, appointmentId);
                ps.executeUpdate();
            }
            
            // Update patient's cancellation count
            String updatePatientSql = "UPDATE patients SET cancellation_count = cancellation_count + 1 WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updatePatientSql)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            // Recalculate PRI
            recalculatePRI(con, patientId);
            
            con.commit();
            System.out.println("[StoredProcedures] Appointment cancelled successfully. ID=" + appointmentId);
            
        } catch (SQLException e) {
            if (con != null) try { con.rollback(); } catch (SQLException ex) {}
            throw e;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (SQLException e) {}
                try { con.close(); } catch (SQLException e) {}
            }
        }
    }

    // Called by COMPLETE_APPOINTMENT_UPDATE stored procedure
    public static void completeAppointment(int appointmentId) throws SQLException {
        
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get patient_id
            int patientId = -1;
            String getPatientSql = "SELECT patient_id FROM appointments WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(getPatientSql)) {
                ps.setInt(1, appointmentId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    patientId = rs.getInt(1);
                }
            }
            
            if (patientId == -1) {
                throw new SQLException("Appointment not found: " + appointmentId);
            }
            
            // Update appointment to completed
            String updateSql = "UPDATE appointments SET status_id = (SELECT status_id FROM appointment_status WHERE status_name = 'completed') " +
                              "WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setInt(1, appointmentId);
                ps.executeUpdate();
            }
            
            // Update patient's completed count
            String updatePatientSql = "UPDATE patients SET completed_count = completed_count + 1 WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updatePatientSql)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            // Recalculate PRI
            recalculatePRI(con, patientId);
            
            con.commit();
            System.out.println("[StoredProcedures] Appointment completed successfully. ID=" + appointmentId);
            
        } catch (SQLException e) {
            if (con != null) try { con.rollback(); } catch (SQLException ex) {}
            throw e;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (SQLException e) {}
                try { con.close(); } catch (SQLException e) {}
            }
        }
    }

    // ==================== HELPER METHODS ====================

    private static void createReminders(Connection con, int appointmentId, Date appointmentDate, String appointmentTime) throws SQLException {
        if (appointmentTime == null || appointmentTime.trim().isEmpty()) return;
        
        String timeStr = appointmentTime.trim();
        if (timeStr.length() > 5) timeStr = timeStr.substring(0, 5);
        
        String dateTimeStr = appointmentDate.toString() + " " + timeStr;
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        LocalDateTime apptDateTime;
        try {
            apptDateTime = LocalDateTime.parse(dateTimeStr, formatter);
        } catch (Exception e) {
            System.err.println("Could not parse appointment datetime: " + dateTimeStr);
            return;
        }
        
        String insertSql = "INSERT INTO reminders (appointment_id, reminder_type, scheduled_time, channel, status) VALUES (?, ?, ?, ?, 'pending')";
        
        // 24-hour reminder
        LocalDateTime reminder24h = apptDateTime.minusHours(24);
        String reminder24hStr = reminder24h.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        try (PreparedStatement ps = con.prepareStatement(insertSql)) {
            ps.setInt(1, appointmentId);
            ps.setString(2, "24h");
            ps.setString(3, reminder24hStr);
            ps.setString(4, "email");
            ps.executeUpdate();
        }
        
        // 1-hour reminder
        LocalDateTime reminder1h = apptDateTime.minusHours(1);
        String reminder1hStr = reminder1h.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        try (PreparedStatement ps = con.prepareStatement(insertSql)) {
            ps.setInt(1, appointmentId);
            ps.setString(2, "1h");
            ps.setString(3, reminder1hStr);
            ps.setString(4, "email");
            ps.executeUpdate();
        }
        
        System.out.println("Created reminders for appointment ID: " + appointmentId);
    }

    private static void recalculatePRI(Connection con, int patientId) throws SQLException {
        String statsSql = "SELECT total_appointments, no_show_count, cancellation_count FROM patients WHERE patient_id = ?";
        int total = 0, noShows = 0, cancelled = 0;
        
        try (PreparedStatement ps = con.prepareStatement(statsSql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                total = rs.getInt("total_appointments");
                noShows = rs.getInt("no_show_count");
                cancelled = rs.getInt("cancellation_count");
            }
        }
        
        int pri = 100;
        if (total > 0) {
            pri = 100 - (noShows * 10) - (cancelled * 5);
            pri = Math.max(0, Math.min(100, pri));
        }
        
        String updateSql = "UPDATE patients SET reliability_score = ? WHERE patient_id = ?";
        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
            ps.setInt(1, pri);
            ps.setInt(2, patientId);
            ps.executeUpdate();
        }
    }
}