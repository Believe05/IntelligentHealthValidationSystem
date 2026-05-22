package controller;

import dao.UserDAO;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        // Check if already logged in
        HttpSession session = req.getSession(false);
        if (session != null) {
            User user = (User) session.getAttribute("user");
            if (user != null && user.isActive()) {
                redirectByRole(user, req, res);
                return;
            }
        }
        
        // Clear any existing session and show login page
        if (session != null) {
            session.invalidate();
        }
        
        req.getRequestDispatcher("/login.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String ip = req.getRemoteAddr();

        // Validate input
        if (isEmpty(username) || isEmpty(password)) {
            req.setAttribute("error", "Username and password are required.");
            req.getRequestDispatcher("/login.jsp").forward(req, res);
            return;
        }

        // Trim and sanitize
        username = username.trim();
        password = password.trim();

        // Validate user
        User user = userDAO.validateUser(username, password);

        if (user != null && user.isActive()) {
            // Create new session
            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);
            session.setMaxInactiveInterval(30 * 60); // 30-minute timeout
            
            // Log successful login
            AuditLogger.log(user.getUserId(), "LOGIN_SUCCESS", 
                          "User logged in successfully from IP: " + ip, ip);
            
            redirectByRole(user, req, res);
        } else {
            // Log failed attempt
            AuditLogger.log(0, "LOGIN_FAILED", 
                          "Failed login attempt for username: " + username + " from IP: " + ip, ip);
            
            req.setAttribute("error", "Invalid username or password or account deactivated.");
            req.getRequestDispatcher("/login.jsp").forward(req, res);
        }
    }

    private void redirectByRole(User user, HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        if (user == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        
        String base = req.getContextPath();
        String role = user.getRole();
        
        if (role == null) {
            res.sendRedirect(base + "/login.jsp");
            return;
        }
        
        switch (role.toLowerCase()) {
            case "patient":
                res.sendRedirect(base + "/patient/dashboard.jsp");
                break;
            case "doctor":
                res.sendRedirect(base + "/doctor/dashboard.jsp");
                break;
            case "admin":
                res.sendRedirect(base + "/admin/dashboard.jsp");
                break;
            case "medicalaid":
                res.sendRedirect(base + "/medicalaid/dashboard.jsp");
                break;
            default:
                res.sendRedirect(base + "/index.jsp");
        }
    }

    private boolean isEmpty(String s) { 
        return s == null || s.trim().isEmpty(); 
    }
}