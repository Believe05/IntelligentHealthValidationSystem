package model;

public class User {
    private int userId;
    private String username;
    private String password;  // Maps to password_hash in DB
    private String fullName;
    private String email;
    private String phone;
    private String role;      // patient, doctor, admin, medicalaid
    private int isActive;      // 1 = active, 0 = inactive
    private String createdAt;

    public User() {
        this.isActive = 1;
    }

    // Getters and Setters
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    
    // For backward compatibility
    public String getPasswordHash() { return password; }
    public void setPasswordHash(String passwordHash) { this.password = passwordHash; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public int getIsActive() { return isActive; }
    public void setIsActive(int isActive) { this.isActive = isActive; }
    
    public boolean isActive() { return isActive == 1; }
    public void setActive(boolean active) { this.isActive = active ? 1 : 0; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    
    public boolean isPatient() { return "patient".equals(role); }
    public boolean isDoctor() { return "doctor".equals(role); }
    public boolean isAdmin() { return "admin".equals(role); }
    public boolean isMedicalAid() { return "medicalaid".equals(role); }
    
    @Override
    public String toString() {
        return "User{id=" + userId + ", username=" + username + ", role=" + role + "}";
    }
}