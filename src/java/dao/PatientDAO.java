package dao;

import model.Patient;
import model.User;
import model.MedicalAid;  // FIX: Added missing import
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PatientDAO {

    // ==================== CREATE ====================
    
    public boolean createPatient(int userId) {
        String sql = "INSERT INTO patients (user_id, medical_aid_provider, medical_aid_number, " +
                     "reliability_score, total_appointments, completed_count, no_show_count, " +
                     "cancellation_count, membership_status) " +
                     "VALUES (?, NULL, NULL, 100, 0, 0, 0, 0, 'pending')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            System.err.println("Error creating patient: " + e.getMessage());
            e.printStackTrace(); 
        }
        return false;
    }

    public boolean createPatientWithMedicalAid(int userId, String provider, String number) {
        String sql = "INSERT INTO patients (user_id, medical_aid_provider, medical_aid_number, " +
                     "reliability_score, total_appointments, completed_count, no_show_count, " +
                     "cancellation_count, membership_status, last_validation) " +
                     "VALUES (?, ?, ?, 100, 0, 0, 0, 0, 'pending', CURRENT_TIMESTAMP)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, provider);
            ps.setString(3, number);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    // ==================== READ ====================
    
    public Patient getPatientById(int patientId) {
        if (patientId <= 0) return null;
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id WHERE p.patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public Patient getPatientByUserId(int userId) {
        if (userId <= 0) return null;
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id WHERE p.user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public List<Patient> getAllPatients() {
        List<Patient> list = new ArrayList<>();
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id ORDER BY u.full_name";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Patient> getPatientsByProviderAndStatus(String providerName, String status) {
        List<Patient> list = new ArrayList<>();
        if (providerName == null || status == null) return list;
        
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id " +
                     "WHERE p.medical_aid_provider = ? AND p.membership_status = ? " +
                     "ORDER BY p.last_validation DESC";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ps.setString(2, status);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }
    
    public List<Patient> getPatientsByProvider(String providerName) {
        List<Patient> list = new ArrayList<>();
        if (providerName == null) return list;
        
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id " +
                     "WHERE p.medical_aid_provider = ? " +
                     "ORDER BY p.last_validation DESC";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    // ==================== ADD THIS METHOD FOR MEDICAL AID LOOKUP ====================
    
    /**
     * Get MedicalAid by patient ID from the medical_aid table
     * Note: This assumes there is a medical_aid table linked to patients
     * If not, you may need to adjust the query or skip using this method
     */
    public MedicalAid getMedicalAidByPatientId(int patientId) {
        String sql = "SELECT * FROM medical_aid WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                MedicalAid medicalAid = new MedicalAid();
                medicalAid.setAidId(rs.getInt("aid_id"));
                //medicalAid.setPatientId(rs.getInt("patient_id"));
                medicalAid.setProviderName(rs.getString("provider_name"));
                medicalAid.setMemberNumber(rs.getString("member_number"));
                medicalAid.setMemberName(rs.getString("member_name"));
                medicalAid.setStatus(rs.getString("status"));
                medicalAid.setPlanType(rs.getString("plan_type"));
                Date expiryDate = rs.getDate("expiry_date");
                if (expiryDate != null) {
                    medicalAid.setExpiryDate(expiryDate.toLocalDate());
                }
                return medicalAid;
            }
        } catch (SQLException e) { 
            System.err.println("Error getting medical aid by patientId: " + e.getMessage());
            // Don't print stack trace as this table might not exist
        }
        return null;
    }

    public boolean patientExistsForUser(int userId) {
        String sql = "SELECT 1 FROM patients WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public int getPatientIdByUserId(int userId) {
        String sql = "SELECT patient_id FROM patients WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("patient_id");
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    // ==================== DELETE ====================
    
    public boolean deletePatient(int patientId) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            if (!patientExists(patientId, con)) return false;
            deleteRelatedRecords(patientId, con);
            boolean deleted = deletePatientRecord(patientId, con);
            if (deleted) {
                con.commit();
                return true;
            } else {
                con.rollback();
                return false;
            }
        } catch (SQLException e) {
            try { if (con != null) con.rollback(); } catch (SQLException ex) {}
            e.printStackTrace();
            return false;
        } finally {
            try { if (con != null) con.close(); } catch (SQLException e) {}
        }
    }
    
    private void deleteRelatedRecords(int patientId, Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM validation_log WHERE patient_id = ?")) {
            ps.setInt(1, patientId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM appointments WHERE patient_id = ?")) {
            ps.setInt(1, patientId);
            ps.executeUpdate();
        }
    }

    private boolean patientExists(int patientId, Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM patients WHERE patient_id = ?")) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        }
    }

    private boolean deletePatientRecord(int patientId, Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM patients WHERE patient_id = ?")) {
            ps.setInt(1, patientId);
            return ps.executeUpdate() > 0;
        }
    }

    // ==================== UPDATE ====================
    
    public boolean updatePatient(Patient patient) {
        String sql = "UPDATE patients SET medical_aid_provider=?, medical_aid_number=?, membership_status=?, " +
                     "reliability_score=?, total_appointments=?, completed_count=?, no_show_count=?, " +
                     "cancellation_count=?, last_validation=CURRENT_TIMESTAMP WHERE patient_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, patient.getMedicalAidProvider());
            ps.setString(2, patient.getMedicalAidNumber());
            ps.setString(3, patient.getMembershipStatus());
            ps.setInt(4, patient.getReliabilityScore());
            ps.setInt(5, patient.getTotalAppointments());
            ps.setInt(6, patient.getCompletedCount());
            ps.setInt(7, patient.getNoShowCount());
            ps.setInt(8, patient.getCancellationCount());
            ps.setInt(9, patient.getPatientId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateMedicalAid(int patientId, String provider, String number) {
        String sql = "UPDATE patients SET medical_aid_provider=?, medical_aid_number=?, last_validation=CURRENT_TIMESTAMP WHERE patient_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, provider);
            ps.setString(2, number);
            ps.setInt(3, patientId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateMembershipStatus(int patientId, String status) {
        String sql = "UPDATE patients SET membership_status = ?, last_validation = CURRENT_TIMESTAMP WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, patientId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }
    
    public boolean updateMedicalAidWithStatus(int patientId, String provider, String number, String status) {
        String sql = "UPDATE patients SET medical_aid_provider=?, medical_aid_number=?, membership_status=?, last_validation=CURRENT_TIMESTAMP WHERE patient_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, provider);
            ps.setString(2, number);
            ps.setString(3, status);
            ps.setInt(4, patientId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    // ==================== PATIENT RELIABILITY INDEX ====================
    
    public boolean recalculatePRI(int patientId) {
        String sql = "SELECT total_appointments, no_show_count, cancellation_count FROM patients WHERE patient_id = ?";
        String updateSql = "UPDATE patients SET reliability_score = ? WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection()) {
            int total = 0, noShows = 0, cancelled = 0;
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, patientId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    total = rs.getInt("total_appointments");
                    noShows = rs.getInt("no_show_count");
                    cancelled = rs.getInt("cancellation_count");
                } else return false;
            }
            int pri = 100;
            if (total > 0) {
                pri = 100 - (noShows * 10) - (cancelled * 5);
                pri = Math.max(0, Math.min(100, pri));
            }
            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setInt(1, pri);
                ps.setInt(2, patientId);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    public int getPatientPRI(int patientId) {
        String sql = "SELECT reliability_score FROM patients WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("reliability_score");
        } catch (SQLException e) { e.printStackTrace(); }
        return 100;
    }

    public String getMembershipStatus(int patientId) {
        String sql = "SELECT membership_status FROM patients WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String status = rs.getString("membership_status");
                return status != null ? status : "pending";
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return "unknown";
    }

    public boolean canBookAppointment(int patientId) {
        String status = getMembershipStatus(patientId);
        return "active".equals(status);
    }

    // ==================== APPOINTMENT COUNT UPDATES ====================
    
    public boolean incrementTotalAppointments(int patientId) {
        String sql = "UPDATE patients SET total_appointments = total_appointments + 1 WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            boolean result = ps.executeUpdate() > 0;
            if (result) recalculatePRI(patientId);
            return result;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    public boolean incrementCompletedCount(int patientId) {
        String sql = "UPDATE patients SET completed_count = completed_count + 1 WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            boolean result = ps.executeUpdate() > 0;
            if (result) recalculatePRI(patientId);
            return result;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    public boolean incrementNoShowCount(int patientId) {
        String sql = "UPDATE patients SET no_show_count = no_show_count + 1 WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            boolean result = ps.executeUpdate() > 0;
            if (result) recalculatePRI(patientId);
            return result;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    public boolean incrementCancellationCount(int patientId) {
        String sql = "UPDATE patients SET cancellation_count = cancellation_count + 1 WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            boolean result = ps.executeUpdate() > 0;
            if (result) recalculatePRI(patientId);
            return result;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    // ==================== HIGH RISK PATIENTS ====================
    
    public List<Patient> getHighRiskPatients() {
        List<Patient> list = new ArrayList<>();
        String sql = "SELECT p.*, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.created_at " +
                     "FROM patients p INNER JOIN users u ON p.user_id = u.user_id " +
                     "WHERE p.reliability_score < 60 ORDER BY p.reliability_score ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    // ==================== HELPER ====================
    
    private Patient mapRow(ResultSet rs) throws SQLException {
        Patient patient = new Patient();
        patient.setPatientId(rs.getInt("patient_id"));
        patient.setUserId(rs.getInt("user_id"));
        
        String provider = rs.getString("medical_aid_provider");
        if (provider != null) patient.setMedicalAidProvider(provider);
        
        String medicalAidNumber = rs.getString("medical_aid_number");
        if (medicalAidNumber != null) patient.setMedicalAidNumber(medicalAidNumber);
        
        patient.setReliabilityScore(rs.getInt("reliability_score"));
        patient.setTotalAppointments(rs.getInt("total_appointments"));
        patient.setCompletedCount(rs.getInt("completed_count"));
        patient.setNoShowCount(rs.getInt("no_show_count"));
        patient.setCancellationCount(rs.getInt("cancellation_count"));
        
        String lastValidation = rs.getString("last_validation");
        if (lastValidation != null) patient.setLastValidation(lastValidation);
        
        String membershipStatus = rs.getString("membership_status");
        patient.setMembershipStatus(membershipStatus != null ? membershipStatus : "pending");
        
        patient.setUsername(rs.getString("username"));
        patient.setFullName(rs.getString("full_name"));
        patient.setEmail(rs.getString("email"));
        patient.setPhone(rs.getString("phone"));
        patient.setRole(rs.getString("role"));
        patient.setIsActive(rs.getInt("is_active"));
        patient.setCreatedAt(rs.getString("created_at"));
        
        return patient;
    }
}