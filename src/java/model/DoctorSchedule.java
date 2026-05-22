package model;

public class DoctorSchedule {
    private int scheduleId;
    private int doctorId;
    private String dayOfWeek;
    private String startTime;
    private String endTime;
    
    // Getters
    public int getScheduleId() { return scheduleId; }
    public int getDoctorId() { return doctorId; }
    public String getDayOfWeek() { return dayOfWeek; }
    public String getStartTime() { return startTime; }
    public String getEndTime() { return endTime; }
    
    // Setters
    public void setScheduleId(int scheduleId) { this.scheduleId = scheduleId; }
    public void setDoctorId(int doctorId) { this.doctorId = doctorId; }
    public void setDayOfWeek(String dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    public void setStartTime(String startTime) { this.startTime = startTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
}