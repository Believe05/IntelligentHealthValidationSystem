<%@page import="java.util.List"%>
<%@page import="model.Reminder"%>
<%@page import="dao.ReminderDAO"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    ReminderDAO reminderDAO = new ReminderDAO();
    List<Reminder> reminders = reminderDAO.getAllReminders();
    List<Reminder> pendingReminders = reminderDAO.getPendingReminders();
    
    String firstName = admin.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reminder Management | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item">Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/reminders.jsp" class="nav-item active">Reminders</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= admin.getFullName() %></div>
                <div class="role">Admin</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Reminder Management</h1>
        <p>System automatically creates reminders when appointments are booked</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div>
    <% } %>

    <!-- Stats -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-bell"></i></div>
            <div class="stat-info">
                <div class="value"><%= reminders.size() %></div>
                <div class="label">Total Reminders</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-clock"></i></div>
            <div class="stat-info">
                <div class="value"><%= pendingReminders.size() %></div>
                <div class="label">Pending</div>
            </div>
        </div>
    </div>

    <!-- Reminders Table - READ Operation -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-list"></i> All Reminders (READ Operation)</h3>
        </div>
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Appointment ID</th>
                        <th>Type</th>
                        <th>Scheduled Time</th>
                        <th>Status</th>
                        <th>Channel</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Reminder r : reminders) { %>
                    <tr>
                        <td><%= r.getReminderId() %></td>
                        <td><%= r.getAppointmentId() %></td>
                        <td><span class="badge badge-info"><%= r.getReminderType() %></span></td>
                        <td><%= r.getScheduledTime() %></td>
                        <td>
                            <span class="badge <%= "sent".equals(r.getStatus()) ? "badge-active" : "badge-pending" %>">
                                <%= r.getStatus() %>
                            </span>
                        </td>
                        <td><%= r.getChannel() %></td>
                        <td class="btn-group">
                            <% if ("pending".equals(r.getStatus())) { %>
                                <a href="${pageContext.request.contextPath}/ReminderServlet?action=markSent&id=<%= r.getReminderId() %>" 
                                   class="btn btn-success btn-sm">Mark Sent (UPDATE)</a>
                            <% } %>
                            <a href="${pageContext.request.contextPath}/ReminderServlet?action=delete&id=<%= r.getReminderId() %>" 
                               class="btn btn-danger btn-sm" 
                               onclick="return confirm('Delete this reminder?')">Delete (DELETE)</a>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Info Box - Explain CREATE Operation -->
    <div class="info-box">
        <h4><i class="fas fa-plus-circle"></i> CREATE Operation - Auto-Generated Reminders</h4>
        <p>When a patient books an appointment, the system automatically CREATES two reminders:</p>
        <ul>
            <li><strong>24-hour reminder:</strong> Sent one day before the appointment</li>
            <li><strong>1-hour reminder:</strong> Sent one hour before the appointment</li>
        </ul>
        <p>This demonstrates the <strong>INSERT/CREATE</strong> operation without manual input.</p>
    </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System.</footer>
</body>
</html>