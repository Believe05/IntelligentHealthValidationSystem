package controller;

import dao.*;
import model.*;
import util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.util.List;

@WebServlet("/DebugServlet")
public class DebugServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        
        res.setContentType("text/html");
        PrintWriter out = res.getWriter();
        
        out.println("<html><head><title>IHVS Debug Info</title>");
        out.println("<style>");
        out.println("body{font-family:Arial;padding:20px;background:#f5f5f5;}");
        out.println(".container{max-width:1200px;margin:0 auto;}");
        out.println("h1{color:#1a73e8;}");
        out.println("h2{color:#333;border-bottom:2px solid #1a73e8;padding-bottom:5px;}");
        out.println("table{border-collapse:collapse;width:100%;margin-bottom:20px;background:white;}");
        out.println("th{background:#1a73e8;color:white;padding:10px;}");
        out.println("td{border:1px solid #ddd;padding:8px;}");
        out.println("tr:nth-child(even){background:#f9f9f9;}");
        out.println(".success{color:green;font-weight:bold;}");
        out.println(".error{color:red;font-weight:bold;}");
        out.println(".info{background:#e3f2fd;padding:10px;border-radius:5px;margin:10px 0;}");
        out.println("</style>");
        out.println("</head><body>");
        out.println("<div class='container'>");
        
        out.println("<h1>🔍 IHVS System Debug Information</h1>");
        
        // Test Database Connection
        out.println("<h2>Database Connection Test</h2>");
        try {
            Connection conn = DBConnection.getConnection();
            if (conn != null && !conn.isClosed()) {
                out.println("<p class='success'>✅ Database connection successful!</p>");
                out.println("<p>Database: " + conn.getMetaData().getURL() + "</p>");
                out.println("<p>Driver: " + conn.getMetaData().getDriverName() + "</p>");
                conn.close();
            }
        } catch (Exception e) {
            out.println("<p class='error'>❌ Database connection failed: " + e.getMessage() + "</p>");
        }
        
        // Current Session Info
        out.println("<h2>Current Session</h2>");
        HttpSession session = req.getSession(false);
        User currentUser = session != null ? (User) session.getAttribute("user") : null;
        
        if (currentUser != null) {
            out.println("<div class='info'>");
            out.println("<p><strong>User ID:</strong> " + currentUser.getUserId() + "</p>");
            out.println("<p><strong>Username:</strong> " + currentUser.getUsername() + "</p>");
            out.println("<p><strong>Full Name:</strong> " + currentUser.getFullName() + "</p>");
            out.println("<p><strong>Email:</strong> " + currentUser.getEmail() + "</p>");
            out.println("<p><strong>Role:</strong> " + currentUser.getRole() + "</p>");
            out.println("</div>");
        } else {
            out.println("<p class='error'>❌ No user logged in</p>");
        }
        
        // All Users
        out.println("<h2>All Users in System</h2>");
        try {
            UserDAO userDAO = new UserDAO();
            List<User> users = userDAO.getAllUsers();
            
            out.println("<table>");
            out.println("<tr><th>ID</th><th>Username</th><th>Name</th><th>Email</th><th>Role</th><th>Phone</th></tr>");
            for (User u : users) {
                out.println("<tr>");
                out.println("<td>" + u.getUserId() + "</td>");
                out.println("<td>" + u.getUsername() + "</td>");
                out.println("<td>" + u.getFullName() + "</td>");
                out.println("<td>" + u.getEmail() + "</td>");
                out.println("<td><strong>" + u.getRole().toUpperCase() + "</strong></td>");
                out.println("<td>" + (u.getPhone() != null ? u.getPhone() : "-") + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total users: " + users.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading users: " + e.getMessage() + "</p>");
        }
        
        // All Patients
        out.println("<h2>All Patients</h2>");
        try {
            PatientDAO patientDAO = new PatientDAO();
            List<Patient> patients = patientDAO.getAllPatients();
            
            out.println("<table>");
            out.println("<tr><th>Patient ID</th><th>User ID</th><th>Name</th><th>Medical Aid</th><th>Status</th><th>PRI</th></tr>");
            for (Patient p : patients) {
                out.println("<tr>");
                out.println("<td>" + p.getPatientId() + "</td>");
                out.println("<td>" + p.getUserId() + "</td>");
                out.println("<td>" + p.getFullName() + "</td>");
                out.println("<td>" + (p.getMedicalAidProvider() != null ? p.getMedicalAidProvider() : "-") + "</td>");
                out.println("<td>" + p.getMembershipStatus() + "</td>");
                out.println("<td>" + p.getReliabilityScore() + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total patients: " + patients.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading patients: " + e.getMessage() + "</p>");
        }
        
        // All Doctors
        out.println("<h2>All Doctors</h2>");
        try {
            DoctorDAO doctorDAO = new DoctorDAO();
            List<Doctor> doctors = doctorDAO.getAllDoctors();
            
            out.println("<table>");
            out.println("<tr><th>Doctor ID</th><th>User ID</th><th>Name</th><th>Specialization</th><th>Fee</th><th>Available</th></tr>");
            for (Doctor d : doctors) {
                out.println("<tr>");
                out.println("<td>" + d.getDoctorId() + "</td>");
                out.println("<td>" + d.getUserId() + "</td>");
                out.println("<td>" + d.getFullName() + "</td>");
                out.println("<td>" + d.getSpecialization() + "</td>");
                out.println("<td>R" + d.getConsultationFee() + "</td>");
                out.println("<td>" + (d.isAvailable() ? "✅" : "❌") + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total doctors: " + doctors.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading doctors: " + e.getMessage() + "</p>");
        }
        
        // All Medical Aid Providers
        out.println("<h2>Medical Aid Providers</h2>");
        try {
            MedicalAidDAO medDAO = new MedicalAidDAO();
            List<MedicalAidProvider> providers = medDAO.getAllProviders();
            
            out.println("<table>");
            out.println("<tr><th>Provider ID</th><th>User ID</th><th>Provider Name</th><th>Email</th><th>Phone</th><th>Active</th></tr>");
            for (MedicalAidProvider p : providers) {
                out.println("<tr>");
                out.println("<td>" + p.getProviderId() + "</td>");
                out.println("<td>" + p.getUserId() + "</td>");
                out.println("<td>" + p.getProviderName() + "</td>");
                out.println("<td>" + p.getEmail() + "</td>");
                out.println("<td>" + p.getPhone() + "</td>");
                out.println("<td>" + (p.isActive() ? "✅" : "❌") + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total providers: " + providers.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading providers: " + e.getMessage() + "</p>");
        }
        
        // All Appointments
        out.println("<h2>All Appointments</h2>");
        try {
            AppointmentDAO apptDAO = new AppointmentDAO();
            List<Appointment> appointments = apptDAO.getAllAppointments();
            
            out.println("<table>");
            out.println("<tr><th>Appt ID</th><th>Date</th><th>Time</th><th>Patient</th><th>Doctor</th><th>Status</th><th>Validation</th></tr>");
            for (Appointment a : appointments) {
                out.println("<tr>");
                out.println("<td>" + a.getAppointmentId() + "</td>");
                out.println("<td>" + a.getAppointmentDate() + "</td>");
                out.println("<td>" + a.getAppointmentTime() + "</td>");
                out.println("<td>" + (a.getPatientName() != null ? a.getPatientName() : "ID: " + a.getPatientId()) + "</td>");
                out.println("<td>" + (a.getDoctorName() != null ? a.getDoctorName() : "ID: " + a.getDoctorId()) + "</td>");
                out.println("<td>" + a.getStatus() + "</td>");
                out.println("<td>" + a.getValidationStatus() + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total appointments: " + appointments.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading appointments: " + e.getMessage() + "</p>");
        }
        
        // Pending Validations
        out.println("<h2>Pending Validations</h2>");
        try {
            AppointmentDAO apptDAO = new AppointmentDAO();
            List<Appointment> pending = apptDAO.getPendingValidations();
            
            out.println("<table>");
            out.println("<tr><th>Appt ID</th><th>Patient</th><th>Doctor</th><th>Med Aid</th></tr>");
            for (Appointment a : pending) {
                out.println("<tr>");
                out.println("<td>" + a.getAppointmentId() + "</td>");
                out.println("<td>" + a.getPatientName() + "</td>");
                out.println("<td>" + a.getDoctorName() + "</td>");
                out.println("<td>" + (a.getMedicalAidProvider() != null ? a.getMedicalAidProvider() : "Not set") + "</td>");
                out.println("</tr>");
            }
            out.println("</table>");
            out.println("<p>Total pending: " + pending.size() + "</p>");
        } catch (Exception e) {
            out.println("<p class='error'>Error loading pending validations: " + e.getMessage() + "</p>");
        }
        
        // Quick Links
        out.println("<h2>Quick Links</h2>");
        out.println("<div class='info'>");
        out.println("<ul>");
        out.println("<li><a href='" + req.getContextPath() + "/login.jsp'>Login Page</a></li>");
        out.println("<li><a href='" + req.getContextPath() + "/register.jsp'>Register Page</a></li>");
        out.println("<li><a href='" + req.getContextPath() + "/admin/dashboard.jsp'>Admin Dashboard</a></li>");
        out.println("<li><a href='" + req.getContextPath() + "/medicalaid/dashboard.jsp'>Medical Aid Dashboard</a></li>");
        out.println("<li><a href='" + req.getContextPath() + "/patient/dashboard.jsp'>Patient Dashboard</a></li>");
        out.println("<li><a href='" + req.getContextPath() + "/doctor/dashboard.jsp'>Doctor Dashboard</a></li>");
        out.println("</ul>");
        out.println("</div>");
        
        out.println("</div></body></html>");
    }
}