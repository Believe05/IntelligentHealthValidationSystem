package service;

import model.Appointment;
import model.User;

/**
 * Email Service for IHVS system.
 * 
 * Current version is a STUB that logs emails to console.
 * This allows the project to compile without javax.mail JAR.
 * 
 * To enable real email sending:
 * 1. Add javax.mail.jar and activation.jar to WEB-INF/lib
 * 2. Uncomment the commented code below
 * 3. Configure SMTP settings
 */
public class EmailService {
    
    private static final String SEPARATOR = "============================================================";
    
    /**
     * Send appointment reminder email (STUB VERSION - logs to console)
     */
    public static boolean sendAppointmentReminder(Appointment apt, User patient) {
        if (apt == null || patient == null) {
            System.err.println("[EmailService] Cannot send reminder: Appointment or Patient is null");
            return false;
        }
        
        String to = patient.getEmail() != null ? patient.getEmail() : "unknown@example.com";
        String subject = "Appointment Reminder - IHVS";
        String body = buildReminderEmail(apt, patient);
        
        // Log the email to console (for development/demo)
        System.out.println("\n" + SEPARATOR);
        System.out.println("📧 EMAIL REMINDER (STUB MODE - No actual email sent)");
        System.out.println("To: " + to);
        System.out.println("Subject: " + subject);
        System.out.println(repeatChar('-', 60));
        System.out.println(body);
        System.out.println(SEPARATOR + "\n");
        
        // TODO: Uncomment this block when javax.mail JAR is added
        /*
        return sendEmail(to, subject, body);
        */
        
        return true;
    }
    
    /**
     * Build the reminder email body
     */
    private static String buildReminderEmail(Appointment apt, User patient) {
        String patientName = patient.getFullName() != null ? patient.getFullName() : "Patient";
        String appointmentDate = apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "scheduled date";
        String appointmentTime = apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "scheduled time";
        String doctorName = apt.getDoctorName() != null ? apt.getDoctorName() : "your doctor";
        
        return String.format(
            "Dear %s,\n\n" +
            "This is a reminder for your upcoming appointment:\n\n" +
            "Date: %s\n" +
            "Time: %s\n" +
            "Doctor: %s\n\n" +
            "Please arrive 15 minutes early.\n\n" +
            "Thank you,\n" +
            "IHVS System",
            patientName, appointmentDate, appointmentTime, doctorName);
    }
    
    
    
    
    /**
     * Send email - REAL IMPLEMENTATION (commented out)
     * Uncomment when javax.mail JAR is added to WEB-INF/lib
     */
    /*
    private static boolean sendEmail(String to, String subject, String body) {
        Properties props = new Properties();
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        
        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, FROM_PASSWORD);
            }
        });
        
        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress("noreply@ihvs.com"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject(subject);
            message.setText(body);
            
            Transport.send(message);
            System.out.println("[EmailService] Email sent successfully to " + to);
            return true;
        } catch (MessagingException e) {
            System.err.println("[EmailService] Failed to send email: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    */
    
    private static String repeatChar(char ch, int count) {
        StringBuilder sb = new StringBuilder(count);
        for (int i = 0; i < count; i++) {
            sb.append(ch);
        }
        return sb.toString();
    }
}