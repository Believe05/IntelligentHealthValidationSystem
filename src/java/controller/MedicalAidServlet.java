package controller;

import dao.AppointmentDAO;
import dao.MedicalAidDAO;
import dao.PatientDAO;
import model.Appointment;
import model.MedicalAidProvider;
import model.Patient;
import model.User;
import util.AuditLogger;
import util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/MedicalAidServlet")
public class MedicalAidServlet extends HttpServlet {

    private final MedicalAidDAO  medicalAidDAO  = new MedicalAidDAO();
    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final PatientDAO     patientDAO     = new PatientDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = requireMedicalAid(req, res);
        if (user == null) return;

        MedicalAidProvider provider = getProviderForUser(user);
        if (provider == null) {
            provider = createProviderFromUser(user);
        }

        String action      = req.getParameter("action");
        String contextPath = req.getContextPath();

        // Patient-level approve / reject
        if ("approvePatient".equals(action) || "rejectPatient".equals(action)) {
            handleApproveRejectPatient(req, res, user, provider, contextPath);
            return;
        }

        // Appointment-level approve / reject
        if ("approve".equals(action) || "reject".equals(action)) {
            handleApproveReject(req, res, user, provider, contextPath);
            return;
        }

        // Default: show dashboard or validations page
        String view = req.getParameter("view");
        if ("validations".equals(view)) {
            showValidations(req, res, user, provider);
        } else if ("history".equals(view)) {
            showHistory(req, res, user, provider);
        } else {
            showDashboard(req, res, user, provider, contextPath);
        }
    }

    // ==================== PATIENT-LEVEL APPROVE/REJECT ====================
    private void handleApproveRejectPatient(HttpServletRequest req, HttpServletResponse res,
                                             User user, MedicalAidProvider provider,
                                             String contextPath)
            throws IOException {

        int    patientId = parseInt(req.getParameter("patientId"), -1);
        String action    = req.getParameter("action");

        if (patientId == -1) {
            res.sendRedirect(contextPath + "/MedicalAidServlet?error=Missing+patient+ID.");
            return;
        }

        boolean approved  = "approvePatient".equals(action);
        String  newMembershipStatus = approved ? "active" : "rejected";
        String  newValidationStatus = approved ? "active" : "rejected";

        System.out.println("========== MEDICAL AID VALIDATION ==========");
        System.out.println("Patient ID: " + patientId);
        System.out.println("Action: " + action);
        System.out.println("New Membership Status: " + newMembershipStatus);
        System.out.println("New Validation Status: " + newValidationStatus);
        System.out.println("============================================");

        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // 1. Update patient membership status
            String updatePatientSql = "UPDATE patients SET membership_status = ?, last_validation = CURRENT_TIMESTAMP WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updatePatientSql)) {
                ps.setString(1, newMembershipStatus);
                ps.setInt(2, patientId);
                int patientUpdated = ps.executeUpdate();
                System.out.println("Patient membership updated: " + patientUpdated + " rows");
            }
            
            // 2. Update ALL appointments for this patient
            String updateAppointmentsSql = "UPDATE appointments SET validation_status = ?, validation_timestamp = CURRENT_TIMESTAMP WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateAppointmentsSql)) {
                ps.setString(1, newValidationStatus);
                ps.setInt(2, patientId);
                int appointmentsUpdated = ps.executeUpdate();
                System.out.println("Appointments updated: " + appointmentsUpdated + " rows for patient " + patientId);
            }
            
            // 3. Recalculate PRI if approved
            if (approved) {
                recalculatePRI(con, patientId);
            }
            
            con.commit();
            System.out.println("✅ TRANSACTION COMMITTED SUCCESSFULLY");
            
            verifyUpdate(patientId, newValidationStatus);
            
            AuditLogger.log(user.getUserId(), "MEDAID_PATIENT_VALIDATE",
                    "patientId=" + patientId + " | " + newMembershipStatus + " | Provider: " +
                    (provider != null ? provider.getProviderName() : "Unknown"),
                    req.getRemoteAddr());

            String msg = approved ? "Patient+medical+aid+approved.+All+appointments+updated+to+ACTIVE." : 
                                   "Patient+medical+aid+rejected.";
            res.sendRedirect(contextPath + "/MedicalAidServlet?success=" + msg);
            
        } catch (SQLException e) {
            System.err.println("❌ ERROR in transaction: " + e.getMessage());
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            res.sendRedirect(contextPath + "/MedicalAidServlet?error=Update+failed:+ " + e.getMessage());
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); con.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }

    // ==================== APPOINTMENT-LEVEL APPROVE/REJECT ====================
    private void handleApproveReject(HttpServletRequest req, HttpServletResponse res,
                                      User user, MedicalAidProvider provider,
                                      String contextPath)
            throws IOException {

        int appointmentId = parseInt(req.getParameter("appointmentId"), -1);
        int patientId     = parseInt(req.getParameter("patientId"),     -1);

        if (appointmentId == -1 || patientId == -1) {
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&error=Missing+parameters.");
            return;
        }

        Appointment apt = appointmentDAO.getAppointmentById(appointmentId);
        if (apt == null) {
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&error=Appointment+not+found.");
            return;
        }

        if (provider == null) {
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&error=Provider+not+found.");
            return;
        }

        Patient patient = patientDAO.getPatientById(patientId);
        if (patient != null && patient.getMedicalAidProvider() != null
                && !patient.getMedicalAidProvider().equalsIgnoreCase(provider.getProviderName())) {
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&error=Not+authorized+to+validate+this+appointment.");
            return;
        }

        String  action       = req.getParameter("action");
        boolean approved     = "approve".equals(action);
        String  newValStatus = approved ? "active" : "rejected";
        String  newMemStatus = approved ? "active" : "rejected";

        System.out.println("========== APPOINTMENT VALIDATION ==========");
        System.out.println("Appointment ID: " + appointmentId);
        System.out.println("Patient ID: " + patientId);
        System.out.println("Action: " + action);
        System.out.println("New Validation Status: " + newValStatus);
        System.out.println("============================================");

        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // 1. Update this specific appointment
            String updateApptSql = "UPDATE appointments SET validation_status = ?, validation_timestamp = CURRENT_TIMESTAMP WHERE appointment_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updateApptSql)) {
                ps.setString(1, newValStatus);
                ps.setInt(2, appointmentId);
                int updated = ps.executeUpdate();
                System.out.println("Appointment updated: " + updated + " rows");
            }
            
            // 2. Update patient membership status
            String updatePatientSql = "UPDATE patients SET membership_status = ?, last_validation = CURRENT_TIMESTAMP WHERE patient_id = ?";
            try (PreparedStatement ps = con.prepareStatement(updatePatientSql)) {
                ps.setString(1, newMemStatus);
                ps.setInt(2, patientId);
                ps.executeUpdate();
                System.out.println("Patient membership updated");
            }
            
            // 3. Update ALL other appointments for this patient
            String updateAllApptsSql = "UPDATE appointments SET validation_status = ?, validation_timestamp = CURRENT_TIMESTAMP WHERE patient_id = ? AND appointment_id != ?";
            try (PreparedStatement ps = con.prepareStatement(updateAllApptsSql)) {
                ps.setString(1, newValStatus);
                ps.setInt(2, patientId);
                ps.setInt(3, appointmentId);
                int otherUpdated = ps.executeUpdate();
                System.out.println("Other appointments updated: " + otherUpdated + " rows");
            }
            
            // 4. Recalculate PRI if approved
            if (approved) {
                recalculatePRI(con, patientId);
            }
            
            con.commit();
            System.out.println("✅ TRANSACTION COMMITTED SUCCESSFULLY");
            
            verifySingleAppointmentUpdate(appointmentId, newValStatus);
            
            AuditLogger.log(user.getUserId(), "MEDAID_VALIDATE",
                    "apptId=" + appointmentId + " | " + newValStatus + " | Provider: " +
                    (provider != null ? provider.getProviderName() : "Unknown"),
                    req.getRemoteAddr());

            String msg = approved ? "Medical+aid+approved.+Status+set+to+ACTIVE." : "Medical+aid+rejected.";
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&success=" + msg);
            
        } catch (SQLException e) {
            System.err.println("❌ ERROR in transaction: " + e.getMessage());
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            res.sendRedirect(contextPath + "/MedicalAidServlet?view=validations&error=Update+failed.");
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); con.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }

    // ==================== RECALCULATE PRI ====================
    private void recalculatePRI(Connection con, int patientId) throws SQLException {
        String statsSql = "SELECT total_appointments, no_show_count, cancellation_count FROM patients WHERE patient_id = ?";
        int total = 0, noShows = 0, cancelled = 0;
        
        try (PreparedStatement ps = con.prepareStatement(statsSql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                total = rs.getInt("total_appointments");
                noShows = rs.getInt("no_show_count");
                cancelled = rs.getInt("cancellation_count");
            }
        }
        
        int pri = 100;
        if (total > 0) {
            pri = 100 - (noShows * 10) - (cancelled * 5);
            pri = Math.max(0, Math.min(100, pri));
        }
        
        String updateSql = "UPDATE patients SET reliability_score = ? WHERE patient_id = ?";
        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
            ps.setInt(1, pri);
            ps.setInt(2, patientId);
            ps.executeUpdate();
            System.out.println("PRI recalculated for patient " + patientId + ": " + pri);
        }
    }

    // ==================== VERIFICATION METHODS ====================
    private void verifyUpdate(int patientId, String expectedStatus) {
        String sql = "SELECT appointment_id, validation_status FROM appointments WHERE patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            System.out.println("VERIFICATION - Appointments for patient " + patientId + ":");
            while (rs.next()) {
                System.out.println("  Appt " + rs.getInt("appointment_id") + " status = " + rs.getString("validation_status"));
            }
        } catch (SQLException e) {
            System.err.println("Verification error: " + e.getMessage());
        }
    }
    
    private void verifySingleAppointmentUpdate(int appointmentId, String expectedStatus) {
        String sql = "SELECT validation_status FROM appointments WHERE appointment_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String actual = rs.getString("validation_status");
                System.out.println("VERIFICATION - Appt " + appointmentId + " status = " + actual + " (expected: " + expectedStatus + ")");
            }
        } catch (SQLException e) {
            System.err.println("Verification error: " + e.getMessage());
        }
    }

    // ==================== DASHBOARD VIEW ====================
    private void showDashboard(HttpServletRequest req, HttpServletResponse res,
                                User user, MedicalAidProvider provider,
                                String contextPath)
            throws ServletException, IOException {

        if (provider == null) {
            req.setAttribute("error", "Your medical aid provider account is not fully configured.");
            req.setAttribute("pendingPatients",  new ArrayList<>());
            req.setAttribute("approvedPatients", new ArrayList<>());
            req.setAttribute("rejectedPatients", new ArrayList<>());
            req.setAttribute("provider", null);
            req.getRequestDispatcher("/medicalaid/dashboard.jsp").forward(req, res);
            return;
        }

        String providerName = provider.getProviderName();

        List<Patient> pendingPatients  = patientDAO.getPatientsByProviderAndStatus(providerName, "pending");
        List<Patient> approvedPatients = patientDAO.getPatientsByProviderAndStatus(providerName, "active");
        List<Patient> rejectedPatients = patientDAO.getPatientsByProviderAndStatus(providerName, "rejected");
        
        List<Appointment> pendingAppts = appointmentDAO.getPendingValidationsByProvider(providerName);
        
        System.out.println("[MedicalAidServlet] Dashboard load - Provider: " + providerName);
        System.out.println("  Pending patients: " + pendingPatients.size());
        System.out.println("  Approved patients: " + approvedPatients.size());
        System.out.println("  Pending validations: " + pendingAppts.size());

        req.setAttribute("provider",          provider);
        req.setAttribute("pendingPatients",   pendingPatients);
        req.setAttribute("approvedPatients",  approvedPatients);
        req.setAttribute("rejectedPatients",  rejectedPatients);
        req.setAttribute("pendingValidations", pendingAppts);

        req.getRequestDispatcher("/medicalaid/dashboard.jsp").forward(req, res);
    }

    // ==================== VALIDATIONS VIEW ====================
    private void showValidations(HttpServletRequest req, HttpServletResponse res,
                                  User user, MedicalAidProvider provider)
            throws ServletException, IOException {

        List<Appointment> pending = new ArrayList<>();

        if (provider != null) {
            pending = appointmentDAO.getPendingValidationsByProvider(provider.getProviderName());
            System.out.println("[MedicalAidServlet] Validations view - Provider: " + provider.getProviderName() + 
                             ", Pending: " + pending.size());
        }

        req.setAttribute("provider", provider);
        req.setAttribute("pendingValidations", pending);
        req.getRequestDispatcher("/medicalaid/validations.jsp").forward(req, res);
    }

    // ==================== HISTORY VIEW ====================
    private void showHistory(HttpServletRequest req, HttpServletResponse res,
                              User user, MedicalAidProvider provider)
            throws ServletException, IOException {

        req.setAttribute("provider", provider);
        req.getRequestDispatcher("/medicalaid/history.jsp").forward(req, res);
    }

    // ==================== PROVIDER HELPERS ====================
    private MedicalAidProvider getProviderForUser(User user) {
        MedicalAidProvider provider = medicalAidDAO.getProviderByUserId(user.getUserId());
        if (provider == null) {
            List<MedicalAidProvider> all = medicalAidDAO.getAllProviders();
            if (!all.isEmpty()) {
                provider = all.get(0);
                System.out.println("[MedicalAidServlet] Fallback provider: " + provider.getProviderName());
            }
        }
        return provider;
    }

    private MedicalAidProvider createProviderFromUser(User user) {
        try {
            String providerName = generateProviderName(user);
            String sql = "INSERT INTO medical_aid_providers " +
                         "(user_id, provider_name, contact_person, email, phone, is_active, created_date) " +
                         "VALUES (?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)";
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                         sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, user.getUserId());
                ps.setString(2, providerName);
                ps.setString(3, user.getFullName());
                ps.setString(4, user.getEmail());
                ps.setString(5, user.getPhone());
                if (ps.executeUpdate() > 0) {
                    ResultSet rs = ps.getGeneratedKeys();
                    if (rs.next()) {
                        MedicalAidProvider p = new MedicalAidProvider();
                        p.setProviderId(rs.getInt(1));
                        p.setUserId(user.getUserId());
                        p.setProviderName(providerName);
                        p.setContactPerson(user.getFullName());
                        p.setEmail(user.getEmail());
                        p.setPhone(user.getPhone());
                        p.setActive(true);
                        return p;
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("[MedicalAidServlet] Error creating provider: " + e.getMessage());
        }
        return null;
    }

    private String generateProviderName(User user) {
        String fullName = user.getFullName();
        if (fullName == null || fullName.trim().isEmpty()) return "Medical Aid Provider";
        String lower = fullName.toLowerCase();
        if (lower.contains("discovery")) return "Discovery Health";
        if (lower.contains("momentum"))  return "Momentum Health";
        if (lower.contains("bonitas"))   return "Bonitas";
        if (lower.contains("medicover")) return "Medicover";
        if (lower.contains("medshield")) return "Medshield";
        if (lower.contains("bestmed"))   return "Bestmed";
        String name = fullName.trim();
        return name.endsWith("Health") ? name : name + " Health";
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        doGet(req, res);
    }

    private User requireMedicalAid(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return null; }
        User user = (User) session.getAttribute("user");
        if (user == null || !"medicalaid".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}