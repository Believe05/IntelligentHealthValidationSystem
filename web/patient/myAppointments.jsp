<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
<%@page import="model.User"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="model.Patient"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());
    
    AppointmentDAO aptDAO = new AppointmentDAO();
    List<Appointment> appointments = new java.util.ArrayList<>();
    
    if (patient != null) {
        appointments = aptDAO.getAppointmentsByPatient(patient.getPatientId());
    }
    
    String firstName = user.getFullName().split(" ")[0];
    String aidStatus = "pending";
    if (patient != null && patient.getMedicalAidProvider() != null 
            && patient.getMedicalAidNumber() != null 
            && !patient.getMedicalAidProvider().trim().isEmpty()
            && !patient.getMedicalAidNumber().trim().isEmpty()) {
        aidStatus = "active";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Appointments | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
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
            <a href="bookAppointment.jsp" class="nav-item"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="myAppointments.jsp" class="nav-item active"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user-circle"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() %></div>
                <div class="role">Patient</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>My Appointments</h1>
        <p>View and manage your scheduled visits</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <% if (!"active".equals(aidStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            Your medical aid status is <strong><%= aidStatus %></strong>. 
            <a href="profile.jsp">Update your details here</a>
        </div>
    <% } %>

    <!-- Filter Buttons -->
    <div class="filter-bar">
        <button class="btn-filter active" onclick="filterTable('all', this)">All</button>
        <button class="btn-filter" onclick="filterTable('pending', this)">Pending</button>
        <button class="btn-filter" onclick="filterTable('confirmed', this)">Confirmed</button>
        <button class="btn-filter" onclick="filterTable('completed', this)">Completed</button>
        <button class="btn-filter" onclick="filterTable('cancelled', this)">Cancelled</button>
        <button class="btn-filter" onclick="filterTable('no-show', this)">No-Show</button>
    </div>

    <!-- Appointments Table -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-calendar-alt"></i> Appointment History</h3>
            <span class="badge badge-active"><%= appointments.size() %> Total</span>
        </div>
        <div class="table-wrapper">
            <table id="appointmentsTable">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Doctor</th>
                        <th>Specialization</th>
                        <th>Status</th>
                        <th>Validation</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (appointments.isEmpty()) { %>
                        <tr class="text-center">
                            <td colspan="7" style="text-align:center; padding:60px;">
                                <i class="fas fa-calendar-times" style="font-size:48px; opacity:0.5;"></i>
                                <p style="margin-top:16px;">You have no appointments yet.</p>
                                <a href="bookAppointment.jsp" class="btn btn-primary" style="margin-top:10px;">Book Your First Appointment →</a>
                            </td>
                        </tr>
                    <% } else { 
                        for (Appointment apt : appointments) { 
                            String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                            String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                            boolean canCancel = "pending".equals(status) || "confirmed".equals(status);
                    %>
                        <tr data-status="<%= status %>">
                            <td><strong><%= apt.getAppointmentDate() %></strong></td>
                            <td><%= apt.getAppointmentTime() %></td>
                            <td><strong><%= apt.getDoctorName() != null ? apt.getDoctorName() : "Loading..." %></strong></td>
                            <td><%= apt.getSpecialization() != null ? apt.getSpecialization() : "General" %></td>
                            <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
                            <td><span class="badge badge-<%= validationStatus %>"><%= validationStatus.toUpperCase() %></span></td>
                            <td class="btn-group">
                                <% if (canCancel) { %>
                                    <button class="btn btn-danger btn-sm" onclick="showCancelModal(<%= apt.getAppointmentId() %>)">
                                        <i class="fas fa-times"></i> Cancel
                                    </button>
                                <% } else { %>
                                    <span style="font-size:12px; color:var(--text-muted);">—</span>
                                <% } %>
                                <% if ("cancelled".equals(status) && apt.getCancellationReason() != null && !apt.getCancellationReason().isEmpty()) { %>
                                    <div class="cancel-reason"><small>Reason: <%= apt.getCancellationReason() %></small></div>
                                <% } %>
                            </td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<!-- Cancel Modal -->
<div id="cancelModal" class="modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); justify-content:center; align-items:center; z-index:1000;">
    <div class="modal-content" style="background:white; border-radius:12px; width:400px; max-width:90%; padding:24px;">
        <h3><i class="fas fa-exclamation-triangle" style="color:var(--danger);"></i> Cancel Appointment</h3>
        <p>Please provide a reason for cancellation:</p>
        <textarea id="cancelReason" class="form-control" rows="3" placeholder="e.g., Feeling better, schedule conflict, etc."></textarea>
        <div style="display:flex; gap:12px; margin-top:20px; justify-content:flex-end;">
            <button onclick="closeCancelModal()" class="btn btn-outline">Close</button>
            <button onclick="confirmCancel()" class="btn btn-danger">Cancel Appointment</button>
        </div>
    </div>
</div>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
    let currentCancelId = null;
    
    function filterTable(status, button) {
        const rows = document.querySelectorAll('#appointmentsTable tbody tr');
        const buttons = document.querySelectorAll('.btn-filter');
        buttons.forEach(btn => btn.classList.remove('active'));
        if (button) button.classList.add('active');
        
        rows.forEach(row => {
            if (row.querySelector('td[colspan]')) return; // Skip empty message row
            if (status === 'all') {
                row.style.display = '';
            } else {
                const rowStatus = row.getAttribute('data-status');
                row.style.display = rowStatus === status ? '' : 'none';
            }
        });
    }
    
    function showCancelModal(appointmentId) {
        currentCancelId = appointmentId;
        document.getElementById('cancelModal').style.display = 'flex';
    }
    
    function closeCancelModal() {
        document.getElementById('cancelModal').style.display = 'none';
        document.getElementById('cancelReason').value = '';
        currentCancelId = null;
    }
    
    function confirmCancel() {
        if (currentCancelId) {
            const reason = document.getElementById('cancelReason').value.trim();
            const encodedReason = encodeURIComponent(reason || 'No reason provided');
            window.location.href = '${pageContext.request.contextPath}/UpdateAppointmentServlet?id=' + currentCancelId + '&action=cancel&reason=' + encodedReason;
        }
        closeCancelModal();
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('cancelModal');
        if (event.target === modal) {
            closeCancelModal();
        }
    }
</script>
</body>
</html>