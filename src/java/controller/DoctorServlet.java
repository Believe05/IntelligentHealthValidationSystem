package controller;

import dao.DoctorDAO;
import dao.UserDAO;
import model.Doctor;
import model.DoctorSchedule;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/DoctorServlet")
public class DoctorServlet extends HttpServlet {

    private final DoctorDAO doctorDAO = new DoctorDAO();
    private final UserDAO   userDAO   = new UserDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || !"doctor".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp"); 
            return;
        }

        String action = req.getParameter("action");
        Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());

        if ("updateProfile".equals(action)) {
            user.setFullName(req.getParameter("fullName"));
            user.setEmail(req.getParameter("email"));
            user.setPhone(req.getParameter("phone"));
            userDAO.updateUser(user);
            session.setAttribute("user", user);

            if (doctor != null) {
                double fee = 0;
                try { 
                    fee = Double.parseDouble(req.getParameter("consultationFee")); 
                } catch (Exception ignored) {}
                
                String specialization = req.getParameter("specialization");
                String qualification = req.getParameter("qualification");
                
                // Use the 4-parameter version if qualification is provided, otherwise use 3-parameter version
                if (qualification != null && !qualification.trim().isEmpty()) {
                    doctorDAO.updateDoctorProfile(doctor.getDoctorId(),
                            isEmpty(specialization) ? "General Practitioner" : specialization,
                            qualification,
                            fee);
                } else {
                    doctorDAO.updateDoctorProfile(doctor.getDoctorId(),
                            isEmpty(specialization) ? "General Practitioner" : specialization,
                            fee);
                }
            }
            AuditLogger.log(user.getUserId(), "UPDATE_DOCTOR_PROFILE", "", req.getRemoteAddr());
            res.sendRedirect(req.getContextPath() + "/doctor/profile.jsp?success=Profile+updated.");

        } else if ("addSchedule".equals(action) && doctor != null) {
            String day  = req.getParameter("dayOfWeek");
            String start = req.getParameter("startTime");
            String end   = req.getParameter("endTime");
            
            if (!isEmpty(day) && !isEmpty(start) && !isEmpty(end)) {
                doctorDAO.addSchedule(doctor.getDoctorId(), day, start, end);
                AuditLogger.log(user.getUserId(), "ADD_SCHEDULE", 
                              "Day=" + day + " " + start + "-" + end, 
                              req.getRemoteAddr());
                res.sendRedirect(req.getContextPath() + "/doctor/schedule.jsp?success=Schedule+added.");
            } else {
                res.sendRedirect(req.getContextPath() + "/doctor/schedule.jsp?error=All+fields+required.");
            }

        } else if ("removeSchedule".equals(action) && doctor != null) {
            int scheduleId = parseInt(req.getParameter("scheduleId"), -1);
            if (scheduleId != -1) {
                doctorDAO.removeSchedule(scheduleId);
                AuditLogger.log(user.getUserId(), "REMOVE_SCHEDULE", 
                              "Schedule ID=" + scheduleId, 
                              req.getRemoteAddr());
                res.sendRedirect(req.getContextPath() + "/doctor/schedule.jsp?success=Schedule+removed.");
            } else {
                res.sendRedirect(req.getContextPath() + "/doctor/schedule.jsp?error=Invalid+schedule+ID.");
            }

        } else if ("viewSchedule".equals(action) && doctor != null) {
            List<DoctorSchedule> schedule = doctorDAO.getDoctorSchedule(doctor.getDoctorId());
            req.setAttribute("schedule", schedule);
            req.getRequestDispatcher("/doctor/schedule.jsp").forward(req, res);

        } else {
            res.sendRedirect(req.getContextPath() + "/doctor/profile.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException { 
        doPost(req, res); 
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private boolean isEmpty(String s) { 
        return s == null || s.trim().isEmpty(); 
    }
}