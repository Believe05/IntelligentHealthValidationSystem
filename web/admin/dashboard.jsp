<%@page import="dao.AdminDAO"%>
<%@page import="dao.UserDAO"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    AdminDAO adminDAO = new AdminDAO();
    UserDAO userDAO = new UserDAO();
    AppointmentDAO apptDAO = new AppointmentDAO();
    PatientDAO patientDAO = new PatientDAO();
    
    int totalUsers = userDAO.getTotalUsers();
    int totalPatients = userDAO.countByRole("patient");
    int totalDoctors = userDAO.countByRole("doctor");
    int totalAppts = apptDAO.countTotal();
    int todayAppts = apptDAO.countByDate(new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()));
    int pendingAppts = apptDAO.countByStatus("pending");
    int confirmedAppts = apptDAO.countByStatus("confirmed");
    int completedAppts = apptDAO.countByStatus("completed");
    int cancelledAppts = apptDAO.countByStatus("cancelled");
    int noShowAppts = apptDAO.countByStatus("no-show");
    
    // Get validation stats from appointments table
    int pendingValidations = 0;
    int approvedValidations = 0;
    int rejectedValidations = 0;
    
    java.util.List<model.Appointment> allAppts = apptDAO.getAllAppointments();
    for (model.Appointment a : allAppts) {
        String valStatus = a.getValidationStatus();
        if (valStatus == null || "pending".equals(valStatus)) {
            pendingValidations++;
        } else if ("active".equals(valStatus) || "approved".equals(valStatus)) {
            approvedValidations++;
        } else if ("rejected".equals(valStatus)) {
            rejectedValidations++;
        }
    }
    
    int validationRate = 0;
    int totalValidations = approvedValidations + rejectedValidations;
    if (totalValidations > 0) {
        validationRate = (approvedValidations * 100) / totalValidations;
    }

    String firstName = "";
    if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
        firstName = user.getFullName().split(" ")[0];
    } else {
        firstName = "Admin";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .refresh-btn {
            background: var(--primary);
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 12px;
            margin-left: 10px;
        }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a>
            <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a>
            <a href="${pageContext.request.contextPath}/admin/providers.jsp" class="nav-item"><i class="fas fa-shield-alt"></i> Medical Aid</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() %></div>
                <div class="role">Admin</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Welcome, <%= firstName %> 👑</h1>
        <p>System-wide overview of IHVS</p>
        <button onclick="location.reload()" class="refresh-btn"><i class="fas fa-sync-alt"></i> Refresh Data</button>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div>
    <% } %>

    <div style="margin-bottom:8px;"><h3><i class="fas fa-users"></i> User Overview</h3></div>
    <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-users"></i></div><div class="stat-info"><div class="value"><%= totalUsers %></div><div class="label">Total Users</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-user"></i></div><div class="stat-info"><div class="value"><%= totalPatients %></div><div class="label">Patients</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-user-md"></i></div><div class="stat-info"><div class="value"><%= totalDoctors %></div><div class="label">Doctors</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-shield-alt"></i></div><div class="stat-info"><div class="value"><%= validationRate %>%</div><div class="label">Med Aid Approval Rate</div></div></div>
    </div>

    <!-- Medical Aid Validation Stats -->
    <div style="margin-bottom:8px; margin-top:24px;"><h3><i class="fas fa-shield-alt"></i> Medical Aid Validation Overview</h3></div>
    <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-spinner fa-spin"></i></div><div class="stat-info"><div class="value"><%= pendingValidations %></div><div class="label">Pending Validations</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-circle"></i></div><div class="stat-info"><div class="value"><%= approvedValidations %></div><div class="label">Approved</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-times-circle"></i></div><div class="stat-info"><div class="value"><%= rejectedValidations %></div><div class="label">Rejected</div></div></div>
    </div>

    <div style="margin-bottom:8px; margin-top:24px;"><h3><i class="fas fa-calendar-alt"></i> Appointment Overview</h3></div>
    <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-calendar-alt"></i></div><div class="stat-info"><div class="value"><%= totalAppts %></div><div class="label">Total Appointments</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-calendar-day"></i></div><div class="stat-info"><div class="value"><%= todayAppts %></div><div class="label">Today</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-double"></i></div><div class="stat-info"><div class="value"><%= completedAppts %></div><div class="label">Completed</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-ban"></i></div><div class="stat-info"><div class="value"><%= cancelledAppts + noShowAppts %></div><div class="label">Cancelled/No-Show</div></div></div>
    </div>

    <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-clock"></i></div><div class="stat-info"><div class="value"><%= pendingAppts %></div><div class="label">Pending</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-circle"></i></div><div class="stat-info"><div class="value"><%= confirmedAppts %></div><div class="label">Confirmed</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-times-circle"></i></div><div class="stat-info"><div class="value"><%= cancelledAppts %></div><div class="label">Cancelled</div></div></div>
        <div class="stat-card"><div class="stat-icon"><i class="fas fa-user-slash"></i></div><div class="stat-info"><div class="value"><%= noShowAppts %></div><div class="label">No-Show</div></div></div>
    </div>

    <div class="quick-grid">
        <a href="${pageContext.request.contextPath}/admin/users.jsp" class="quick-card"><i class="fas fa-users qc-icon"></i><h4>Manage Users</h4><p>Validate patients, edit or remove user accounts</p></a>
        <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="quick-card"><i class="fas fa-calendar-alt qc-icon"></i><h4>View Appointments</h4><p>See all appointments and manage cancellations</p></a>
        <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="quick-card"><i class="fas fa-chart-line qc-icon"></i><h4>View Reports</h4><p>System analytics and appointment statistics</p></a>
    </div>
    
    <!-- Auto-refresh every 30 seconds -->
    <script>
        setTimeout(function() {
            location.reload();
        }, 30000);
    </script>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. All rights reserved.</footer>
</body>
</html>