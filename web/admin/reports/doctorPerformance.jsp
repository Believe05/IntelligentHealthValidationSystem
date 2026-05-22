<%@page import="java.util.List"%>
<%@page import="model.DoctorPerformance"%>
<%@page import="dao.DoctorDAO"%>
<%@page import="model.Doctor"%>
<%@page import="model.User"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    List<DoctorPerformance> performance = (List<DoctorPerformance>) request.getAttribute("doctorPerformance");
    List<Doctor> doctors = (List<Doctor>) request.getAttribute("doctors");
    
    // If no performance data, fetch directly
    if (performance == null) {
        DoctorDAO doctorDAO = new DoctorDAO();
        performance = doctorDAO.getDoctorPerformance();
    }
    if (doctors == null) {
        DoctorDAO doctorDAO = new DoctorDAO();
        doctors = doctorDAO.getAllDoctors();
    }
    
    String doctorFilter = request.getParameter("doctorId");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    
    // Set default date range to current month
    if (startDate == null || startDate.isEmpty()) {
        java.util.Calendar cal = java.util.Calendar.getInstance();
        cal.set(java.util.Calendar.DAY_OF_MONTH, 1);
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
        startDate = sdf.format(cal.getTime());
    }
    if (endDate == null || endDate.isEmpty()) {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
        endDate = sdf.format(new java.util.Date());
    }
    
    String firstName = admin.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Doctor Performance Report | IHVS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .report-header { margin-bottom: 24px; }
        .filter-bar { display: flex; gap: 16px; flex-wrap: wrap; align-items: flex-end; margin-bottom: 24px; padding: 16px; background: #f8fafc; border-radius: 12px; }
        .filter-group { display: flex; flex-direction: column; gap: 6px; }
        .filter-group label { font-size: 12px; font-weight: 600; color: #64748b; }
        .export-buttons { display: flex; gap: 12px; margin-top: 20px; }
        .chart-container { max-width: 600px; margin: 0 auto 30px; }
        .rating-excellent { color: #10b981; font-weight: bold; }
        .rating-good { color: #3b82f6; font-weight: bold; }
        .rating-average { color: #f59e0b; font-weight: bold; }
        .rating-poor { color: #ef4444; font-weight: bold; }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info"><div class="name"><%= admin.getFullName() %></div><div class="role">Admin</div></div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="report-header">
        <h1><i class="fas fa-chart-line"></i> Doctor Performance Report</h1>
        <p>Track doctor productivity, completion rates, and no-show statistics</p>
    </div>
    
    <!-- Filter Bar with Default Values -->
    <div class="filter-bar">
        <form method="get" action="${pageContext.request.contextPath}/AdminServlet" style="display: flex; gap: 16px; flex-wrap: wrap; width: 100%;">
            <input type="hidden" name="action" value="doctorPerformanceReport">
            
            <div class="filter-group">
                <label><i class="fas fa-user-md"></i> Doctor</label>
                <select name="doctorId" class="form-control" style="min-width: 180px;">
                    <option value="">All Doctors</option>
                    <% if (doctors != null) {
                        for (Doctor d : doctors) { %>
                            <option value="<%= d.getDoctorId() %>" <%= (doctorFilter != null && doctorFilter.equals(String.valueOf(d.getDoctorId()))) ? "selected" : "" %>>
                                Dr. <%= d.getFullName() %> - <%= d.getSpecialization() %>
                            </option>
                    <% } } %>
                </select>
            </div>
            
            <div class="filter-group">
                <label><i class="fas fa-calendar-alt"></i> From Date</label>
                <input type="date" name="startDate" class="form-control" value="<%= startDate %>">
            </div>
            
            <div class="filter-group">
                <label><i class="fas fa-calendar-alt"></i> To Date</label>
                <input type="date" name="endDate" class="form-control" value="<%= endDate %>">
            </div>
            
            <div class="filter-group">
                <label>&nbsp;</label>
                <button type="submit" class="btn btn-primary"><i class="fas fa-filter"></i> Apply Filter</button>
            </div>
        </form>
    </div>
    
    <!-- Chart -->
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-chart-bar"></i> Completion Rate Comparison</h3></div>
        <div class="card-body">
            <div class="chart-container">
                <canvas id="completionChart"></canvas>
            </div>
        </div>
    </div>
    
    <!-- Performance Table -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-table"></i> Doctor Performance Details</h3>
            <div class="export-buttons">
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportAppointments&format=csv" 
                   class="btn btn-outline btn-sm"><i class="fas fa-file-csv"></i> Export CSV</a>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportDoctorPerformancePDF" 
                   class="btn btn-outline btn-sm"><i class="fas fa-file-pdf"></i> Export PDF</a>
            </div>
        </div>
        <div class="table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Doctor</th>
                        <th>Specialization</th>
                        <th>Total Appts</th>
                        <th>Completed</th>
                        <th>Cancelled</th>
                        <th>No-Shows</th>
                        <th>Completion Rate</th>
                        <th>Rating</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (performance == null || performance.isEmpty()) { %>
                        <tr><td colspan="8" style="text-align:center; padding:40px;">No data available for selected filters</td></tr>
                    <% } else { 
                        for (DoctorPerformance dp : performance) { 
                            String ratingClass = "";
                            String ratingText = "";
                            double rate = dp.getCompletionRate();
                            if (rate >= 85) {
                                ratingClass = "rating-excellent";
                                ratingText = "Excellent";
                            } else if (rate >= 70) {
                                ratingClass = "rating-good";
                                ratingText = "Good";
                            } else if (rate >= 50) {
                                ratingClass = "rating-average";
                                ratingText = "Average";
                            } else {
                                ratingClass = "rating-poor";
                                ratingText = "Poor";
                            }
                    %>
                        <tr>
                            <td><strong>Dr. <%= dp.getDoctorName() %></strong></td>
                            <td><%= dp.getSpecialization() %></td>
                            <td><%= dp.getTotalAppointments() %></td>
                            <td><%= dp.getCompletedAppointments() %></td>
                            <td><%= dp.getCancelledAppointments() %></td>
                            <td><%= dp.getNoShowCount() %></td>
                            <td><strong><%= String.format("%.1f", dp.getCompletionRate()) %>%</strong></td>
                            <td class="<%= ratingClass %>"><%= ratingText %></td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Social Media Links -->
    <div class="social-links" style="text-align: center; margin-top: 30px; padding: 20px; border-top: 1px solid #e2e8f0;">
        <h4>Follow IHVS</h4>
        <a href="#" style="margin: 0 10px; color: #1877f2;"><i class="fab fa-facebook fa-2x"></i></a>
        <a href="#" style="margin: 0 10px; color: #1da1f2;"><i class="fab fa-twitter fa-2x"></i></a>
        <a href="#" style="margin: 0 10px; color: #0a66c2;"><i class="fab fa-linkedin fa-2x"></i></a>
        <a href="#" style="margin: 0 10px; color: #e4405f;"><i class="fab fa-instagram fa-2x"></i></a>
        <a href="#" style="margin: 0 10px; color: #ff0000;"><i class="fab fa-youtube fa-2x"></i></a>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>

<script>
    const doctorNames = [<% if (performance != null) { for (DoctorPerformance dp : performance) { %>"<%= dp.getDoctorName() %>",<% } } %>];
    const completionRates = [<% if (performance != null) { for (DoctorPerformance dp : performance) { %><%= dp.getCompletionRate() %>,<% } } %>];
    
    if (doctorNames.length > 0) {
        const ctx = document.getElementById('completionChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: doctorNames,
                datasets: [{
                    label: 'Completion Rate (%)',
                    data: completionRates,
                    backgroundColor: 'rgba(37, 99, 235, 0.7)',
                    borderColor: 'rgba(37, 99, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: { y: { beginAtZero: true, max: 100, title: { display: true, text: 'Completion Rate (%)' } } },
                plugins: { tooltip: { callbacks: { label: function(context) { return context.raw + '%'; } } } }
            }
        });
    }
</script>
</body>
</html>