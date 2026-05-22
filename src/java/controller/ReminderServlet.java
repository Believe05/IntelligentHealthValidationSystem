package controller;

import dao.ReminderDAO;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/ReminderServlet")
public class ReminderServlet extends HttpServlet {

    private final ReminderDAO reminderDAO = new ReminderDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || !"admin".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        String contextPath = req.getContextPath();

        if ("markSent".equals(action)) {
            int id = parseInt(req.getParameter("id"), -1);
            reminderDAO.markReminderAsSent(id);
            AuditLogger.log(user.getUserId(), "REMINDER_MARK_SENT",
                    "Reminder ID: " + id, req.getRemoteAddr());
            res.sendRedirect(contextPath + "/admin/reminders.jsp?success=Reminder+marked+as+sent");

        } else if ("delete".equals(action)) {
            int id = parseInt(req.getParameter("id"), -1);
            reminderDAO.deleteReminder(id);
            AuditLogger.log(user.getUserId(), "REMINDER_DELETE",
                    "Deleted reminder ID: " + id, req.getRemoteAddr());
            res.sendRedirect(contextPath + "/admin/reminders.jsp?success=Reminder+deleted");

        } else {
            res.sendRedirect(contextPath + "/admin/reminders.jsp");
        }
    }

    private int parseInt(String s, int def) {
        try {
            return Integer.parseInt(s);
        } catch (Exception e) {
            return def;
        }
    }
}