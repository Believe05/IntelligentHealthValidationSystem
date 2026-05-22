package model;

public class ValidationLog {
    private int     validationId;
    private int     patientId;
    private String  patientName;          // Joined field
    private String  aidProvider;           // Changed from providerName
    private String  memberNumber;
    private String  validationResult;      // Changed from status (approved | rejected)
    private String  validationTime;        // Changed from validationDate

    public ValidationLog() {}

    // Getters and Setters
    public int getValidationId() { return validationId; }
    public void setValidationId(int validationId) { this.validationId = validationId; }

    public int getPatientId() { return patientId; }
    public void setPatientId(int patientId) { this.patientId = patientId; }

    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }

    public String getAidProvider() { return aidProvider; }
    public void setAidProvider(String aidProvider) { this.aidProvider = aidProvider; }

    public String getMemberNumber() { return memberNumber; }
    public void setMemberNumber(String memberNumber) { this.memberNumber = memberNumber; }

    public String getValidationResult() { return validationResult; }
    public void setValidationResult(String validationResult) { this.validationResult = validationResult; }

    public String getValidationTime() { return validationTime; }
    public void setValidationTime(String validationTime) { this.validationTime = validationTime; }

    // Backward compatibility
    public String getProviderName() { return aidProvider; }
    public void setProviderName(String providerName) { this.aidProvider = providerName; }

    public String getStatus() { return validationResult; }
    public void setStatus(String status) { this.validationResult = status; }

    public String getValidationDate() { return validationTime; }
    public void setValidationDate(String validationDate) { this.validationTime = validationDate; }
}