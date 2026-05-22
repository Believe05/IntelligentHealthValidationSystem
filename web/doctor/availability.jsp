<%@page import="dao.DoctorDAO"%>
<%@page import="model.Doctor"%>
<%@page import="model.DoctorSchedule"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"doctor".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
    List<DoctorSchedule> schedule = null;
    
    if (doctor != null) {
        schedule = doctorDAO.getDoctorSchedule(doctor.getDoctorId());
    }
    
    boolean hasSchedule = schedule != null && !schedule.isEmpty();
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Availability | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>.availability-grid { display: grid; grid-template-columns: 1fr 340px; gap: 24px; align-items: start; } @media (max-width: 768px) { .availability-grid { grid-template-columns: 1fr; } }</style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links"><a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a><a href="availability.jsp" class="nav-item active"><i class="fas fa-clock"></i> Availability</a><a href="profile.jsp" class="nav-item"><i class="fas fa-user-md"></i> Profile</a></div>
        <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name">Dr. <%= user.getFullName() %></div><div class="role">Doctor</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header"><h1>My Availability</h1><p>Set the days and times you are available to see patients</p></div>

    <% if (request.getParameter("success") != null) { %><div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div><% } %>
    <% if (request.getParameter("error") != null) { %><div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error") %></div><% } %>

    <div class="availability-grid">
        <div class="card"><div class="card-header"><h3><i class="fas fa-plus-circle"></i> Add Schedule Entry</h3></div><div class="card-body">
            <form action="${pageContext.request.contextPath}/DoctorServlet" method="post"><input type="hidden" name="action" value="addSchedule">
                <div class="form-group"><label class="form-label">Day of Week</label><select class="form-control" name="dayOfWeek" required><option value="Monday">Monday</option><option value="Tuesday">Tuesday</option><option value="Wednesday">Wednesday</option><option value="Thursday">Thursday</option><option value="Friday">Friday</option><option value="Saturday">Saturday</option><option value="Sunday">Sunday</option></select></div>
                <div class="form-row"><div class="form-group"><label class="form-label">Start Time</label><input type="time" class="form-control" name="startTime" required></div><div class="form-group"><label class="form-label">End Time</label><input type="time" class="form-control" name="endTime" required></div></div>
                <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add to Schedule</button>
            </form>
        </div></div>

        <div class="card"><div class="card-header"><h3><i class="fas fa-calendar-week"></i> Current Schedule</h3></div><div class="card-body">
            <% if (!hasSchedule) { %><p class="text-center" style="padding:20px; color:var(--text-muted);">No schedule set. Add your available days above.</p>
            <% } else { for (DoctorSchedule ds : schedule) { %>
                <div class="info-row"><span class="key"><strong><%= ds.getDayOfWeek() %></strong></span><span class="val"><%= ds.getStartTime() %> - <%= ds.getEndTime() %> <a href="${pageContext.request.contextPath}/DoctorServlet?action=removeSchedule&scheduleId=<%= ds.getScheduleId() %>" class="btn btn-danger btn-sm" style="margin-left:10px;" onclick="return confirm('Remove this schedule entry?')"><i class="fas fa-trash"></i></a></span></div>
            <% } } %>
        </div></div>
    </div>

    <div class="card"><div class="card-header"><h3><i class="fas fa-info-circle"></i> Availability Status</h3></div><div class="card-body"><div style="display:flex; align-items:center; gap:20px;"><span class="badge <%= hasSchedule ? "badge-active" : "badge-pending" %>"><%= hasSchedule ? "SCHEDULE SET" : "NO SCHEDULE" %></span><span style="color:var(--text-muted);"><%= hasSchedule ? "You have " + schedule.size() + " schedule entries. Patients can book appointments during these times." : "Please add schedule entries to start receiving appointments." %></span></div></div></div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>
</body>
</html>