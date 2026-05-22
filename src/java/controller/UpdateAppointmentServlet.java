package controller;

import dao.AppointmentDAO;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/UpdateAppointmentServlet")
public class UpdateAppointmentServlet extends HttpServlet {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        int apptId = parseInt(req.getParameter("id"), -1);

        if (apptId == -1 || action == null) {
            res.sendRedirect(req.getContextPath() + "/index.jsp");
            return;
        }

        boolean ok = false;
        String cancelReason = req.getParameter("reason");

        System.out.println("=== UpdateAppointmentServlet Debug ===");
        System.out.println("Appointment ID: " + apptId);
        System.out.println("Action: " + action);
        System.out.println("User Role: " + user.getRole());

        switch (action) {
            case "confirm":
                System.out.println("→ Confirming appointment...");
                ok = appointmentDAO.updateStatus(apptId, "confirmed");
                break;
            case "complete":
                System.out.println("→ Completing appointment...");
                ok = appointmentDAO.completeAppointment(apptId);
                break;
            case "cancel":
                String reason = (cancelReason != null && !cancelReason.isEmpty()) ? cancelReason : "Cancelled by user";
                System.out.println("→ Cancelling appointment, reason: " + reason);
                ok = appointmentDAO.cancelAppointment(apptId, reason);
                break;
            case "no-show":
                System.out.println("→ Marking as no-show...");
                ok = appointmentDAO.updateStatus(apptId, "no-show");
                if (ok) {
                    AuditLogger.log(user.getUserId(), "NO_SHOW_MARKED",
                            "Appointment #" + apptId + " marked as no-show",
                            req.getRemoteAddr());
                }
                break;
            case "reschedule":
                System.out.println("→ Rescheduling appointment...");
                ok = appointmentDAO.updateStatus(apptId, "rescheduled");
                break;
            default:
                System.out.println("→ Unknown action: " + action);
                ok = false;
        }

        System.out.println("Result: " + (ok ? "SUCCESS" : "FAILED"));
        System.out.println("=====================================");

        AuditLogger.log(user.getUserId(), "UPDATE_APPOINTMENT",
                "Appointment #" + apptId + " action=" + action + " ok=" + ok,
                req.getRemoteAddr());

        String redirectPath = getRedirectPath(user.getRole());
        String param = ok ? "?success=Status+updated" : "?error=Update+failed";
        res.sendRedirect(req.getContextPath() + redirectPath + param);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        doGet(req, res);
    }

    private String getRedirectPath(String role) {
        if (role == null) return "/index.jsp";
        
        switch (role.toLowerCase()) {
            case "doctor":
                return "/doctor/manageAppointments.jsp";
            case "patient":
                return "/patient/myAppointments.jsp";
            case "admin":
                return "/admin/appointments.jsp";
            default:
                return "/index.jsp";
        }
    }

    private int parseInt(String s, int defaultValue) {
        if (s == null || s.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}