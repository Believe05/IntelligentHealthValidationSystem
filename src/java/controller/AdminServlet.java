package controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

// Add these imports for PDF export
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.Font;
import com.itextpdf.text.FontFactory;
import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Element;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfWriter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.*;
import model.*;
import util.AuditLogger;

@WebServlet("/AdminServlet")
public class AdminServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final PatientDAO patientDAO = new PatientDAO();
    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final AuditLogDAO auditLogDAO = new AuditLogDAO();
    private final DoctorDAO doctorDAO = new DoctorDAO();
    private final MedicalAidDAO medicalAidDAO = new MedicalAidDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User admin = requireAdmin(req, res);
        if (admin == null) return;

        String action = req.getParameter("action");
        String contextPath = req.getContextPath();

        // ==================== USER MANAGEMENT ACTIONS ====================

        if ("deleteUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            String permanent = req.getParameter("permanent");
            boolean ok = false;

            if (userId != -1) {
                if ("true".equals(permanent)) {
                    ok = deleteUserCompletely(userId);
                    if (ok) {
                        AuditLogger.log(admin.getUserId(), "DELETE_USER_PERMANENT",
                                "Permanently deleted user ID: " + userId,
                                req.getRemoteAddr());
                    }
                    res.sendRedirect(contextPath + "/admin/users.jsp?" +
                            (ok ? "success=User+permanently+deleted." : "error=Delete+failed."));
                } else {
                    ok = userDAO.deactivateUser(userId);
                    AuditLogger.log(admin.getUserId(), "DEACTIVATE_USER",
                            "Deactivated user ID: " + userId,
                            req.getRemoteAddr());
                    res.sendRedirect(contextPath + "/admin/users.jsp?" +
                            (ok ? "success=User+deactivated." : "error=Deactivate+failed."));
                }
            } else {
                res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+user+ID.");
            }
            return;
        }

        if ("activateUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            boolean ok = false;

            if (userId != -1) {
                ok = userDAO.activateUser(userId);
                AuditLogger.log(admin.getUserId(), "ACTIVATE_USER",
                        "Activated user ID: " + userId,
                        req.getRemoteAddr());
            }

            res.sendRedirect(contextPath + "/admin/users.jsp?" +
                    (ok ? "success=User+activated." : "error=Activate+failed."));
            return;
        }

        if ("validatePatient".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);

            if (userId != -1) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    req.setAttribute("patientToValidate", patient);
                    req.getRequestDispatcher("/admin/validatePatient.jsp").forward(req, res);
                    return;
                } else {
                    res.sendRedirect(contextPath + "/admin/users.jsp?error=Patient+not+found.");
                    return;
                }
            }
            res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+patient+ID.");
            return;
        }

        if ("updateMedicalAid".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            String provider = req.getParameter("provider");
            String memberNumber = req.getParameter("memberNumber");

            boolean ok = false;
            if (userId != -1 && provider != null && memberNumber != null) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    ok = patientDAO.updateMedicalAid(patient.getPatientId(), provider, memberNumber);
                    if (ok) {
                        patientDAO.recalculatePRI(patient.getPatientId());
                        
                        List<Appointment> pendingApps = appointmentDAO.getPendingValidations();
                        
                        List<Appointment> patientPendingApps = pendingApps.stream()
                                .filter(apt -> apt.getPatientId() == patient.getPatientId())
                                .collect(Collectors.toList());
                        
                        if (!patientPendingApps.isEmpty()) {
                            List<Integer> patientIds = patientPendingApps.stream()
                                    .map(Appointment::getPatientId)
                                    .distinct()
                                    .collect(Collectors.toList());
                            
                            Map<Integer, Boolean> validationMap = medicalAidDAO.batchValidateMedicalAid(patientIds);
                            
                            for (Appointment apt : patientPendingApps) {
                                boolean isValid = validationMap.getOrDefault(apt.getPatientId(), false);
                                String newStatus = isValid ? "approved" : "rejected";
                                appointmentDAO.updateValidationStatus(apt.getAppointmentId(), newStatus);
                            }
                        }
                    }
                }
            }

            AuditLogger.log(admin.getUserId(), "UPDATE_MEDICAL_AID",
                    "Updated medical aid for user ID: " + userId + " Provider: " + provider,
                    req.getRemoteAddr());

            res.sendRedirect(contextPath + "/admin/users.jsp?" +
                    (ok ? "success=Patient+medical+aid+updated." : "error=Update+failed."));
            return;
        }

        // ==================== MEDICAL AID PROVIDER MANAGEMENT ====================

        if ("createProvider".equals(action)) {
            String providerName = req.getParameter("providerName");
            String contactPerson = req.getParameter("contactPerson");
            String email = req.getParameter("email");
            String phone = req.getParameter("phone");
            
            if (providerName == null || providerName.trim().isEmpty()) {
                res.sendRedirect(contextPath + "/admin/providers.jsp?error=Provider+name+is+required.");
                return;
            }
            
            MedicalAidProvider provider = new MedicalAidProvider();
            provider.setProviderName(providerName.trim());
            provider.setContactPerson(contactPerson != null ? contactPerson.trim() : null);
            provider.setEmail(email != null ? email.trim() : null);
            provider.setPhone(phone != null ? phone.trim() : null);
            provider.setActive(true);
            
            boolean ok = medicalAidDAO.createMedicalAidProvider(provider);
            
            AuditLogger.log(admin.getUserId(), "CREATE_MEDICAL_AID_PROVIDER",
                    "Created provider: " + providerName, req.getRemoteAddr());
            
            res.sendRedirect(contextPath + "/admin/providers.jsp?" +
                    (ok ? "success=Provider+created+successfully." : "error=Create+failed."));
            return;
        }

        if ("updateProvider".equals(action)) {
            int providerId = parseInt(req.getParameter("providerId"), -1);
            String providerName = req.getParameter("providerName");
            String contactPerson = req.getParameter("contactPerson");
            String email = req.getParameter("email");
            String phone = req.getParameter("phone");
            boolean isActive = "on".equals(req.getParameter("isActive"));
            
            if (providerId == -1 || providerName == null || providerName.trim().isEmpty()) {
                res.sendRedirect(contextPath + "/admin/providers.jsp?error=Invalid+provider+data.");
                return;
            }
            
            MedicalAidProvider provider = new MedicalAidProvider();
            provider.setProviderId(providerId);
            provider.setProviderName(providerName.trim());
            provider.setContactPerson(contactPerson != null ? contactPerson.trim() : null);
            provider.setEmail(email != null ? email.trim() : null);
            provider.setPhone(phone != null ? phone.trim() : null);
            provider.setActive(isActive);
            
            boolean ok = medicalAidDAO.updateMedicalAidProvider(provider);
            
            AuditLogger.log(admin.getUserId(), "UPDATE_MEDICAL_AID_PROVIDER",
                    "Updated provider ID: " + providerId, req.getRemoteAddr());
            
            res.sendRedirect(contextPath + "/admin/providers.jsp?" +
                    (ok ? "success=Provider+updated." : "error=Update+failed."));
            return;
        }

        if ("deleteProvider".equals(action)) {
            int providerId = parseInt(req.getParameter("providerId"), -1);
            
            if (providerId == -1) {
                res.sendRedirect(contextPath + "/admin/providers.jsp?error=Invalid+provider+ID.");
                return;
            }
            
            boolean ok = medicalAidDAO.deleteMedicalAidProvider(providerId);
            
            AuditLogger.log(admin.getUserId(), "DELETE_MEDICAL_AID_PROVIDER",
                    "Deleted provider ID: " + providerId, req.getRemoteAddr());
            
            res.sendRedirect(contextPath + "/admin/providers.jsp?" +
                    (ok ? "success=Provider+deleted." : "error=Cannot+delete+-+provider+has+associated+patients."));
            return;
        }

        // ==================== AUDIT LOGS ====================

        if ("viewLogs".equals(action)) {
            int limit = parseInt(req.getParameter("limit"), 100);
            List<AuditLog> logs = auditLogDAO.getRecentLogs(limit);
            req.setAttribute("auditLogs", logs);
            req.getRequestDispatcher("/admin/auditLogs.jsp").forward(req, res);
            return;
        }

        // ==================== EXPORT CSV ====================

        if ("exportAppointments".equals(action)) {
            exportAppointmentsToCSV(req, res, admin);
            return;
        }

        if ("exportUsers".equals(action)) {
            exportUsersToCSV(req, res, admin);
            return;
        }
        
        // ==================== EXPORT PATIENT RELIABILITY CSV ====================
        
        if ("exportPatientReliability".equals(action)) {
            String format = req.getParameter("format");
            if ("pdf".equals(format)) {
                exportPatientReliabilityToPDF(req, res, admin);
            } else {
                exportPatientReliabilityToCSV(req, res, admin);
            }
            return;
        }

        // ==================== PDF EXPORT ACTIONS ====================

        if ("exportAppointmentsPDF".equals(action)) {
            exportAppointmentsToPDF(req, res, admin);
            return;
        }

        if ("exportUsersPDF".equals(action)) {
            exportUsersToPDF(req, res, admin);
            return;
        }

        if ("exportDoctorPerformancePDF".equals(action)) {
            exportDoctorPerformanceToPDF(req, res, admin);
            return;
        }

        if ("exportMedicalAidUtilizationPDF".equals(action)) {
            exportMedicalAidUtilizationToPDF(req, res, admin);
            return;
        }

        // ==================== REPORTS ====================
        
        if ("doctorPerformanceReport".equals(action)) {
            showDoctorPerformanceReport(req, res, admin);
            return;
        }
        
        if ("medicalAidUtilizationReport".equals(action)) {
            showMedicalAidUtilizationReport(req, res, admin);
            return;
        }
        
        if ("patientReliabilityReport".equals(action)) {
            showPatientReliabilityReport(req, res, admin);
            return;
        }

        // ==================== DASHBOARD (DEFAULT) ====================

        try {
            int totalUsers = userDAO.getTotalUsers();
            int totalPatients = userDAO.countByRole("patient");
            int totalDoctors = userDAO.countByRole("doctor");
            int totalMedicalAid = userDAO.countByRole("medicalaid");

            int totalAppointments = appointmentDAO.countTotal();
            int pendingAppointments = appointmentDAO.countByStatus("pending");
            int confirmedAppointments = appointmentDAO.countByStatus("confirmed");
            int completedAppointments = appointmentDAO.countByStatus("completed");
            int cancelledAppointments = appointmentDAO.countByStatus("cancelled");
            int noShowAppointments = appointmentDAO.countByStatus("no-show");
            int rescheduledAppointments = appointmentDAO.countByStatus("rescheduled");

            String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
            int todayAppointments = appointmentDAO.countByDate(today);

            int totalValidations = appointmentDAO.countTotal();
            int approvedValidations = appointmentDAO.countByStatus("completed") +
                    appointmentDAO.countByStatus("confirmed");
            int validationRate = totalValidations > 0 ? (approvedValidations * 100 / totalValidations) : 0;

            List<Patient> highRiskPatients = patientDAO.getHighRiskPatients();

            List<Appointment> recentAppointments = appointmentDAO.getAllAppointments();
            if (recentAppointments != null && recentAppointments.size() > 10) {
                recentAppointments = recentAppointments.subList(0, 10);
            }
            
            List<DoctorPerformance> doctorPerformance = doctorDAO.getDoctorPerformance();
            List<MedicalAidUtilization> medAidUtilization = medicalAidDAO.getUtilizationStats();

            req.setAttribute("totalUsers", totalUsers);
            req.setAttribute("totalPatients", totalPatients);
            req.setAttribute("totalDoctors", totalDoctors);
            req.setAttribute("totalMedicalAid", totalMedicalAid);
            req.setAttribute("totalAppointments", totalAppointments);
            req.setAttribute("pendingAppointments", pendingAppointments);
            req.setAttribute("confirmedAppointments", confirmedAppointments);
            req.setAttribute("completedAppointments", completedAppointments);
            req.setAttribute("cancelledAppointments", cancelledAppointments);
            req.setAttribute("noShowAppointments", noShowAppointments);
            req.setAttribute("rescheduledAppointments", rescheduledAppointments);
            req.setAttribute("todayAppointments", todayAppointments);
            req.setAttribute("validationRate", validationRate);
            req.setAttribute("highRiskPatients", highRiskPatients);
            req.setAttribute("recentAppointments", recentAppointments);
            req.setAttribute("doctorPerformance", doctorPerformance);
            req.setAttribute("medAidUtilization", medAidUtilization);

            req.getRequestDispatcher("/admin/dashboard.jsp").forward(req, res);

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect(contextPath + "/admin/dashboard.jsp?error=Error+loading+dashboard%3A+" + e.getMessage().replace(" ", "+"));
        }
    }
    
    // ==================== REPORT DISPLAY METHODS ====================
    
    private void showDoctorPerformanceReport(HttpServletRequest req, HttpServletResponse res, User admin)
            throws ServletException, IOException {
        List<DoctorPerformance> performance = doctorDAO.getDoctorPerformance();
        String doctorFilter = req.getParameter("doctorId");
        
        if (doctorFilter != null && !doctorFilter.isEmpty()) {
            int docId = Integer.parseInt(doctorFilter);
            performance = performance.stream()
                .filter(p -> p.getDoctorId() == docId)
                .collect(Collectors.toList());
        }
        
        req.setAttribute("doctorPerformance", performance);
        req.setAttribute("doctors", doctorDAO.getAllDoctors());
        req.setAttribute("reportTitle", "Doctor Performance Report");
        req.getRequestDispatcher("/admin/reports/doctorPerformance.jsp").forward(req, res);
    }
    
    private void showMedicalAidUtilizationReport(HttpServletRequest req, HttpServletResponse res, User admin)
            throws ServletException, IOException {
        List<MedicalAidUtilization> utilization = medicalAidDAO.getUtilizationStats();
        req.setAttribute("utilization", utilization);
        req.setAttribute("reportTitle", "Medical Aid Utilization Report");
        req.getRequestDispatcher("/admin/reports/medicalAidUtilization.jsp").forward(req, res);
    }
    
    private void showPatientReliabilityReport(HttpServletRequest req, HttpServletResponse res, User admin)
            throws ServletException, IOException {
        List<Patient> patients = patientDAO.getAllPatients();
        patients.sort((p1, p2) -> Integer.compare(p1.getReliabilityScore(), p2.getReliabilityScore()));
        req.setAttribute("patients", patients);
        req.setAttribute("reportTitle", "Patient Reliability Report");
        req.getRequestDispatcher("/admin/reports/patientReliability.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User admin = requireAdmin(req, res);
        if (admin == null) return;

        String action = req.getParameter("action");
        String contextPath = req.getContextPath();

        if ("updateUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);

            if (userId != -1) {
                User user = userDAO.getUserById(userId);
                if (user != null) {
                    String fullName = req.getParameter("fullName");
                    String email = req.getParameter("email");
                    String phone = req.getParameter("phone");

                    user.setFullName(fullName);
                    user.setEmail(email);
                    user.setPhone(phone);

                    boolean ok = userDAO.updateUser(user);

                    AuditLogger.log(admin.getUserId(), "UPDATE_USER",
                            "Updated user ID: " + userId + " - " + user.getFullName(),
                            req.getRemoteAddr());

                    if (ok) {
                        res.sendRedirect(contextPath + "/admin/users.jsp?success=User+updated+successfully.");
                    } else {
                        res.sendRedirect(contextPath + "/admin/users.jsp?error=Update+failed.");
                    }
                } else {
                    res.sendRedirect(contextPath + "/admin/users.jsp?error=User+not+found.");
                }
            } else {
                res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+user+ID.");
            }
            return;
        }

        if ("createProvider".equals(action) || "updateProvider".equals(action)) {
            doGet(req, res);
            return;
        }

        res.sendRedirect(contextPath + "/admin/dashboard.jsp");
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private User requireAdmin(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || !"admin".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }

    private boolean deleteUserCompletely(int userId) {
        try {
            User user = userDAO.getUserById(userId);
            if (user == null) return false;
            
            if ("patient".equals(user.getRole())) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    int patientId = patient.getPatientId();
                    appointmentDAO.deleteAppointmentsByPatient(patientId);
                    patientDAO.deletePatient(patientId);
                }
            } else if ("doctor".equals(user.getRole())) {
                Doctor doctor = doctorDAO.getDoctorByUserId(userId);
                if (doctor != null) {
                    int doctorId = doctor.getDoctorId();
                    appointmentDAO.deleteAppointmentsByDoctor(doctorId);
                    doctorDAO.deleteDoctorSchedule(doctorId);
                    doctorDAO.deleteDoctor(doctorId);
                }
            }
            
            auditLogDAO.deleteLogsByUser(userId);
            return userDAO.deleteUserPermanently(userId);
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ==================== CSV EXPORT METHODS ====================

    private void exportAppointmentsToCSV(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {

        res.setContentType("text/csv");
        res.setHeader("Content-Disposition", "attachment; filename=\"appointments_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".csv\"");

        List<Appointment> appointments = appointmentDAO.getAllAppointments();

        StringBuilder csv = new StringBuilder();
        csv.append("Appointment ID,Patient Name,Doctor Name,Date,Time,Status,Validation Status,Notes\n");

        for (Appointment apt : appointments) {
            csv.append(apt.getAppointmentId()).append(",");
            csv.append(escapeCsv(apt.getPatientName())).append(",");
            csv.append(escapeCsv(apt.getDoctorName())).append(",");
            csv.append(apt.getAppointmentDate()).append(",");
            csv.append(apt.getAppointmentTime()).append(",");
            csv.append(apt.getStatus()).append(",");
            csv.append(apt.getValidationStatus()).append(",");
            csv.append(escapeCsv(apt.getNotes())).append("\n");
        }

        AuditLogger.log(admin.getUserId(), "EXPORT_APPOINTMENTS",
                "Exported " + appointments.size() + " appointments",
                req.getRemoteAddr());

        PrintWriter writer = res.getWriter();
        writer.write(csv.toString());
        writer.flush();
        writer.close();
    }

    private void exportUsersToCSV(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {

        res.setContentType("text/csv");
        res.setHeader("Content-Disposition", "attachment; filename=\"users_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".csv\"");

        List<User> users = userDAO.getAllUsers();

        StringBuilder csv = new StringBuilder();
        csv.append("User ID,Username,Full Name,Email,Phone,Role,Status,Created Date\n");

        for (User u : users) {
            csv.append(u.getUserId()).append(",");
            csv.append(escapeCsv(u.getUsername())).append(",");
            csv.append(escapeCsv(u.getFullName())).append(",");
            csv.append(escapeCsv(u.getEmail())).append(",");
            csv.append(escapeCsv(u.getPhone())).append(",");
            csv.append(u.getRole()).append(",");
            csv.append(u.isActive() ? "Active" : "Inactive").append(",");
            csv.append(u.getCreatedAt()).append("\n");
        }

        AuditLogger.log(admin.getUserId(), "EXPORT_USERS",
                "Exported " + users.size() + " users",
                req.getRemoteAddr());

        PrintWriter writer = res.getWriter();
        writer.write(csv.toString());
        writer.flush();
        writer.close();
    }
    
    private void exportPatientReliabilityToCSV(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {

        res.setContentType("text/csv");
        res.setHeader("Content-Disposition", "attachment; filename=\"patient_reliability_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".csv\"");

        List<Patient> patients = patientDAO.getAllPatients();
        patients.sort((p1, p2) -> Integer.compare(p1.getReliabilityScore(), p2.getReliabilityScore()));

        StringBuilder csv = new StringBuilder();
        csv.append("Patient Name,Email,Phone,Medical Aid Provider,Member Number,Total Appointments,Completed,No-Shows,Cancelled,PRI Score,Risk Level\n");

        for (Patient p : patients) {
            int score = p.getReliabilityScore();
            String riskLevel = score < 60 ? "HIGH RISK" : (score < 80 ? "MEDIUM RISK" : "LOW RISK");
            
            csv.append(escapeCsv(p.getFullName())).append(",");
            csv.append(escapeCsv(p.getEmail())).append(",");
            csv.append(escapeCsv(p.getPhone())).append(",");
            csv.append(escapeCsv(p.getMedicalAidProvider())).append(",");
            csv.append(escapeCsv(p.getMedicalAidNumber())).append(",");
            csv.append(p.getTotalAppointments()).append(",");
            csv.append(p.getCompletedCount()).append(",");
            csv.append(p.getNoShowCount()).append(",");
            csv.append(p.getCancellationCount()).append(",");
            csv.append(score).append(",");
            csv.append(riskLevel).append("\n");
        }

        AuditLogger.log(admin.getUserId(), "EXPORT_PATIENT_RELIABILITY",
                "Exported " + patients.size() + " patients",
                req.getRemoteAddr());

        PrintWriter writer = res.getWriter();
        writer.write(csv.toString());
        writer.flush();
        writer.close();
    }

    // ==================== PDF EXPORT METHODS ====================

    private void exportAppointmentsToPDF(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {
        
        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=\"appointments_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".pdf\"");
        
        List<Appointment> appointments = appointmentDAO.getAllAppointments();
        
        try {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, res.getOutputStream());
            document.open();
            
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("IHVS Appointments Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph("Generated: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())));
            document.add(new Paragraph("Total Appointments: " + appointments.size()));
            document.add(new Paragraph(" "));
            
            PdfPTable table = new PdfPTable(8);
            table.setWidthPercentage(100);
            table.setSpacingBefore(10f);
            table.setSpacingAfter(10f);
            
            String[] headers = {"ID", "Date", "Time", "Patient", "Doctor", "Status", "Validation", "Medical Aid"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
                cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
                cell.setPadding(5);
                table.addCell(cell);
            }
            
            for (Appointment apt : appointments) {
                table.addCell(String.valueOf(apt.getAppointmentId()));
                table.addCell(apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "-");
                table.addCell(apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "-");
                table.addCell(apt.getPatientName() != null ? apt.getPatientName() : "-");
                table.addCell(apt.getDoctorName() != null ? apt.getDoctorName() : "-");
                table.addCell(apt.getStatus() != null ? apt.getStatus() : "-");
                table.addCell(apt.getValidationStatus() != null ? apt.getValidationStatus() : "-");
                table.addCell(apt.getMedicalAidProvider() != null ? apt.getMedicalAidProvider() : "-");
            }
            
            document.add(table);
            document.close();
            
            AuditLogger.log(admin.getUserId(), "EXPORT_APPOINTMENTS_PDF",
                    "Exported " + appointments.size() + " appointments to PDF",
                    req.getRemoteAddr());
                    
        } catch (DocumentException e) {
            e.printStackTrace();
            res.sendError(500, "PDF generation failed: " + e.getMessage());
        }
    }

    private void exportUsersToPDF(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {
        
        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=\"users_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".pdf\"");
        
        List<User> users = userDAO.getAllUsers();
        
        try {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, res.getOutputStream());
            document.open();
            
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("IHVS Users Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph("Generated: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())));
            document.add(new Paragraph("Total Users: " + users.size()));
            document.add(new Paragraph(" "));
            
            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            
            String[] headers = {"ID", "Username", "Full Name", "Email", "Phone", "Role", "Status"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
                cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
                cell.setPadding(5);
                table.addCell(cell);
            }
            
            for (User u : users) {
                table.addCell(String.valueOf(u.getUserId()));
                table.addCell(u.getUsername());
                table.addCell(u.getFullName());
                table.addCell(u.getEmail());
                table.addCell(u.getPhone() != null ? u.getPhone() : "-");
                table.addCell(u.getRole());
                table.addCell(u.isActive() ? "Active" : "Inactive");
            }
            
            document.add(table);
            document.close();
            
            AuditLogger.log(admin.getUserId(), "EXPORT_USERS_PDF",
                    "Exported " + users.size() + " users to PDF",
                    req.getRemoteAddr());
                    
        } catch (DocumentException e) {
            e.printStackTrace();
            res.sendError(500, "PDF generation failed: " + e.getMessage());
        }
    }

    private void exportPatientReliabilityToPDF(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {
        
        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=\"patient_reliability_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".pdf\"");
        
        List<Patient> patients = patientDAO.getAllPatients();
        patients.sort((p1, p2) -> Integer.compare(p1.getReliabilityScore(), p2.getReliabilityScore()));
        
        try {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, res.getOutputStream());
            document.open();
            
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("IHVS Patient Reliability Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph("Generated: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())));
            document.add(new Paragraph("Total Patients: " + patients.size()));
            document.add(new Paragraph(" "));
            
            PdfPTable table = new PdfPTable(10);
            table.setWidthPercentage(100);
            
            String[] headers = {"Patient Name", "Email", "Phone", "Medical Aid", "Total Appts", "Completed", "No-Shows", "Cancelled", "PRI Score", "Risk Level"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
                cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
                cell.setPadding(5);
                table.addCell(cell);
            }
            
            for (Patient p : patients) {
                int score = p.getReliabilityScore();
                String riskLevel = score < 60 ? "HIGH RISK" : (score < 80 ? "MEDIUM RISK" : "LOW RISK");
                
                table.addCell(p.getFullName() != null ? p.getFullName() : "-");
                table.addCell(p.getEmail() != null ? p.getEmail() : "-");
                table.addCell(p.getPhone() != null ? p.getPhone() : "-");
                table.addCell(p.getMedicalAidProvider() != null ? p.getMedicalAidProvider() : "-");
                table.addCell(String.valueOf(p.getTotalAppointments()));
                table.addCell(String.valueOf(p.getCompletedCount()));
                table.addCell(String.valueOf(p.getNoShowCount()));
                table.addCell(String.valueOf(p.getCancellationCount()));
                table.addCell(String.valueOf(score));
                table.addCell(riskLevel);
            }
            
            document.add(table);
            document.close();
            
            AuditLogger.log(admin.getUserId(), "EXPORT_PATIENT_RELIABILITY_PDF",
                    "Exported " + patients.size() + " patients to PDF",
                    req.getRemoteAddr());
                    
        } catch (DocumentException e) {
            e.printStackTrace();
            res.sendError(500, "PDF generation failed: " + e.getMessage());
        }
    }

    private void exportDoctorPerformanceToPDF(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {
        
        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=\"doctor_performance_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".pdf\"");
        
        List<DoctorPerformance> performance = doctorDAO.getDoctorPerformance();
        
        try {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, res.getOutputStream());
            document.open();
            
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("IHVS Doctor Performance Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph("Generated: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())));
            document.add(new Paragraph(" "));
            
            PdfPTable table = new PdfPTable(8);
            table.setWidthPercentage(100);
            
            String[] headers = {"Doctor", "Specialization", "Total Appts", "Completed", "Cancelled", "No-Shows", "Completion Rate", "Rating"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
                cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
                cell.setPadding(5);
                table.addCell(cell);
            }
            
            for (DoctorPerformance dp : performance) {
                double rate = dp.getCompletionRate();
                String rating = rate >= 85 ? "Excellent" : (rate >= 70 ? "Good" : (rate >= 50 ? "Average" : "Poor"));
                
                table.addCell("Dr. " + dp.getDoctorName());
                table.addCell(dp.getSpecialization());
                table.addCell(String.valueOf(dp.getTotalAppointments()));
                table.addCell(String.valueOf(dp.getCompletedAppointments()));
                table.addCell(String.valueOf(dp.getCancelledAppointments()));
                table.addCell(String.valueOf(dp.getNoShowCount()));
                table.addCell(String.format("%.1f%%", rate));
                table.addCell(rating);
            }
            
            document.add(table);
            document.close();
            
            AuditLogger.log(admin.getUserId(), "EXPORT_DOCTOR_PERFORMANCE_PDF",
                    "Exported doctor performance to PDF",
                    req.getRemoteAddr());
                    
        } catch (DocumentException e) {
            e.printStackTrace();
            res.sendError(500, "PDF generation failed: " + e.getMessage());
        }
    }

    private void exportMedicalAidUtilizationToPDF(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {
        
        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=\"medical_aid_utilization_" +
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".pdf\"");
        
        List<MedicalAidUtilization> utilization = medicalAidDAO.getUtilizationStats();
        
        try {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, res.getOutputStream());
            document.open();
            
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("IHVS Medical Aid Utilization Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph("Generated: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())));
            document.add(new Paragraph(" "));
            
            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            
            String[] headers = {"Provider", "Patients", "Appointments", "Approved", "Rejected", "Pending", "Approval Rate"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
                cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
                cell.setPadding(5);
                table.addCell(cell);
            }
            
            for (MedicalAidUtilization mu : utilization) {
                double approvalRate = mu.getAppointmentCount() > 0 ? 
                    (mu.getApprovedCount() * 100.0 / mu.getAppointmentCount()) : 0;
                
                table.addCell(mu.getProviderName());
                table.addCell(String.valueOf(mu.getPatientCount()));
                table.addCell(String.valueOf(mu.getAppointmentCount()));
                table.addCell(String.valueOf(mu.getApprovedCount()));
                table.addCell(String.valueOf(mu.getRejectedCount()));
                table.addCell(String.valueOf(mu.getPendingCount()));
                table.addCell(String.format("%.1f%%", approvalRate));
            }
            
            document.add(table);
            document.close();
            
            AuditLogger.log(admin.getUserId(), "EXPORT_MEDICAL_AID_UTILIZATION_PDF",
                    "Exported medical aid utilization to PDF",
                    req.getRemoteAddr());
                    
        } catch (DocumentException e) {
            e.printStackTrace();
            res.sendError(500, "PDF generation failed: " + e.getMessage());
        }
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        return "\"" + value.replace("\"", "\"\"") + "\"";
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