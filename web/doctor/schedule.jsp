<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Doctor, model.DoctorSchedule, dao.DoctorDAO, java.util.List" %>
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
    
    String firstName = user.getFullName().split(" ")[0];
    String[] days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Schedule | IHVS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
     <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="schedule.jsp" class="nav-item active"><i class="fas fa-clock"></i> Schedule</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user"></i> Profile</a>
        </div>
        <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><a href="${pageContext.request.contextPath}/LogoutServlet" style="margin-left:16px; color:var(--text-muted);"><i class="fas fa-sign-out-alt"></i></a></div>
    </div>
</nav>

<main class="main-content">
    <div class="card">
        <div class="card-header"><i class="fas fa-plus-circle"></i> Add Working Hours</div>
        <div class="card-body">
            <form action="${pageContext.request.contextPath}/DoctorServlet" method="post">
                <input type="hidden" name="action" value="addSchedule">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Day</label>
                        <select name="dayOfWeek" class="form-control" required>
                            <option value="">Select Day</option>
                            <% for (String day : days) { %>
                                <option value="<%= day %>"><%= day %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Start Time</label>
                        <!-- ✅ TIME PICKER ADDED HERE ✅ -->
                        <input type="time" class="form-control" name="startTime" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">End Time</label>
                        <!-- ✅ TIME PICKER ADDED HERE ✅ -->
                        <input type="time" class="form-control" name="endTime" required>
                    </div>
                    <div class="form-group">
                        <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Schedule</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <% if (schedule != null && !schedule.isEmpty()) { %>
    <div class="card">
        <div class="card-header"><i class="fas fa-calendar-week"></i> Your Current Schedule</div>
        <div class="card-body">
            <table>
                <thead><tr><th>Day</th><th>Start Time</th><th>End Time</th><th>Action</th></tr></thead>
                <tbody>
                    <% for (DoctorSchedule ds : schedule) { %>
                    <tr>
                        <td><%= ds.getDayOfWeek() %></td>
                        <td><%= ds.getStartTime() %></td>
                        <td><%= ds.getEndTime() %></td>
                        <td>
                            <a href="${pageContext.request.contextPath}/DoctorServlet?action=removeSchedule&scheduleId=<%= ds.getScheduleId() %>" 
                               class="btn btn-danger" style="padding:4px 12px;" 
                               onclick="return confirm('Remove this schedule?')">Remove</a>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
    <% } %>
</main>
<footer class="page-footer">&copy; 2026 Intelligent Health Validation System</footer>
</body>
</html>