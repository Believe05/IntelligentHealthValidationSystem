package model;

public class Patient extends User {
    private int patientId;
    private String medicalAidProvider;
    private String medicalAidNumber;
    private String membershipStatus;
    private int reliabilityScore;
    private int totalAppointments;
    private int completedCount;
    private int noShowCount;
    private int cancellationCount;
    private String lastValidation;

    public Patient() {
        super();
        this.reliabilityScore = 100;
        this.totalAppointments = 0;
        this.completedCount = 0;
        this.noShowCount = 0;
        this.cancellationCount = 0;
        this.membershipStatus = "pending";
    }

    // Getters and Setters
    public int getPatientId() { return patientId; }
    public void setPatientId(int patientId) { this.patientId = patientId; }

    public String getMedicalAidProvider() { return medicalAidProvider; }
    public void setMedicalAidProvider(String medicalAidProvider) { this.medicalAidProvider = medicalAidProvider; }

    public String getMedicalAidNumber() { return medicalAidNumber; }
    public void setMedicalAidNumber(String medicalAidNumber) { this.medicalAidNumber = medicalAidNumber; }

    public String getMembershipStatus() { return membershipStatus; }
    public void setMembershipStatus(String membershipStatus) { this.membershipStatus = membershipStatus; }

    public int getReliabilityScore() { return reliabilityScore; }
    public void setReliabilityScore(int reliabilityScore) { this.reliabilityScore = reliabilityScore; }

    public int getTotalAppointments() { return totalAppointments; }
    public void setTotalAppointments(int totalAppointments) { this.totalAppointments = totalAppointments; }

    public int getCompletedCount() { return completedCount; }
    public void setCompletedCount(int completedCount) { this.completedCount = completedCount; }

    public int getNoShowCount() { return noShowCount; }
    public void setNoShowCount(int noShowCount) { this.noShowCount = noShowCount; }

    public int getCancellationCount() { return cancellationCount; }
    public void setCancellationCount(int cancellationCount) { this.cancellationCount = cancellationCount; }

    public String getLastValidation() { return lastValidation; }
    public void setLastValidation(String lastValidation) { this.lastValidation = lastValidation; }

    // Backward compatibility
    public int getNoShows() { return noShowCount; }
    public void setNoShows(int noShows) { this.noShowCount = noShows; }

    public boolean hasValidMedicalAid() {
        return medicalAidProvider != null && !medicalAidProvider.trim().isEmpty() &&
               medicalAidNumber != null && !medicalAidNumber.trim().isEmpty() &&
               "active".equals(membershipStatus);
    }

    public boolean isMedicalAidInfoComplete() {
        return medicalAidProvider != null && !medicalAidProvider.trim().isEmpty() &&
               medicalAidNumber != null && !medicalAidNumber.trim().isEmpty();
    }

    public String getMaskedMedicalAidNumber() {
        if (medicalAidNumber == null || medicalAidNumber.length() < 4) return "****";
        return "****" + medicalAidNumber.substring(medicalAidNumber.length() - 4);
    }

    public double getNoShowPercentage() {
        if (totalAppointments == 0) return 0.0;
        return Math.round((noShowCount * 100.0 / totalAppointments) * 10.0) / 10.0;
    }

    public double getCompletionRate() {
        if (totalAppointments == 0) return 0.0;
        return Math.round((completedCount * 100.0 / totalAppointments) * 10.0) / 10.0;
    }

    public double getCancellationRate() {
        if (totalAppointments == 0) return 0.0;
        return Math.round((cancellationCount * 100.0 / totalAppointments) * 10.0) / 10.0;
    }

    public void updateReliabilityScore() {
        int score = 100;
        score -= (noShowCount * 10);
        score -= (cancellationCount * 5);
        this.reliabilityScore = Math.max(0, Math.min(100, score));
    }

    @Override
    public String toString() {
        return String.format("Patient{id=%d, name=%s, medicalAid=%s, reliability=%d%%}", 
            patientId, getFullName(), 
            medicalAidProvider != null ? medicalAidProvider : "None", 
            reliabilityScore);
    }
}