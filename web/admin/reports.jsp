<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="dao.AdminDAO"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="model.User"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.*"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    AdminDAO adminDAO = new AdminDAO();
    AppointmentDAO appointmentDAO = new AppointmentDAO();
    
    String[] months = {"January", "February", "March", "April", "May", "June", 
                       "July", "August", "September", "October", "November", "December"};
    
    int selectedYear = Calendar.getInstance().get(Calendar.YEAR);
    int selectedMonth = Calendar.getInstance().get(Calendar.MONTH) + 1;
    
    if (request.getParameter("year") != null) {
        try { selectedYear = Integer.parseInt(request.getParameter("year")); } catch (NumberFormatException e) {}
    }
    if (request.getParameter("month") != null) {
        try { selectedMonth = Integer.parseInt(request.getParameter("month")); } catch (NumberFormatException e) {}
    }
    
    int[] monthlyStats = adminDAO.getMonthlyStats(selectedYear, selectedMonth);
    
    Map<String, Integer> monthlyTotals = new LinkedHashMap<>();
    Calendar cal = Calendar.getInstance();
    SimpleDateFormat monthFormat = new SimpleDateFormat("MMM yyyy");
    for (int i = 11; i >= 0; i--) {
        cal.set(Calendar.MONTH, Calendar.getInstance().get(Calendar.MONTH) - i);
        String monthKey = monthFormat.format(cal.getTime());
        int[] stats = adminDAO.getMonthlyStats(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1);
        int total = stats[0] + stats[1] + stats[2] + stats[3] + stats[4] + stats[5];
        monthlyTotals.put(monthKey, total);
    }
    
    int totalForMonth = monthlyStats[0] + monthlyStats[1] + monthlyStats[2] + monthlyStats[3] + monthlyStats[4] + monthlyStats[5];
    int completedOrConfirmed = monthlyStats[1] + monthlyStats[4];
    double successRate = totalForMonth > 0 ? (completedOrConfirmed * 100.0 / totalForMonth) : 0;
    double noShowRate = totalForMonth > 0 ? (monthlyStats[5] * 100.0 / totalForMonth) : 0;
    double cancellationRate = totalForMonth > 0 ? (monthlyStats[2] * 100.0 / totalForMonth) : 0;
    
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    List<model.Appointment> filteredAppointments = null;
    if (startDate != null && endDate != null && !startDate.isEmpty() && !endDate.isEmpty()) {
        filteredAppointments = adminDAO.getAppointmentsByDateRange(startDate, endDate);
    }
    
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="reports.jsp" class="nav-item active"><i class="fas fa-chart-line"></i> Reports</a>
            <a href="providers.jsp" class="nav-item"><i class="fas fa-hospital"></i> Providers</a>
        </div>
        <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Admin</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>System Reports</h1>
        <p>Analytics, trends, and operational metrics</p>
    </div>

    <!-- Report Navigation Cards -->
    <div class="quick-grid" style="margin-bottom: 30px;">
        <a href="${pageContext.request.contextPath}/AdminServlet?action=doctorPerformanceReport" class="quick-card">
            <i class="fas fa-user-md qc-icon"></i>
            <h4>Doctor Performance</h4>
            <p>Track completion rates and productivity</p>
        </a>
        <a href="${pageContext.request.contextPath}/AdminServlet?action=medicalAidUtilizationReport" class="quick-card">
            <i class="fas fa-shield-alt qc-icon"></i>
            <h4>Medical Aid Utilization</h4>
            <p>Provider usage and validation stats</p>
        </a>
        <a href="${pageContext.request.contextPath}/AdminServlet?action=patientReliabilityReport" class="quick-card">
            <i class="fas fa-star qc-icon"></i>
            <h4>Patient Reliability</h4>
            <p>PRI scores and risk analysis</p>
        </a>
    </div>

    <!-- Existing Reports (Monthly Stats, etc.) -->
    <div class="card" style="margin-bottom: 24px;">
        <div class="card-header"><h3><i class="fas fa-calendar-alt"></i> Monthly Statistics</h3></div>
        <div class="card-body">
            <form method="get" action="" class="filter-bar" style="display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 20px;">
                <div class="filter-group">
                    <label>Year</label>
                    <select name="year" class="form-control" style="width: 120px;">
                        <% for (int y = 2024; y <= 2026; y++) { %>
                            <option value="<%= y %>" <%= (selectedYear == y) ? "selected" : "" %>><%= y %></option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-group">
                    <label>Month</label>
                    <select name="month" class="form-control" style="width: 140px;">
                        <% for (int m = 1; m <= 12; m++) { %>
                            <option value="<%= m %>" <%= (selectedMonth == m) ? "selected" : "" %>><%= months[m-1] %></option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-group">
                    <label>&nbsp;</label>
                    <button type="submit" class="btn btn-primary">Apply Filter</button>
                </div>
            </form>
            
           <div class="kpi-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px;">
    <div class="kpi-card" style="text-align: center; background: #f8fafc; padding: 20px; border-radius: 12px;">
        <div class="kpi-value" style="font-size: 32px; font-weight: 700; color: #2563eb;"><%= totalForMonth %></div>
        <div class="kpi-label" style="font-size: 14px; color: #64748b;">Total Appointments</div>
    </div>
    <div class="kpi-card" style="text-align: center; background: #f8fafc; padding: 20px; border-radius: 12px;">
        <div class="kpi-value" style="font-size: 32px; font-weight: 700; color: #10b981;"><%= String.format("%.1f", successRate) %>%</div>
        <div class="kpi-label" style="font-size: 14px; color: #64748b;">Success Rate</div>
    </div>
    <div class="kpi-card" style="text-align: center; background: #f8fafc; padding: 20px; border-radius: 12px;">
        <div class="kpi-value" style="font-size: 32px; font-weight: 700; color: #ef4444;"><%= String.format("%.1f", noShowRate) %>%</div>
        <div class="kpi-label" style="font-size: 14px; color: #64748b;">No-Show Rate</div>
    </div>
    <div class="kpi-card" style="text-align: center; background: #f8fafc; padding: 20px; border-radius: 12px;">
        <div class="kpi-value" style="font-size: 32px; font-weight: 700; color: #f59e0b;"><%= String.format("%.1f", cancellationRate) %>%</div>
        <div class="kpi-label" style="font-size: 14px; color: #64748b;">Cancellation Rate</div>
    </div>
</div> 
        </div>
    </div>

    <!-- Export Section -->
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-download"></i> Export Data</h3></div>
        <div class="card-body">
            <div style="display: flex; gap: 16px; flex-wrap: wrap;">
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportAppointments" class="btn btn-primary"><i class="fas fa-file-csv"></i> Export Appointments (CSV)</a>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportAppointmentsPDF" class="btn btn-primary"><i class="fas fa-file-pdf"></i> Export Appointments (PDF)</a>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportUsers" class="btn btn-primary"><i class="fas fa-users"></i> Export Users (CSV)</a>
            </div>
        </div>
    </div>
    
    <!-- Social Media Links (Assessment 5) -->
    <div class="social-footer" style="text-align: center; margin-top: 40px; padding: 20px; border-top: 1px solid #e2e8f0;">
        <h4>Connect With IHVS</h4>
        <div style="display: flex; justify-content: center; gap: 20px; margin-top: 10px;">
            <a href="#" style="color: #1877f2; font-size: 24px;"><i class="fab fa-facebook"></i></a>
            <a href="#" style="color: #1da1f2; font-size: 24px;"><i class="fab fa-twitter"></i></a>
            <a href="#" style="color: #0a66c2; font-size: 24px;"><i class="fab fa-linkedin"></i></a>
            <a href="#" style="color: #e4405f; font-size: 24px;"><i class="fab fa-instagram"></i></a>
            <a href="#" style="color: #ff0000; font-size: 24px;"><i class="fab fa-youtube"></i></a>
        </div>
        <p style="margin-top: 15px; font-size: 12px; color: #64748b;">Follow us for updates on healthcare innovation</p>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>
</body>
</html>