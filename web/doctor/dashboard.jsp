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
    
    // Calculate statistics
    int pending = 0, confirmed = 0, completed = 0, cancelled = 0, noShows = 0;
    int pendingValidation = 0, approvedValidation = 0, rejectedValidation = 0;
    
    for (Appointment a : appointments) {
        String status = a.getStatus();
        if ("pending".equals(status)) pending++;
        else if ("confirmed".equals(status)) confirmed++;
        else if ("completed".equals(status)) completed++;
        else if ("cancelled".equals(status)) cancelled++;
        else if ("no-show".equals(status)) noShows++;
        
        String valStatus = a.getValidationStatus();
        if (valStatus == null || "pending".equals(valStatus)) pendingValidation++;
        else if ("active".equals(valStatus) || "approved".equals(valStatus)) approvedValidation++;
        else if ("rejected".equals(valStatus)) rejectedValidation++;
    }
    
    String firstName = user.getFullName().split(" ")[0];
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Doctor Dashboard | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .badge-active, .badge-approved { background: #d1fae5; color: #065f46; }
        .badge-pending { background: #fed7aa; color: #92400e; }
        .badge-rejected { background: #fee2e2; color: #991b1b; }
        .validation-badge-small {
            display: block;
            font-size: 10px;
            margin-top: 4px;
        }
        .text-muted { color: #6b7280; font-size: 13px; }
        .text-muted i { margin-right: 4px; }
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
        <div class="logo-area">
            <i class="fas fa-heartbeat logo-icon"></i>
            <span class="brand-name">IHVS</span>
            <span class="brand-tagline">Intelligent Health Validation</span>
        </div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
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
        <h1>Welcome, Dr. <%= firstName %> 👨‍⚕️</h1>
        <p>Here's your practice overview and today's schedule</p>
        <button onclick="location.reload()" class="refresh-btn"><i class="fas fa-sync-alt"></i> Refresh</button>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <!-- Appointment Status Stats -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-hourglass-half"></i></div>
            <div class="stat-info">
                <div class="value"><%= pending %></div>
                <div class="label">Pending</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= confirmed %></div>
                <div class="label">Confirmed</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-double"></i></div>
            <div class="stat-info">
                <div class="value"><%= completed %></div>
                <div class="label">Completed</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-user-slash"></i></div>
            <div class="stat-info">
                <div class="value"><%= noShows %></div>
                <div class="label">No-Shows</div>
            </div>
        </div>
    </div>

    <!-- Medical Aid Validation Stats -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-spinner fa-spin"></i></div>
            <div class="stat-info">
                <div class="value"><%= pendingValidation %></div>
                <div class="label">Pending Validation</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= approvedValidation %></div>
                <div class="label">Approved</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-times-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= rejectedValidation %></div>
                <div class="label">Rejected</div>
            </div>
        </div>
    </div>
                
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-calendar-alt"></i> Recent Appointments</h3>
            <a href="manageAppointments.jsp" class="btn btn-outline">View All</a>
        </div>
        <div class="table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Patient</th>
                        <th>Medical Aid</th>
                        <th>PRI</th>
                        <th>Status</th>
                        <th>Validation</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (appointments.isEmpty()) { %>
                        <tr>
                            <td colspan="8" style="text-align:center; padding:60px;">
                                <i class="fas fa-calendar-times" style="font-size:48px; opacity:0.5;"></i>
                                <p style="margin-top:16px;">No appointments yet.</p>
                            </td>
                        </tr>
                    <% } else { 
                        int shown = 0;
                        for (Appointment apt : appointments) { 
                            if (shown++ >= 10) break;
                            String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                            String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                            int score = apt.getReliabilityScore();
                            
                            // Determine display for validation status
                            String displayValidationStatus = validationStatus;
                            String displayValidationText = validationStatus.toUpperCase();
                            String validationIcon = "";
                            
                            if ("active".equalsIgnoreCase(validationStatus) || "approved".equalsIgnoreCase(validationStatus)) {
                                displayValidationStatus = "active";
                                displayValidationText = "APPROVED";
                                validationIcon = "<i class='fas fa-check-circle'></i> ";
                            } else if ("rejected".equalsIgnoreCase(validationStatus)) {
                                displayValidationStatus = "rejected";
                                displayValidationText = "REJECTED";
                                validationIcon = "<i class='fas fa-times-circle'></i> ";
                            } else {
                                displayValidationStatus = "pending";
                                displayValidationText = "PENDING";
                                validationIcon = "<i class='fas fa-spinner fa-spin'></i> ";
                            }
                    %>
                        <tr>
                            <td><strong><%= apt.getAppointmentDate() %></strong></td>
                            <td><%= apt.getAppointmentTime() %></td>
                            <td><strong><%= apt.getPatientName() != null ? apt.getPatientName() : "Unknown" %></strong></td>
                            <td><%= apt.getMedicalAidProvider() != null ? apt.getMedicalAidProvider() : "—" %></td>
                            <td><span style="font-weight:600; color:<%= score >= 80 ? "#10b981" : score >= 60 ? "#f59e0b" : "#ef4444" %>;"><%= score %>%</span></td>
                            <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
                            <td>
                                <span class="badge badge-<%= displayValidationStatus %>"><%= validationIcon %><%= displayValidationText %></span>
                                <% if ("pending".equals(validationStatus)) { %>
                                    <small class="validation-badge-small">
                                        <i class="fas fa-spinner fa-spin"></i> Awaiting medical aid validation
                                    </small>
                                <% } else if ("active".equalsIgnoreCase(validationStatus) || "approved".equalsIgnoreCase(validationStatus)) { %>
                                    <small class="validation-badge-small" style="color: #065f46;">
                                        <i class="fas fa-check-circle"></i> Medical aid verified - Coverage confirmed
                                    </small>
                                <% } else if ("rejected".equalsIgnoreCase(validationStatus)) { %>
                                    <small class="validation-badge-small" style="color: #991b1b;">
                                        <i class="fas fa-exclamation-triangle"></i> Medical aid rejected - Patient may need to pay directly
                                    </small>
                                <% } %>
                             </td>
                            <td class="btn-group">
                                <% if ("pending".equals(status)) { %>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=confirm" class="btn btn-success btn-sm" onclick="return confirm('Confirm this appointment?')"><i class="fas fa-check"></i> Confirm</a>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=cancel" class="btn btn-danger btn-sm" onclick="return confirm('Cancel this appointment?')"><i class="fas fa-times"></i> Cancel</a>
                                <% } else if ("confirmed".equals(status)) { %>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=complete" class="btn btn-primary btn-sm" onclick="return confirm('Mark as completed?')"><i class="fas fa-check-double"></i> Complete</a>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=no-show" class="btn btn-warning btn-sm" onclick="return confirm('Mark as no-show? This will affect patient reliability score.')"><i class="fas fa-user-slash"></i> No-Show</a>
                                <% } else if ("completed".equals(status)) { %>
                                    <span class="text-muted"><i class="fas fa-check"></i> Completed</span>
                                <% } else if ("cancelled".equals(status)) { %>
                                    <span class="text-muted"><i class="fas fa-ban"></i> Cancelled</span>
                                <% } else if ("no-show".equals(status)) { %>
                                    <span class="text-muted"><i class="fas fa-user-slash"></i> No-Show</span>
                                <% } %>
                             </td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>

<script>
    // Auto-refresh every 30 seconds to show latest validation status
    setTimeout(function() {
        location.reload();
    }, 30000);
</script>
</body>
</html>