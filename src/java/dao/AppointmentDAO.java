package dao;

import model.Appointment;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AppointmentDAO {

    // ==================== BOOK APPOINTMENT ====================
    
    public boolean bookAppointment(Appointment apt) {
        // First try stored procedure
        try {
            String sql = "{call BOOK_APPOINTMENT_WITH_VALIDATION(?, ?, ?, ?, ?)}";
            try (Connection con = DBConnection.getConnection();
                 CallableStatement cs = con.prepareCall(sql)) {
                
                cs.setInt(1, apt.getPatientId());
                cs.setInt(2, apt.getDoctorId());
                cs.setDate(3, java.sql.Date.valueOf(apt.getAppointmentDate()));
                cs.setString(4, apt.getAppointmentTime());
                cs.setString(5, apt.getNotes() != null ? apt.getNotes() : "");
                
                cs.execute();
                System.out.println("✅ [STORED PROCEDURE] Booked appointment successfully");
                return true;
            }
        } catch (SQLException e) {
            System.err.println("⚠️ Stored procedure failed, using direct SQL: " + e.getMessage());
            return bookAppointmentDirect(apt);
        }
    }
    
    public boolean bookAppointmentDirect(Appointment apt) {
        String sql = "INSERT INTO appointments " +
                     "(patient_id, doctor_id, status_id, appointment_date, appointment_time, " +
                     " notes, validation_status, medical_aid_provider, created_at) " +
                     "VALUES (?, ?, " +
                     " (SELECT status_id FROM appointment_status WHERE status_name = 'pending'), " +
                     " ?, ?, ?, 'pending', ?, CURRENT_TIMESTAMP)";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            ps.setInt(1, apt.getPatientId());
            ps.setInt(2, apt.getDoctorId());
            ps.setString(3, apt.getAppointmentDate());
            ps.setString(4, apt.getAppointmentTime());
            ps.setString(5, apt.getNotes());
            ps.setString(6, apt.getMedicalAidProvider());
            
            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    apt.setAppointmentId(keys.getInt(1));
                }
                
                // Update patient total appointments
                String updateSql = "UPDATE patients SET total_appointments = total_appointments + 1 WHERE patient_id = ?";
                try (PreparedStatement ps2 = con.prepareStatement(updateSql)) {
                    ps2.setInt(1, apt.getPatientId());
                    ps2.executeUpdate();
                }
                
                // Create reminders
                createReminders(apt.getAppointmentId(), apt.getAppointmentDate(), apt.getAppointmentTime());
                
                System.out.println("✅ [DIRECT SQL] Booked appointment - ID: " + apt.getAppointmentId());
                return true;
            }
        } catch (SQLException e) {
            System.err.println("Error booking appointment: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    // ==================== CANCEL APPOINTMENT ====================
    
    public boolean cancelAppointment(int appointmentId, String reason) {
        // First try stored procedure
        try {
            String sql = "{call CANCEL_APPOINTMENT_WITH_UPDATES(?, ?)}";
            try (Connection con = DBConnection.getConnection();
                 CallableStatement cs = con.prepareCall(sql)) {
                
                cs.setInt(1, appointmentId);
                cs.setString(2, reason != null && !reason.isEmpty() ? reason : "Cancelled by user");
                
                cs.execute();
                System.out.println("✅ [STORED PROCEDURE] Cancelled appointment: " + appointmentId);
                return true;
            }
        } catch (SQLException e) {
            System.err.println("⚠️ Stored procedure failed, using direct SQL: " + e.getMessage());
            return cancelAppointmentDirect(appointmentId, reason);
        }
    }
    
    public boolean cancelAppointmentDirect(int appointmentId, String reason) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get patient_id
            int patientId = getPatientIdForAppointment(con, appointmentId);
            if (patientId == -1) {
                System.err.println("Appointment not found: " + appointmentId);
                return false;
            }
            
            // Update appointment to cancelled
            String updateApptSql = "UPDATE appointments SET status_id = " +
                                   "(SELECT status_id FROM appointment_status WHERE status_name = 'cancelled'), " +
                                   "cancellation_reason = ? WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateApptSql)) {
                ps.setString(1, reason != null && !reason.isEmpty() ? reason : "Cancelled by user");
                ps.setInt(2, appointmentId);
                int rows = ps.executeUpdate();
                System.out.println("Cancel: Updated appointment " + appointmentId + ", rows: " + rows);
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
            System.out.println("✅ [DIRECT SQL] Cancelled appointment: " + appointmentId);
            return true;
            
        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) {}
            }
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) {
                try { con.close(); } catch (SQLException e) {}
            }
        }
    }

    // ==================== COMPLETE APPOINTMENT ====================
    
    public boolean completeAppointment(int appointmentId) {
        // First try stored procedure
        try {
            String sql = "{call COMPLETE_APPOINTMENT_UPDATE(?)}";
            try (Connection con = DBConnection.getConnection();
                 CallableStatement cs = con.prepareCall(sql)) {
                
                cs.setInt(1, appointmentId);
                cs.execute();
                System.out.println("✅ [STORED PROCEDURE] Completed appointment: " + appointmentId);
                return true;
            }
        } catch (SQLException e) {
            System.err.println("⚠️ Stored procedure failed, using direct SQL: " + e.getMessage());
            return completeAppointmentDirect(appointmentId);
        }
    }
    
    public boolean completeAppointmentDirect(int appointmentId) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get patient_id
            int patientId = getPatientIdForAppointment(con, appointmentId);
            if (patientId == -1) {
                System.err.println("Appointment not found: " + appointmentId);
                return false;
            }
            
            // Update appointment to completed
            String updateApptSql = "UPDATE appointments SET status_id = " +
                                   "(SELECT status_id FROM appointment_status WHERE status_name = 'completed') " +
                                   "WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateApptSql)) {
                ps.setInt(1, appointmentId);
                int rows = ps.executeUpdate();
                System.out.println("Complete: Updated appointment " + appointmentId + ", rows: " + rows);
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
            System.out.println("✅ [DIRECT SQL] Completed appointment: " + appointmentId);
            return true;
            
        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) {}
            }
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) {
                try { con.close(); } catch (SQLException e) {}
            }
        }
    }

    // ==================== UPDATE STATUS ====================
    
    public boolean updateStatus(int appointmentId, String statusName) {
        String sql = "UPDATE appointments SET status_id = " +
                     "(SELECT status_id FROM appointment_status WHERE status_name = ?) " +
                     "WHERE appointment_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, statusName);
            ps.setInt(2, appointmentId);
            int rows = ps.executeUpdate();
            System.out.println("Updated appointment " + appointmentId + " to " + statusName + ". Rows: " + rows);
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // ==================== UPDATE VALIDATION STATUS ====================
    
    public boolean updateValidationStatus(int appointmentId, String validationStatus) {
        String sql = "UPDATE appointments SET validation_status=?, " +
                     "validation_timestamp=CURRENT_TIMESTAMP WHERE appointment_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, validationStatus);
            ps.setInt(2, appointmentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // ==================== PRIVATE HELPER METHODS ====================
    
    private int getPatientIdForAppointment(Connection con, int appointmentId) throws SQLException {
        String sql = "SELECT patient_id FROM appointments WHERE appointment_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("patient_id");
            }
        }
        return -1;
    }
    
    private void recalculatePRI(Connection con, int patientId) throws SQLException {
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
            System.out.println("PRI recalculated for patient " + patientId + ": " + pri);
        }
    }

    // ==================== CREATE REMINDERS ====================
    
    private void createReminders(int appointmentId, String appointmentDate, String appointmentTime) {
        if (appointmentDate == null || appointmentTime == null) return;
        
        String timeStr = appointmentTime.length() > 5 ? appointmentTime.substring(0, 5) : appointmentTime;
        String dateTimeStr = appointmentDate + " " + timeStr;
        
        java.time.LocalDateTime apptDT;
        try {
            apptDT = java.time.LocalDateTime.parse(dateTimeStr,
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        } catch (Exception e) {
            System.err.println("Could not parse appointment datetime for reminders: " + dateTimeStr);
            return;
        }
        
        String insertSql = "INSERT INTO reminders " +
                           "(appointment_id, reminder_type, scheduled_time, channel, status) " +
                           "VALUES (?, ?, ?, 'email', 'pending')";
        java.time.format.DateTimeFormatter fmt =
                java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        
        try (Connection con = DBConnection.getConnection()) {
            // 24-hour reminder
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, appointmentId);
                ps.setString(2, "24h");
                ps.setString(3, apptDT.minusHours(24).format(fmt));
                ps.executeUpdate();
            }
            
            // 1-hour reminder
            try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                ps.setInt(1, appointmentId);
                ps.setString(2, "1h");
                ps.setString(3, apptDT.minusHours(1).format(fmt));
                ps.executeUpdate();
            }
            System.out.println("Created reminders for appointment ID: " + appointmentId);
        } catch (SQLException e) {
            System.err.println("Could not create reminders: " + e.getMessage());
        }
    }

    // ==================== READ METHODS ====================
    
    public List<Appointment> getAppointmentsByPatient(int patientId) {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "d.specialization, " +
                     "p.medical_aid_provider, p.reliability_score " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.patient_id = ? " +
                     "ORDER BY a.appointment_date DESC, a.appointment_time DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public List<Appointment> getAppointmentsByDoctor(int doctorId) {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.doctor_id = ? " +
                     "ORDER BY a.appointment_date ASC, a.appointment_time ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public List<Appointment> getAllAppointments() {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "ORDER BY a.appointment_date DESC, a.appointment_time DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public Appointment getAppointmentById(int id) {
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.appointment_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }

    public List<Appointment> getPendingValidations() {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score, p.medical_aid_number " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.validation_status = 'pending' " +
                     "ORDER BY a.appointment_date ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public List<Appointment> getPendingValidationsByProvider(String providerName) {
        List<Appointment> list = new ArrayList<>();
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score, p.medical_aid_number " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.validation_status = 'pending' " +
                     "AND (a.medical_aid_provider = ? OR p.medical_aid_provider = ?) " +
                     "ORDER BY a.appointment_date ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ps.setString(2, providerName);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    // ==================== DELETE METHODS ====================
    
    public void deleteAppointmentsByPatient(int patientId) {
        execute("DELETE FROM appointments WHERE patient_id = ?", patientId);
    }

    public void deleteAppointmentsByDoctor(int doctorId) {
        execute("DELETE FROM appointments WHERE doctor_id = ?", doctorId);
    }

    // ==================== COUNT METHODS ====================
    
    public int countByStatus(String statusName) {
        String sql = "SELECT COUNT(*) FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE s.status_name = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, statusName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }

    public int countTotal() {
        String sql = "SELECT COUNT(*) FROM appointments";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }

    public int countByDate(String date) {
        String sql = "SELECT COUNT(*) FROM appointments WHERE appointment_date = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, date);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }

    // ==================== PRIVATE HELPERS ====================
    
    private void execute(String sql, int param) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, param);
            ps.executeUpdate();
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
    }

    private Appointment mapRow(ResultSet rs) throws SQLException {
        Appointment a = new Appointment();
        a.setAppointmentId(rs.getInt("appointment_id"));
        a.setPatientId(rs.getInt("patient_id"));
        a.setDoctorId(rs.getInt("doctor_id"));
        a.setStatusId(rs.getInt("status_id"));
        a.setPatientName(rs.getString("patient_name"));
        a.setDoctorName(rs.getString("doctor_name"));
        a.setAppointmentDate(rs.getString("appointment_date"));
        a.setAppointmentTime(rs.getString("appointment_time"));
        a.setStatus(rs.getString("status_name"));
        a.setValidationStatus(rs.getString("validation_status"));
        a.setValidationTimestamp(rs.getString("validation_timestamp"));
        a.setCancellationReason(rs.getString("cancellation_reason"));
        a.setNotes(rs.getString("notes"));
        a.setMedicalAidProvider(rs.getString("medical_aid_provider"));
        a.setReliabilityScore(rs.getInt("reliability_score"));
        return a;
    }
}