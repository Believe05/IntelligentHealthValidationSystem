<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="model.User"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Settings | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>.settings-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; } @media (max-width: 768px) { .settings-grid { grid-template-columns: 1fr; } }</style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links"><a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a><a href="appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a><a href="reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a><a href="settings.jsp" class="nav-item active"><i class="fas fa-cog"></i> Settings</a></div>
        <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Admin</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header"><h1>System Settings</h1><p>Configure system-wide parameters</p></div>

    <% if (request.getParameter("success") != null) { %><div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div><% } %>

    <div class="settings-grid">
        <div class="card"><div class="card-header"><h3><i class="fas fa-cog"></i> General Settings</h3></div><div class="card-body">
            <form action="${pageContext.request.contextPath}/AdminServlet" method="post"><input type="hidden" name="action" value="general">
                <div class="form-group"><label class="form-label">System Name</label><input class="form-control" type="text" value="Intelligent Health Validation System" disabled></div>
                <div class="form-group"><label class="form-label" for="sessionTimeout">Session Timeout (minutes)</label><input class="form-control" type="number" id="sessionTimeout" name="sessionTimeout" value="30" min="5" max="120"></div>
                <div class="form-group"><label class="form-label" for="language">Default Language</label><select class="form-control" id="language" name="language"><option value="en" selected>English</option><option value="af">Afrikaans</option><option value="zu">Zulu</option><option value="xh">Xhosa</option></select></div>
                <button type="submit" class="btn btn-primary">Save Settings</button>
            </form>
        </div></div>

        <div class="card"><div class="card-header"><h3><i class="fas fa-calendar-alt"></i> Appointment Settings</h3></div><div class="card-body">
            <form action="${pageContext.request.contextPath}/AdminServlet" method="post"><input type="hidden" name="action" value="appointment">
                <div class="form-group"><label class="form-label">Default Appointment Duration</label><select class="form-control" name="duration"><option value="30" selected>30 minutes</option><option value="15">15 minutes</option><option value="45">45 minutes</option><option value="60">60 minutes</option></select></div>
                <div class="form-group"><label class="form-label" for="cancelWindow">Cancellation Window (hours before)</label><input class="form-control" type="number" id="cancelWindow" name="cancelWindow" value="2" min="1" max="48"></div>
                <button type="submit" class="btn btn-primary">Save Settings</button>
            </form>
        </div></div>

        <div class="card"><div class="card-header"><h3><i class="fas fa-star"></i> Reliability Score Settings</h3></div><div class="card-body">
            <form action="${pageContext.request.contextPath}/AdminServlet" method="post"><input type="hidden" name="action" value="reliability">
                <div class="form-group"><label class="form-label" for="noShowPenalty">Points Deducted per No-Show</label><input class="form-control" type="number" id="noShowPenalty" name="noShowPenalty" value="10" min="1" max="20"></div>
                <div class="form-group"><label class="form-label" for="cancelPenalty">Points Deducted per Late Cancellation</label><input class="form-control" type="number" id="cancelPenalty" name="cancelPenalty" value="5" min="0" max="10"></div>
                <div class="form-group"><label class="form-label" for="warningThreshold">Warning Threshold Score</label><input class="form-control" type="number" id="warningThreshold" name="warningThreshold" value="60" min="50" max="90"></div>
                <button type="submit" class="btn btn-primary">Save Settings</button>
            </form>
        </div></div>

        <div class="card"><div class="card-header"><h3><i class="fas fa-info-circle"></i> System Information</h3></div><div class="card-body">
            <div class="current-info"><div class="info-row"><span class="key">System Version</span><span class="val">IHVS v2.0 - Clinical Trust</span></div>
            <div class="info-row"><span class="key">Database</span><span class="val">Apache Derby</span></div>
            <div class="info-row"><span class="key">DB Status</span><span class="val"><span class="badge badge-active">Connected</span></span></div>
            <div class="info-row"><span class="key">Java Version</span><span class="val"><%= System.getProperty("java.version") %></span></div>
            <div class="info-row"><span class="key">Server Time</span><span class="val"><%= new java.text.SimpleDateFormat("dd MMM yyyy HH:mm:ss").format(new java.util.Date()) %></span></div></div>
            <div style="margin-top:24px;"><button onclick="alert('Database backup initiated. Check server logs.')" class="btn btn-success btn-sm"><i class="fas fa-database"></i> Backup Database</button></div>
        </div></div>
    </div>
</main>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>
</body>
</html>