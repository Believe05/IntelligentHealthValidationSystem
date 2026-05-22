package dao;

import model.User;
import util.DBConnection;
import util.PasswordUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    public User validateUser(String username, String password) {
        if (username == null || password == null) return null;
        
        String sql = "SELECT * FROM users WHERE username = ? AND is_active = 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, username.trim());
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");
                if (PasswordUtil.verify(password, storedHash)) {
                    return mapRow(rs);
                }
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }

    public boolean registerUser(User user) {
        if (user == null) return false;
        
        String sql = "INSERT INTO users (username, password_hash, full_name, email, phone, role, is_active, created_at) " +
                     "VALUES (?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            ps.setString(1, user.getUsername());
            ps.setString(2, PasswordUtil.hash(user.getPassword()));
            ps.setString(3, user.getFullName());
            ps.setString(4, user.getEmail());
            ps.setString(5, user.getPhone());
            ps.setString(6, user.getRole());
            
            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    user.setUserId(keys.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    public boolean isUsernameExists(String username) {
        if (username == null) return false;
        
        String sql = "SELECT 1 FROM users WHERE username = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username.trim());
            return ps.executeQuery().next();
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    public boolean isEmailExists(String email) {
        if (email == null) return false;
        
        String sql = "SELECT 1 FROM users WHERE email = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            return ps.executeQuery().next();
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    public User getUserById(int userId) {
        if (userId <= 0) return null;
        
        String sql = "SELECT * FROM users WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }
    
    public User getUserByUsername(String username) {
        if (username == null) return null;
        
        String sql = "SELECT * FROM users WHERE username = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username.trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return null;
    }

    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users ORDER BY role, full_name";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public List<User> getUsersByRole(String role) {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE role = ? ORDER BY full_name";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, role);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }

    public boolean updateUser(User user) {
        if (user == null || user.getUserId() <= 0) return false;
        
        String sql = "UPDATE users SET full_name=?, email=?, phone=? WHERE user_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, user.getFullName());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPhone());
            ps.setInt(4, user.getUserId());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
            return false;
        }
    }

    public boolean updatePassword(int userId, String newPlainPassword) {
        if (userId <= 0 || newPlainPassword == null || newPlainPassword.length() < 8) {
            return false;
        }
        
        String sql = "UPDATE users SET password_hash=? WHERE user_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, PasswordUtil.hash(newPlainPassword));
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }

    public boolean deleteUserPermanently(int userId) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            User user = getUserById(userId);
            if (user != null) {
                if ("patient".equals(user.getRole())) {
                    deletePatientRecords(userId, con);
                } else if ("doctor".equals(user.getRole())) {
                    deleteDoctorRecords(userId, con);
                } else if ("medicalaid".equals(user.getRole())) {
                    deleteMedicalAidRecords(userId, con);
                }
                
                deleteAuditLogs(userId, con);
            }
            
            String sql = "DELETE FROM users WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                int rows = ps.executeUpdate();
                con.commit();
                return rows > 0;
            }
        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); con.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }

    public boolean deactivateUser(int userId) {
        String sql = "UPDATE users SET is_active = 0 WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean activateUser(int userId) {
        String sql = "UPDATE users SET is_active = 1 WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    private void deletePatientRecords(int userId, Connection con) throws SQLException {
        String getPatientId = "SELECT patient_id FROM patients WHERE user_id = ?";
        int patientId = -1;
        try (PreparedStatement ps = con.prepareStatement(getPatientId)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) patientId = rs.getInt(1);
        }
        
        if (patientId > 0) {
            String deleteReminders = "DELETE FROM reminders WHERE appointment_id IN (SELECT appointment_id FROM appointments WHERE patient_id = ?)";
            try (PreparedStatement ps = con.prepareStatement(deleteReminders)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            String deleteValidations = "DELETE FROM validation_log WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deleteValidations)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            String deleteAppointments = "DELETE FROM appointments WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deleteAppointments)) {
                ps.setInt(1, patientId);
                ps.executeUpdate();
            }
            
            String deletePatient = "DELETE FROM patients WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deletePatient)) {
                ps.setInt(1, userId);
                ps.executeUpdate();
            }
        }
    }
    
    private void deleteDoctorRecords(int userId, Connection con) throws SQLException {
        String getDoctorId = "SELECT doctor_id FROM doctors WHERE user_id = ?";
        int doctorId = -1;
        try (PreparedStatement ps = con.prepareStatement(getDoctorId)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) doctorId = rs.getInt(1);
        }
        
        if (doctorId > 0) {
            String deleteSchedule = "DELETE FROM doctor_schedule WHERE doctor_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deleteSchedule)) {
                ps.setInt(1, doctorId);
                ps.executeUpdate();
            }
            
            String deleteAppointments = "DELETE FROM appointments WHERE doctor_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deleteAppointments)) {
                ps.setInt(1, doctorId);
                ps.executeUpdate();
            }
            
            String deleteDoctor = "DELETE FROM doctors WHERE user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(deleteDoctor)) {
                ps.setInt(1, userId);
                ps.executeUpdate();
            }
        }
    }
    
    private void deleteMedicalAidRecords(int userId, Connection con) throws SQLException {
        String deleteProvider = "DELETE FROM medical_aid_providers WHERE user_id = ?";
        try (PreparedStatement ps = con.prepareStatement(deleteProvider)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }
    
    private void deleteAuditLogs(int userId, Connection con) throws SQLException {
        String sql = "DELETE FROM audit_log WHERE user_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }

    public int countByRole(String role) {
        if (role == null) return 0;
        
        String sql = "SELECT COUNT(*) FROM users WHERE role=? AND is_active=1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, role);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }
    
    public int getTotalUsers() {
        String sql = "SELECT COUNT(*) FROM users WHERE is_active = 1";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }
    
    private User mapRow(ResultSet rs) throws SQLException {
        User u = new User();
        u.setUserId(rs.getInt("user_id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password_hash"));
        u.setFullName(rs.getString("full_name"));
        u.setEmail(rs.getString("email"));
        u.setPhone(rs.getString("phone"));
        u.setRole(rs.getString("role"));
        u.setIsActive(rs.getInt("is_active"));
        u.setCreatedAt(rs.getString("created_at"));
        return u;
    }
}