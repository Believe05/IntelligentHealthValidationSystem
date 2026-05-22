package controller;

import dao.PatientDAO;
import dao.UserDAO;
import dao.AppointmentDAO;
import dao.MedicalAidDAO;
import model.Patient;
import model.User;
import model.MedicalAid;  // FIX: Added missing import
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/PatientServlet")
public class PatientServlet extends HttpServlet {

    private final PatientDAO     patientDAO     = new PatientDAO();
    private final UserDAO        userDAO        = new UserDAO();
    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final MedicalAidDAO  medicalAidDAO  = new MedicalAidDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || !"patient".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");

        if ("updateProfile".equals(action)) {
            user.setFullName(req.getParameter("fullName"));
            user.setEmail(req.getParameter("email"));
            user.setPhone(req.getParameter("phone"));
            boolean ok = userDAO.updateUser(user);
            if (ok) session.setAttribute("user", user);
            AuditLogger.log(user.getUserId(), "UPDATE_PROFILE",
                    "Patient profile updated", req.getRemoteAddr());
            redirect(res, req, "/patient/profile.jsp",
                    ok ? "Profile updated." : null,
                    ok ? null : "Update failed.");

        } else if ("updateMedicalAid".equals(action)) {
            Patient patient = patientDAO.getPatientByUserId(user.getUserId());
            if (patient == null) {
                redirect(res, req, "/patient/profile.jsp", null, "Patient not found.");
                return;
            }

            String provider = req.getParameter("medicalAidProvider");
            String number   = req.getParameter("medicalAidNumber");

            if (provider == null || provider.trim().isEmpty()) {
                redirect(res, req, "/patient/profile.jsp", null, "Medical aid provider is required.");
                return;
            }

            // Update the patient record to 'pending'
            boolean ok = patientDAO.updateMedicalAidWithStatus(
                    patient.getPatientId(),
                    provider.trim(),
                    number != null ? number.trim() : null,
                    "pending");

            if (ok) {
                patientDAO.recalculatePRI(patient.getPatientId());
                System.out.println("Medical aid updated successfully for patientId: " + patient.getPatientId());
            } else {
                System.out.println("Update FAILED for patientId: " + patient.getPatientId());
            }

            AuditLogger.log(user.getUserId(), "UPDATE_MEDICAL_AID",
                    "Provider=" + provider, req.getRemoteAddr());
            redirect(res, req, "/patient/profile.jsp",
                    ok ? "Medical aid updated. Waiting for provider approval." : null,
                    ok ? null : "Update failed.");

        } else {
            res.sendRedirect(req.getContextPath() + "/patient/profile.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        doPost(req, res);
    }

    private void redirect(HttpServletResponse res, HttpServletRequest req,
                          String path, String success, String error) throws IOException {
        StringBuilder url = new StringBuilder(req.getContextPath()).append(path).append("?");
        if (success != null) url.append("success=").append(success.replace(" ", "+"));
        if (error   != null) url.append("error=").append(error.replace(" ", "+"));
        res.sendRedirect(url.toString());
    }
}