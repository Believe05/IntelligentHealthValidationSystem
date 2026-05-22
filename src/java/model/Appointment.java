package model;

public class Appointment {
    private int     appointmentId;
    private int     patientId;
    private int     doctorId;
    private int     statusId;
    private String  status;
    private String  appointmentDate;
    private String  appointmentTime;
    private String  validationStatus;
    private String  validationTimestamp;
    private String  cancellationReason;
    private String  notes;
    private boolean reminder24hSent;
    private boolean reminder1hSent;
    private String  createdAt;
    private String  medicalAidNumber;

    // Joined fields
    private String  patientName;
    private String  doctorName;
    private String  specialization;
    private String  patientPhone;
    private String  patientEmail;
    private String  medicalAidProvider;
    private int     reliabilityScore;

    public Appointment() {
        this.validationStatus = "pending";
        this.reminder24hSent = false;
        this.reminder1hSent = false;
    }

    // Getters and Setters
    public int getAppointmentId() { return appointmentId; }
    public void setAppointmentId(int appointmentId) { this.appointmentId = appointmentId; }

    public int getPatientId() { return patientId; }
    public void setPatientId(int patientId) { this.patientId = patientId; }

    public int getDoctorId() { return doctorId; }
    public void setDoctorId(int doctorId) { this.doctorId = doctorId; }

    public int getStatusId() { return statusId; }
    public void setStatusId(int statusId) { this.statusId = statusId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(String appointmentDate) { this.appointmentDate = appointmentDate; }

    public String getAppointmentTime() { return appointmentTime; }
    public void setAppointmentTime(String appointmentTime) { this.appointmentTime = appointmentTime; }

    public String getValidationStatus() { return validationStatus; }
    public void setValidationStatus(String validationStatus) { this.validationStatus = validationStatus; }

    public String getValidationTimestamp() { return validationTimestamp; }
    public void setValidationTimestamp(String validationTimestamp) { this.validationTimestamp = validationTimestamp; }

    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public boolean isReminder24hSent() { return reminder24hSent; }
    public void setReminder24hSent(boolean reminder24hSent) { this.reminder24hSent = reminder24hSent; }

    public boolean isReminder1hSent() { return reminder1hSent; }
    public void setReminder1hSent(boolean reminder1hSent) { this.reminder1hSent = reminder1hSent; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getMedicalAidNumber() { return medicalAidNumber; }
    public void setMedicalAidNumber(String medicalAidNumber) { this.medicalAidNumber = medicalAidNumber; }

    // Joined fields
    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }

    public String getDoctorName() { return doctorName; }
    public void setDoctorName(String doctorName) { this.doctorName = doctorName; }

    public String getSpecialization() { return specialization; }
    public void setSpecialization(String specialization) { this.specialization = specialization; }

    public String getPatientPhone() { return patientPhone; }
    public void setPatientPhone(String patientPhone) { this.patientPhone = patientPhone; }

    public String getPatientEmail() { return patientEmail; }
    public void setPatientEmail(String patientEmail) { this.patientEmail = patientEmail; }

    public String getMedicalAidProvider() { return medicalAidProvider; }
    public void setMedicalAidProvider(String medicalAidProvider) { this.medicalAidProvider = medicalAidProvider; }

    public int getReliabilityScore() { return reliabilityScore; }
    public void setReliabilityScore(int reliabilityScore) { this.reliabilityScore = reliabilityScore; }

    public boolean isConfirmed() { return "confirmed".equals(status); }
    public boolean isCancelled() { return "cancelled".equals(status); }
    public boolean isCompleted() { return "completed".equals(status); }

    // Backward compatibility
    public String getSymptoms() { return notes; }
    public void setSymptoms(String symptoms) { this.notes = symptoms; }
}