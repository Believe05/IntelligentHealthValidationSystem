package model;

import java.time.LocalDate;

public class MedicalAid {
    private int         aidId;
    private String      providerName;
    private String      memberNumber;
    private String      memberName;
    private String      status;           // active | inactive | suspended
    private String      planType;
    private LocalDate   expiryDate;

    public MedicalAid() {}

    // Getters and Setters
    public int getAidId() { return aidId; }
    public void setAidId(int aidId) { this.aidId = aidId; }

    public String getProviderName() { return providerName; }
    public void setProviderName(String providerName) { this.providerName = providerName; }

    public String getMemberNumber() { return memberNumber; }
    public void setMemberNumber(String memberNumber) { this.memberNumber = memberNumber; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPlanType() { return planType; }
    public void setPlanType(String planType) { this.planType = planType; }

    public LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(LocalDate expiryDate) { this.expiryDate = expiryDate; }

    public boolean isValid() {
        return "active".equalsIgnoreCase(status) && 
               expiryDate != null && 
               !expiryDate.isBefore(LocalDate.now());
    }
}