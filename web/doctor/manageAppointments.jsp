<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
<%@page import="model.User"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.DoctorDAO"%>
<%@page import="model.Doctor"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"doctor".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    AppointmentDAO aptDAO = new AppointmentDAO();
    
    Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
    List<Appointment> appointments = new java.util.ArrayList<>();
    
    if (doctor != null) {
        appointments = aptDAO.getAppointmentsByDoctor(doctor.getDoctorId());
    }
    
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Appointments | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
     <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    
    
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area">
            <i class="fas fa-heartbeat logo-icon"></i>
            <span class="brand-name">IHVS</span>
            <span class="brand-tagline">Intelligent Health Validation</span>
        </div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="manageAppointments.jsp" class="nav-item active"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="schedule.jsp" class="nav-item"><i class="fas fa-clock"></i> Availability</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user-md"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name">Dr. <%= user.getFullName() %></div>
                <div class="role">Doctor</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Manage Appointments</h1>
        <p>Review, confirm, and manage your patient appointments</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="filter-buttons">
        <button class="btn btn-outline active" onclick="filterTable('all', this)">All</button>
        <button class="btn btn-outline" onclick="filterTable('pending', this)">Pending</button>
        <button class="btn btn-outline" onclick="filterTable('confirmed', this)">Confirmed</button>
        <button class="btn btn-outline" onclick="filterTable('completed', this)">Completed</button>
        <button class="btn btn-outline" onclick="filterTable('cancelled', this)">Cancelled</button>
        <button class="btn btn-outline" onclick="filterTable('no-show', this)">No-Show</button>
    </div>

    <div class="card">
        <div class="table-wrapper">
            <table id="appointmentsTable">
                <thead>
                    <tr><th>Date</th><th>Time</th><th>Patient</th><th>Contact</th><th>Medical Aid</th><th>PRI</th><th>Notes</th><th>Status</th><th>Validation</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <% if (appointments.isEmpty()) { %>
                        <tr><td colspan="10" style="text-align:center; padding:60px;"><i class="fas fa-calendar-times" style="font-size:48px; opacity:0.5;"></i><p style="margin-top:16px;">No appointments yet.</p></td></tr>
                    <% } else { 
                        for (Appointment apt : appointments) { 
                            String notes = apt.getNotes() != null ? apt.getNotes() : "—";
                            if (notes.length() > 30) notes = notes.substring(0, 30) + "…";
                            int score = apt.getReliabilityScore();
                            String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                            String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                    %>
                        <tr data-status="<%= status %>">
                            <td><strong><%= apt.getAppointmentDate() %></strong></td>
                            <td><%= apt.getAppointmentTime() %></td>
                            <td><strong><%= apt.getPatientName() != null ? apt.getPatientName() : "Unknown" %></strong></td>
                            <td><%= apt.getPatientPhone() != null ? apt.getPatientPhone() : "—" %></td>
                            <td><%= apt.getMedicalAidProvider() != null ? apt.getMedicalAidProvider() : "—" %></td>
                            <td><span style="font-weight:600; color:<%= score >= 80 ? "#10b981" : score >= 60 ? "#f59e0b" : "#ef4444" %>;"><%= score %></span></td>
                            <td><%= notes %></td>
                            <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
                            <td>
                                <span class="badge badge-<%= validationStatus %>"><%= validationStatus.toUpperCase() %></span>
                                <% if ("pending".equals(validationStatus)) { %>
                                    <small class="validation-small"><i class="fas fa-spinner fa-spin"></i> Processing</small>
                                <% } %>
                            </td>
                            <td class="btn-group">
                                <% if ("pending".equals(status)) { %>
                                    <a href="#" onclick="updateAppointment(<%= apt.getAppointmentId() %>, 'confirm', this)" class="btn btn-success"><i class="fas fa-check"></i> Confirm</a>
                                    <a href="#" onclick="updateAppointment(<%= apt.getAppointmentId() %>, 'cancel', this)" class="btn btn-danger"><i class="fas fa-times"></i> Cancel</a>
                                <% } else if ("confirmed".equals(status)) { %>
                                    <a href="#" onclick="updateAppointment(<%= apt.getAppointmentId() %>, 'complete', this)" class="btn btn-primary"><i class="fas fa-check-double"></i> Complete</a>
                                    <a href="#" onclick="updateAppointment(<%= apt.getAppointmentId() %>, 'no-show', this)" class="btn btn-warning"><i class="fas fa-user-slash"></i> No-Show</a>
                                <% } else { %>
                                    <span style="font-size:12px; color:var(--text-muted);">—</span>
                                <% } %>
                            </td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
function filterTable(status, button) {
    var rows = document.querySelectorAll('#appointmentsTable tbody tr');
    document.querySelectorAll('.filter-buttons .btn').forEach(btn => btn.classList.remove('active'));
    if (button) button.classList.add('active');
    rows.forEach(row => {
        if (status === 'all') row.style.display = '';
        else {
            var rowStatus = row.getAttribute('data-status');
            row.style.display = rowStatus === status ? '' : 'none';
        }
    });
}

function updateAppointment(id, action, element) {
    if (!confirm('Are you sure you want to ' + action + ' this appointment?')) return;
    
    var originalText = element.innerHTML;
    element.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    element.classList.add('loading-btn');
    element.style.pointerEvents = 'none';
    
    fetch('${pageContext.request.contextPath}/UpdateAppointmentServlet?id=' + id + '&action=' + action)
        .then(response => response.text())
        .then(data => {
            if (data.includes('success') || data.includes('redirect')) {
                location.reload();
            } else {
                alert('Error updating appointment. Please try again.');
                element.innerHTML = originalText;
                element.classList.remove('loading-btn');
                element.style.pointerEvents = 'auto';
            }
        })
        .catch(error => {
            alert('Network error. Please try again.');
            element.innerHTML = originalText;
            element.classList.remove('loading-btn');
            element.style.pointerEvents = 'auto';
        });
}
</script>
</body>
</html>