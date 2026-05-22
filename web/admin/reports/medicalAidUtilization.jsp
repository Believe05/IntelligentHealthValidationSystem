<%@page import="java.util.List"%>
<%@page import="model.MedicalAidUtilization"%>
<%@page import="model.User"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    List<MedicalAidUtilization> utilization = (List<MedicalAidUtilization>) request.getAttribute("utilization");
    String firstName = admin.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Medical Aid Utilization Report | IHVS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item active"><i class="fas fa-chart-line"></i> Reports</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info"><div class="name"><%= admin.getFullName() %></div><div class="role">Admin</div></div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1><i class="fas fa-shield-alt"></i> Medical Aid Utilization Report</h1>
        <p>Track medical aid provider usage and validation statistics</p>
    </div>
    
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-table"></i> Provider Statistics</h3>
            <div>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportMedicalAidReportPDF" 
                   class="btn btn-outline btn-sm"><i class="fas fa-file-pdf"></i> Export PDF</a>
            </div>
        </div>
        <div class="table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Provider Name</th>
                        <th>Patients</th>
                        <th>Appointments</th>
                        <th>Approved</th>
                        <th>Rejected</th>
                        <th>Pending</th>
                        <th>Approval Rate</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (utilization == null || utilization.isEmpty()) { %>
                        <tr><td colspan="7" style="text-align:center; padding:40px;">No medical aid utilization data available</td></tr>
                    <% } else { 
                        for (MedicalAidUtilization mu : utilization) { 
                            double approvalRate = mu.getAppointmentCount() > 0 ? 
                                (mu.getApprovedCount() * 100.0 / mu.getAppointmentCount()) : 0;
                    %>
                        <tr>
                            <td><strong><%= mu.getProviderName() %></strong></td>
                            <td><%= mu.getPatientCount() %></td>
                            <td><%= mu.getAppointmentCount() %></td>
                            <td><span style="color:#10b981;"><i class="fas fa-check-circle"></i> <%= mu.getApprovedCount() %></span></td>
                            <td><span style="color:#ef4444;"><i class="fas fa-times-circle"></i> <%= mu.getRejectedCount() %></span></td>
                            <td><span style="color:#f59e0b;"><i class="fas fa-clock"></i> <%= mu.getPendingCount() %></span></td>
                            <td><strong><%= String.format("%.1f", approvalRate) %>%</strong></td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-chart-pie"></i> Approval Rate Visualization</h3></div>
        <div class="card-body">
            <div style="max-width: 500px; margin: 0 auto;">
                <canvas id="approvalChart"></canvas>
            </div>
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
    const ctx = document.getElementById('approvalChart').getContext('2d');
    const providerNames = [<% if (utilization != null) { for (MedicalAidUtilization mu : utilization) { %>"<%= mu.getProviderName() %>",<% } } %>];
    const approvalRates = [<% if (utilization != null) { for (MedicalAidUtilization mu : utilization) { %><%= mu.getAppointmentCount() > 0 ? (mu.getApprovedCount() * 100.0 / mu.getAppointmentCount()) : 0 %>,<% } } %>];
    
    if (providerNames.length > 0) {
        new Chart(ctx, {
            type: 'pie',
            data: {
                labels: providerNames,
                datasets: [{
                    data: approvalRates,
                    backgroundColor: ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec489a']
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'bottom' },
                    tooltip: { callbacks: { label: function(context) { return context.label + ': ' + context.raw.toFixed(1) + '%'; } } }
                }
            }
        });
    }
</script>
</body>
</html>