package dao;

import model.MedicalAidProvider;
import model.ValidationLog;
import model.MedicalAidUtilization;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MedicalAidDAO {

    // ==================== GET ALL ACTIVE PROVIDERS ====================
    
    public List<MedicalAidProvider> getAllProviders() {
        List<MedicalAidProvider> list = new ArrayList<>();
        String sql = "SELECT provider_id, provider_name, contact_person, email, phone, is_active, user_id FROM medical_aid_providers WHERE is_active = 1 ORDER BY provider_name";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                MedicalAidProvider p = new MedicalAidProvider();
                p.setProviderId(rs.getInt("provider_id"));
                p.setProviderName(rs.getString("provider_name"));
                p.setContactPerson(rs.getString("contact_person"));
                p.setEmail(rs.getString("email"));
                p.setPhone(rs.getString("phone"));
                p.setActive(rs.getInt("is_active") == 1);
                try { p.setUserId(rs.getInt("user_id")); } catch (SQLException ignored) {}
                list.add(p);
            }
            System.out.println("[MedicalAidDAO] Retrieved " + list.size() + " active providers");
        } catch (SQLException e) { 
            System.err.println("[MedicalAidDAO] Error: " + e.getMessage());
            e.printStackTrace(); 
        }
        return list;
    }
    
    // ==================== GET PROVIDER BY USER ID ====================
    
    public MedicalAidProvider getProviderByUserId(int userId) {
        String sql = "SELECT * FROM medical_aid_providers WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapProvider(rs);
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }
    
    // ==================== GET PROVIDER BY ID ====================
    
    public MedicalAidProvider getProviderById(int providerId) {
        String sql = "SELECT * FROM medical_aid_providers WHERE provider_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapProvider(rs);
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }
    
    // ==================== GET PROVIDER BY NAME ====================
    
    public MedicalAidProvider getProviderByProviderName(String providerName) {
        String sql = "SELECT * FROM medical_aid_providers WHERE provider_name = ? AND is_active = 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapProvider(rs);
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }
    
    // ==================== CREATE PROVIDER ====================
    
    public boolean createMedicalAidProvider(MedicalAidProvider provider) {
        String sql = "INSERT INTO medical_aid_providers (provider_name, contact_person, email, phone, is_active) VALUES (?, ?, ?, ?, ?)";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, provider.getProviderName());
            ps.setString(2, provider.getContactPerson());
            ps.setString(3, provider.getEmail());
            ps.setString(4, provider.getPhone());
            ps.setInt(5, provider.isActive() ? 1 : 0);
            
            int affected = ps.executeUpdate();
            if (affected > 0) {
                ResultSet rs = ps.getGeneratedKeys();
                if (rs.next()) {
                    provider.setProviderId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // ==================== UPDATE PROVIDER ====================
    
    public boolean updateMedicalAidProvider(MedicalAidProvider provider) {
        String sql = "UPDATE medical_aid_providers SET provider_name=?, contact_person=?, email=?, phone=?, is_active=? WHERE provider_id=?";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, provider.getProviderName());
            ps.setString(2, provider.getContactPerson());
            ps.setString(3, provider.getEmail());
            ps.setString(4, provider.getPhone());
            ps.setInt(5, provider.isActive() ? 1 : 0);
            ps.setInt(6, provider.getProviderId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // ==================== DELETE PROVIDER ====================
    
    public boolean deleteMedicalAidProvider(int providerId) {
        String checkSql = "SELECT COUNT(*) FROM patients WHERE medical_aid_provider = (SELECT provider_name FROM medical_aid_providers WHERE provider_id = ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(checkSql)) {
            ps.setInt(1, providerId);
            ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        String sql = "DELETE FROM medical_aid_providers WHERE provider_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // ==================== FORCE UPDATE APPOINTMENTS VALIDATION STATUS ====================
    
    public int forceUpdateAppointmentsValidationStatus(int patientId, String newStatus) {
        String sql = "UPDATE appointments SET validation_status = ?, validation_timestamp = CURRENT_TIMESTAMP WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setInt(2, patientId);
            int updated = ps.executeUpdate();
            System.out.println("[MedicalAidDAO] Updated " + updated + " appointments for patient " + patientId + " to " + newStatus);
            return updated;
        } catch (SQLException e) {
            System.err.println("[MedicalAidDAO] Error updating appointments: " + e.getMessage());
            e.printStackTrace();
            return 0;
        }
    }
    
    // ==================== VALIDATION METHODS ====================
    
    public boolean validateMedicalAid(int patientId, int appointmentId) {
        String sql = "SELECT p.membership_status FROM patients p WHERE p.patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String membershipStatus = rs.getString("membership_status");
                return "active".equalsIgnoreCase(membershipStatus);
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    public Map<Integer, Boolean> batchValidateMedicalAid(List<Integer> patientIds) {
        Map<Integer, Boolean> resultMap = new HashMap<>();
        if (patientIds == null || patientIds.isEmpty()) return resultMap;
        
        StringBuilder sql = new StringBuilder("SELECT patient_id, membership_status FROM patients WHERE patient_id IN (");
        for (int i = 0; i < patientIds.size(); i++) {
            if (i > 0) sql.append(",");
            sql.append("?");
        }
        sql.append(")");
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < patientIds.size(); i++) {
                ps.setInt(i + 1, patientIds.get(i));
            }
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int patientId = rs.getInt("patient_id");
                String membershipStatus = rs.getString("membership_status");
                resultMap.put(patientId, "active".equalsIgnoreCase(membershipStatus));
            }
            for (int patientId : patientIds) {
                resultMap.putIfAbsent(patientId, false);
            }
        } catch (SQLException e) {
            System.err.println("Error in batch validation: " + e.getMessage());
            for (int patientId : patientIds) resultMap.put(patientId, false);
        }
        return resultMap;
    }
    
    // ==================== VALIDATION LOGS ====================
    
    public List<ValidationLog> getValidationsByProvider(int providerId) {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "WHERE v.provider_id = ? ORDER BY v.validation_time DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapValidation(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }
    
    public List<ValidationLog> getValidationsByPatient(int patientId) {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "WHERE v.patient_id = ? ORDER BY v.validation_time DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapValidation(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }
    
    public List<ValidationLog> getAllValidations() {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "ORDER BY v.validation_time DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapValidation(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }
    
    // ==================== MEDICAL AID UTILIZATION REPORT ====================
    
    public List<MedicalAidUtilization> getUtilizationStats() {
        List<MedicalAidUtilization> list = new ArrayList<>();
        String sql = 
            "SELECT " +
            "  mp.provider_name, " +
            "  COUNT(DISTINCT p.patient_id) as patient_count, " +
            "  COUNT(a.appointment_id) as appointment_count, " +
            "  SUM(CASE WHEN a.validation_status = 'active' OR a.validation_status = 'approved' THEN 1 ELSE 0 END) as approved_count, " +
            "  SUM(CASE WHEN a.validation_status = 'rejected' THEN 1 ELSE 0 END) as rejected_count, " +
            "  SUM(CASE WHEN a.validation_status = 'pending' THEN 1 ELSE 0 END) as pending_count " +
            "FROM medical_aid_providers mp " +
            "LEFT JOIN patients p ON mp.provider_name = p.medical_aid_provider " +
            "LEFT JOIN appointments a ON p.patient_id = a.patient_id " +
            "WHERE mp.is_active = 1 " +
            "GROUP BY mp.provider_name " +
            "ORDER BY appointment_count DESC";
            
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                MedicalAidUtilization mu = new MedicalAidUtilization();
                mu.setProviderName(rs.getString("provider_name"));
                mu.setPatientCount(rs.getInt("patient_count"));
                mu.setAppointmentCount(rs.getInt("appointment_count"));
                mu.setApprovedCount(rs.getInt("approved_count"));
                mu.setRejectedCount(rs.getInt("rejected_count"));
                mu.setPendingCount(rs.getInt("pending_count"));
                list.add(mu);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    // ==================== PRIVATE HELPERS ====================
    
    private MedicalAidProvider mapProvider(ResultSet rs) throws SQLException {
        MedicalAidProvider p = new MedicalAidProvider();
        p.setProviderId(rs.getInt("provider_id"));
        p.setProviderName(rs.getString("provider_name"));
        p.setContactPerson(rs.getString("contact_person"));
        p.setEmail(rs.getString("email"));
        p.setPhone(rs.getString("phone"));
        p.setActive(rs.getInt("is_active") == 1);
        try { p.setUserId(rs.getInt("user_id")); } catch (SQLException ignored) {}
        return p;
    }
    
    private ValidationLog mapValidation(ResultSet rs) throws SQLException {
        ValidationLog v = new ValidationLog();
        v.setValidationId(rs.getInt("validation_id"));
        v.setPatientId(rs.getInt("patient_id"));
        String providerName = rs.getString("provider_name");
        v.setAidProvider(providerName != null ? providerName : "Unknown");
        v.setValidationTime(rs.getString("validation_time"));
        v.setValidationResult(rs.getString("validation_result"));
        v.setMemberNumber(rs.getString("member_number"));
        try { v.setPatientName(rs.getString("full_name")); } catch (SQLException ignored) {}
        return v;
    }
}