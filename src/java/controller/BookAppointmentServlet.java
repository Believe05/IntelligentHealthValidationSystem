package controller;

import dao.*;
import model.*;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet("/BookAppointmentServlet")
public class BookAppointmentServlet extends HttpServlet {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final DoctorDAO      doctorDAO      = new DoctorDAO();
    private final PatientDAO     patientDAO     = new PatientDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = getPatientUser(req, res);
        if (user == null) return;

        Patient patient = patientDAO.getPatientByUserId(user.getUserId());
        if (patient == null) {
            res.sendRedirect(req.getContextPath() + "/patient/dashboard.jsp?error=Patient+profile+not+found.");
            return;
        }

        // Check if patient has medical aid provider
        if (patient.getMedicalAidProvider() == null || patient.getMedicalAidProvider().trim().isEmpty()) {
            req.setAttribute("error", "Please add your medical aid details before booking an appointment.");
            req.getRequestDispatcher("/patient/profile.jsp").forward(req, res);
            return;
        }

        List<Doctor> allDoctors = doctorDAO.getAllDoctors();
        if (allDoctors == null) allDoctors = new java.util.ArrayList<>();

        List<Doctor> availableDoctors = allDoctors.stream()
                .filter(d -> d.getSchedule() != null && !d.getSchedule().isEmpty())
                .collect(Collectors.toList());

        req.setAttribute("doctors", availableDoctors);
        req.setAttribute("patient", patient);
        req.getRequestDispatcher("/patient/bookAppointment.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = getPatientUser(req, res);
        if (user == null) return;

        Patient patient = patientDAO.getPatientByUserId(user.getUserId());
        if (patient == null) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Patient+profile+not+found.");
            return;
        }

        // Check if patient has medical aid provider
        if (patient.getMedicalAidProvider() == null || patient.getMedicalAidProvider().trim().isEmpty()) {
            res.sendRedirect(req.getContextPath() + "/patient/profile.jsp?error=Please+add+your+medical+aid+details+before+booking.");
            return;
        }

        int    doctorId = parseInt(req.getParameter("doctorId"), -1);
        String date     = req.getParameter("appointmentDate");
        String time     = req.getParameter("appointmentTime");
        String notes    = req.getParameter("notes");

        System.out.println("=== BOOK APPOINTMENT ===");
        System.out.println("Patient ID: " + patient.getPatientId());
        System.out.println("Patient Medical Aid Status: " + patient.getMembershipStatus());
        System.out.println("Doctor ID: " + doctorId);
        System.out.println("Date: " + date);
        System.out.println("Time: " + time);

        if (doctorId == -1 || isEmpty(date) || isEmpty(time)) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Doctor,+date+and+time+are+required.");
            return;
        }

        if (!doctorDAO.isDoctorAvailable(doctorId, date, time)) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=That+time+slot+is+already+taken.");
            return;
        }

        // Determine validation status based on patient's membership
        String validationStatus = "active".equalsIgnoreCase(patient.getMembershipStatus()) ? "active" : "pending";
        System.out.println("Setting appointment validation status to: " + validationStatus);

        try {
            // Direct SQL insert to ensure validation status is set correctly
            boolean booked = bookAppointmentDirect(patient.getPatientId(), doctorId, date, time, notes, patient.getMedicalAidProvider(), validationStatus);
            
            System.out.println("Booking result: " + booked);

            if (!booked) {
                res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Booking+failed.+Please+try+again.");
                return;
            }

            AuditLogger.log(user.getUserId(), "BOOK_APPOINTMENT",
                    "Appointment booked with validation status: " + validationStatus,
                    req.getRemoteAddr());

            res.sendRedirect(req.getContextPath() + "/patient/myAppointments.jsp?success=Appointment+booked+successfully!");

        } catch (Exception e) {
            System.err.println("ERROR during booking: " + e.getMessage());
            e.printStackTrace();
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Booking+failed.+Please+try+again.");
        }
    }
    
    private boolean bookAppointmentDirect(int patientId, int doctorId, String date, String time, String notes, String medicalAidProvider, String validationStatus) {
        String sql = "INSERT INTO appointments " +
                     "(patient_id, doctor_id, status_id, appointment_date, appointment_time, " +
                     " notes, validation_status, medical_aid_provider, created_at) " +
                     "VALUES (?, ?, " +
                     " (SELECT status_id FROM appointment_status WHERE status_name = 'pending'), " +
                     " ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
        
        try (Connection con = util.DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            
            ps.setInt(1, patientId);
            ps.setInt(2, doctorId);
            ps.setString(3, date);
            ps.setString(4, time);
            ps.setString(5, notes);
            ps.setString(6, validationStatus);
            ps.setString(7, medicalAidProvider);
            
            int rows = ps.executeUpdate();
            if (rows > 0) {
                // Update patient total appointments
                String updateSql = "UPDATE patients SET total_appointments = total_appointments + 1 WHERE patient_id = ?";
                try (PreparedStatement ps2 = con.prepareStatement(updateSql)) {
                    ps2.setInt(1, patientId);
                    ps2.executeUpdate();
                }
                System.out.println("✅ Appointment booked successfully with validation status: " + validationStatus);
                return true;
            }
        } catch (Exception e) {
            System.err.println("Error in direct booking: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    private User getPatientUser(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        User user = (User) session.getAttribute("user");
        if (user == null || !"patient".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }

    private int parseInt(String s, int def) {
        if (s == null || s.trim().isEmpty()) return def;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }

    private boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}