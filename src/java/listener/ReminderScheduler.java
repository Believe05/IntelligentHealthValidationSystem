package listener;

import dao.AppointmentDAO;
import dao.ReminderDAO;
import model.Appointment;
import model.Reminder;
import util.DBConnection;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@WebListener
public class ReminderScheduler implements ServletContextListener {

    private ScheduledExecutorService executor;
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final String SEPARATOR_LINE = "============================================================";

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        executor = Executors.newSingleThreadScheduledExecutor();
        executor.scheduleAtFixedRate(this::processReminders, 1, 5, TimeUnit.MINUTES);
        System.out.println("[ReminderScheduler] Started — checking every 5 minutes at " + 
                          LocalDateTime.now().format(TIME_FORMATTER));
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (executor != null) {
            executor.shutdownNow();
            try {
                if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                    System.err.println("[ReminderScheduler] Executor did not terminate properly");
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        System.out.println("[ReminderScheduler] Stopped");
    }

    private void processReminders() {
        System.out.println("[ReminderScheduler] Checking for pending reminders at " + 
                          LocalDateTime.now().format(TIME_FORMATTER));
        
        ReminderDAO reminderDAO = new ReminderDAO();
        AppointmentDAO apptDAO = new AppointmentDAO();
        
        List<Reminder> pending = reminderDAO.getPendingReminders();
        
        if (pending == null || pending.isEmpty()) {
            System.out.println("[ReminderScheduler] No pending reminders found");
            return;
        }
        
        System.out.println("[ReminderScheduler] Found " + pending.size() + " pending reminder(s)");
        
        for (Reminder r : pending) {
            if (r == null) continue;
            
            try {
                Appointment apt = apptDAO.getAppointmentById(r.getAppointmentId());
                
                if (apt == null) { 
                    System.err.println("[ReminderScheduler] Appointment not found for reminder #" + r.getReminderId());
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    continue; 
                }
                
                PatientInfo patient = getPatientInfo(apt.getPatientId());
                
                String aptStatus = apt.getStatus();
                if ("cancelled".equals(aptStatus) || "completed".equals(aptStatus) || "no-show".equals(aptStatus)) {
                    System.out.println("[ReminderScheduler] Skipping reminder #" + r.getReminderId() + 
                                     " - appointment status: " + aptStatus);
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    continue;
                }
                
                boolean sent = sendReminder(r, apt, patient);
                
                if (sent) {
                    reminderDAO.markReminderAsSent(r.getReminderId());
                    logAuditEvent(apt.getPatientId(), "REMINDER_SENT",
                            "Appointment #" + apt.getAppointmentId() + " | " + r.getReminderType() + " reminder sent");
                    System.out.println("[ReminderScheduler] Successfully sent reminder #" + r.getReminderId());
                } else {
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    System.err.println("[ReminderScheduler] Failed to send reminder #" + r.getReminderId());
                }
                
            } catch (Exception e) {
                System.err.println("[ReminderScheduler] Failed to process reminder #" + 
                                  (r != null ? r.getReminderId() : "unknown") + ": " + e.getMessage());
                e.printStackTrace();
                
                if (r != null) {
                    try {
                        reminderDAO.markReminderAsFailed(r.getReminderId());
                    } catch (Exception ex) {
                        System.err.println("[ReminderScheduler] Could not mark reminder as failed: " + ex.getMessage());
                    }
                }
            }
        }
    }
    
    private void logAuditEvent(int userId, String action, String details) {
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address, log_time) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, action);
            ps.setString(3, details);
            ps.setString(4, "scheduler");
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[ReminderScheduler] Failed to log audit event: " + e.getMessage());
        }
    }
    
    private PatientInfo getPatientInfo(int patientId) {
        PatientInfo info = new PatientInfo();
        String sql = "SELECT u.email, u.phone, u.full_name FROM users u " +
                     "JOIN patients p ON u.user_id = p.user_id WHERE p.patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                info.email = rs.getString("email");
                info.phone = rs.getString("phone");
                info.name = rs.getString("full_name");
                if (info.name == null) info.name = "Patient";
            } else {
                info.name = "Patient";
            }
        } catch (SQLException e) {
            System.err.println("[ReminderScheduler] Error getting patient info: " + e.getMessage());
            info.name = "Patient";
        }
        return info;
    }
    
    private String getDoctorName(int doctorId) {
        String sql = "SELECT u.full_name FROM users u JOIN doctors d ON u.user_id = d.user_id WHERE d.doctor_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getString("full_name");
            }
        } catch (SQLException e) {
            System.err.println("[ReminderScheduler] Error getting doctor name: " + e.getMessage());
        }
        return "your doctor";
    }

    private boolean sendReminder(Reminder reminder, Appointment apt, PatientInfo patient) {
        if (reminder == null || apt == null || patient == null) return false;
        
        try {
            String doctorName = getDoctorName(apt.getDoctorId());
            String appointmentDate = apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "scheduled date";
            String appointmentTime = apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "scheduled time";
            
            String when = "24h".equals(reminder.getReminderType()) ? "tomorrow" : "in 1 hour";
            
            String subject = "[IHVS REMINDER] Your appointment is " + when;
            String message = buildMessage(patient.name, doctorName, appointmentDate, appointmentTime, when);

            printReminder(reminder, patient.email, subject, message);
            
            boolean emailSent = false;
            if (patient.email != null && !patient.email.trim().isEmpty()) {
                emailSent = sendEmail(patient.email, subject, message);
                System.out.println("[ReminderScheduler] Email sending result: " + emailSent);
            } else {
                System.out.println("[ReminderScheduler] No email address for patient, skipping email");
            }
            
            boolean smsSent = false;
            if (patient.phone != null && !patient.phone.trim().isEmpty()) {
                smsSent = sendSms(patient.phone, message);
                System.out.println("[ReminderScheduler] SMS sending result: " + smsSent);
            }
            
            return emailSent || smsSent;
            
        } catch (Exception e) {
            System.err.println("[ReminderScheduler] Error in sendReminder: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    private String buildMessage(String patientName, String doctorName, String date, String time, String when) {
        return String.format(
            "Dear %s,\n\n" +
            "This is a reminder that your appointment with %s on %s at %s is %s.\n\n" +
            "Please attend on time or cancel at least 2 hours in advance to avoid affecting your reliability score.\n\n" +
            "Thank you,\nIHVS System",
            patientName, doctorName, date, time, when);
    }
    
    private void printReminder(Reminder reminder, String email, String subject, String message) {
        System.out.println("\n" + SEPARATOR_LINE);
        System.out.println("📧 REMINDER (" + reminder.getReminderType() + ")");
        System.out.println("Reminder ID: " + reminder.getReminderId());
        System.out.println("To: " + email);
        System.out.println("Subject: " + subject);
        System.out.println("------------------------------------------------------------");
        System.out.println(message);
        System.out.println(SEPARATOR_LINE + "\n");
    }
    
    private boolean sendEmail(String to, String subject, String body) {
        System.out.println("[EMAIL] Would send to: " + to);
        System.out.println("[EMAIL] Subject: " + subject);
        return true;
    }
    
    private boolean sendSms(String to, String message) {
        System.out.println("[SMS] Would send to: " + to);
        if (message.length() > 100) {
            System.out.println("[SMS] Message: " + message.substring(0, 100) + "...");
        } else {
            System.out.println("[SMS] Message: " + message);
        }
        return true;
    }
    
    private static class PatientInfo {
        String email;
        String phone;
        String name;
    }
}