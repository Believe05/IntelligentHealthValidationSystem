package model;

import java.util.List;

public class Doctor extends User {
    private int                 doctorId;
    private String              specialization;
    private String              qualification;      // New field
    private double              consultationFee;
    private List<DoctorSchedule> schedule; 
    
    // Changed from availableDays/availableTime
   // Add to Doctor.java model class
     


    public Doctor() {
        super();
        this.consultationFee = 0.0;
    }

    // Getters and Setters
    public int getDoctorId() { return doctorId; }
    public void setDoctorId(int doctorId) { this.doctorId = doctorId; }

    public String getSpecialization() { return specialization; }
    public void setSpecialization(String specialization) { this.specialization = specialization; }

    public String getQualification() { return qualification; }
    public void setQualification(String qualification) { this.qualification = qualification; }

    public double getConsultationFee() { return consultationFee; }
    public void setConsultationFee(double consultationFee) { this.consultationFee = consultationFee; }

    public List<DoctorSchedule> getSchedule() { return schedule; }
    public void setSchedule(List<DoctorSchedule> schedule) { this.schedule = schedule; }

    // Backward compatibility methods
    public String getAvailableDays() { 
        // This would need to be derived from schedule
        return schedule != null ? schedule.toString() : ""; 
    }
    public void setAvailableDays(String availableDays) { 
        // Ignore - use schedule instead
    }

    public String getAvailableTime() { 
        // This would need to be derived from schedule
        return ""; 
    }
    public void setAvailableTime(String availableTime) { 
        // Ignore - use schedule instead
    }

    public boolean isAvailable() { 
        // This would need real logic checking today's schedule
        return schedule != null && !schedule.isEmpty(); 
    }
    public void setAvailable(boolean available) { 
        // Ignore - availability derived from schedule
    }
}