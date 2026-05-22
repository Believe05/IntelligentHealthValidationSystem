<%@page import="dao.PatientDAO"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="model.Patient"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
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

    int upcoming = 0;
    int completed = 0;
    int cancelled = 0;
    int noShows = 0;
    
    for (Appointment a : appointments) {
        String status = a.getStatus();
        if ("pending".equals(status) || "confirmed".equals(status)) upcoming++;
        if ("completed".equals(status)) completed++;
        if ("cancelled".equals(status)) cancelled++;
        if ("no-show".equals(status)) noShows++;
    }

    int reliabilityScore = (patient != null) ? patient.getReliabilityScore() : 100;
    int totalAppts = (patient != null) ? patient.getTotalAppointments() : appointments.size();
    
    // Read actual membership_status from database
    String aidStatus = "pending";
    if (patient != null) {
        String status = patient.getMembershipStatus();
        if (status != null && !status.isEmpty()) {
            aidStatus = status;
        }
    }
    
    // Check if they have provider/number filled
    boolean hasMedicalAidInfo = (patient != null && patient.getMedicalAidProvider() != null 
            && !patient.getMedicalAidProvider().trim().isEmpty()
            && patient.getMedicalAidNumber() != null 
            && !patient.getMedicalAidNumber().trim().isEmpty());

    String firstName = "";
    if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
        firstName = user.getFullName().split(" ")[0];
    } else {
        firstName = "Patient";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .badge-active { background: #d1fae5; color: #065f46; }
        .badge-approved { background: #d1fae5; color: #065f46; }
        .badge-pending { background: #fed7aa; color: #92400e; }
        .badge-rejected, .badge-expired { background: #fee2e2; color: #991b1b; }
        .validation-badge {
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 12px;
            display: inline-block;
        }
        .appointment-item {
            border-left: 3px solid transparent;
        }
        .appointment-item.validation-approved {
            border-left-color: var(--success);
        }
        .appointment-item.validation-pending {
            border-left-color: var(--warning);
        }
        .appointment-item.validation-rejected {
            border-left-color: var(--danger);
        }
        .refresh-container {
            text-align: right;
            margin-bottom: 16px;
        }
        .refresh-btn {
            background: var(--primary);
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 12px;
        }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area">
            <i class="fas fa-heartbeat logo-icon"></i>
            <span class="brand-name">IHVS</span>
            <span class="brand-tagline">Intelligent Health Validation System</span>
        </div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="bookAppointment.jsp" class="nav-item <%= !"active".equals(aidStatus) ? "disabled" : "" %>"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
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
        <h1>Good day, <%= firstName %> 👋</h1>
        <p>Here's your health overview and recent activity</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-star"></i></div>
            <div class="stat-info">
                <div class="value"><%= reliabilityScore %>%</div>
                <div class="label">Reliability Score</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-calendar-alt"></i></div>
            <div class="stat-info">
                <div class="value"><%= totalAppts %></div>
                <div class="label">Total Appointments</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-hourglass-half"></i></div>
            <div class="stat-info">
                <div class="value"><%= upcoming %></div>
                <div class="label">Upcoming</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-shield-alt"></i></div>
            <div class="stat-info">
                <div class="value" style="font-size: 18px; text-transform: capitalize;">
                    <span class="badge badge-<%= aidStatus %>"><%= aidStatus.toUpperCase() %></span>
                </div>
                <div class="label">Medical Aid</div>
            </div>
        </div>
    </div>

    <!-- Medical Aid Status Warning Messages -->
    <% if (!"active".equals(aidStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i> 
            <div>
                <strong>Medical Aid Status: <%= aidStatus.toUpperCase() %></strong><br>
                <% if ("pending".equals(aidStatus) && hasMedicalAidInfo) { %>
                    Your medical aid details have been submitted and are pending approval from the medical aid provider. 
                    You cannot book appointments until approved.
                <% } else if ("pending".equals(aidStatus) && !hasMedicalAidInfo) { %>
                    Please complete your medical aid information to enable booking appointments.
                <% } else if ("rejected".equals(aidStatus)) { %>
                    Your medical aid was rejected. Please verify your membership details and update them for re-validation.
                <% } else if ("expired".equals(aidStatus)) { %>
                    Your medical aid coverage has expired. Please update your details with current information.
                <% } %>
                <a href="profile.jsp" style="color: #92400e; font-weight: 600; display: inline-block; margin-top: 5px;">
                    <i class="fas fa-edit"></i> Update your details here
                </a>
            </div>
        </div>
    <% } %>

    <!-- Recent Appointments with Validation Status -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-calendar-alt"></i> Recent Appointments</h3>
            <a href="myAppointments.jsp" class="btn btn-outline btn-sm">View All</a>
        </div>
        <div class="card-body">
            <div class="refresh-container">
                <button onclick="location.reload()" class="refresh-btn"><i class="fas fa-sync-alt"></i> Check Latest Status</button>
            </div>
            <% if (appointments.isEmpty()) { %>
                <div style="text-align: center; padding: 40px;">
                    <i class="fas fa-calendar-times" style="font-size: 48px; opacity: 0.5;"></i>
                    <p style="margin-top: 16px;">You have no appointments yet.</p>
                    <% if ("active".equals(aidStatus)) { %>
                        <a href="bookAppointment.jsp" class="btn btn-primary" style="margin-top: 10px;">Book Your First Appointment →</a>
                    <% } %>
                </div>
            <% } else { 
                int shown = 0;
                for (Appointment apt : appointments) { 
                    if (shown++ >= 5) break;
                    String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                    String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                    String validationClass = "";
                    String validationText = "";
                    if ("active".equalsIgnoreCase(validationStatus) || "approved".equalsIgnoreCase(validationStatus)) {
                        validationClass = "validation-approved";
                        validationText = "APPROVED";
                    } else if ("rejected".equalsIgnoreCase(validationStatus)) {
                        validationClass = "validation-rejected";
                        validationText = "REJECTED";
                    } else {
                        validationClass = "validation-pending";
                        validationText = "PENDING";
                    }
            %>
                <div class="appointment-item <%= validationClass %>" style="display: flex; justify-content: space-between; align-items: center; padding: 16px; border-bottom: 1px solid var(--border);">
                    <div>
                        <div><strong><%= apt.getAppointmentDate() %></strong> at <strong><%= apt.getAppointmentTime() %></strong></div>
                        <div style="font-size: 13px; color: var(--text-muted);">Dr. <%= apt.getDoctorName() != null ? apt.getDoctorName() : "Unknown" %></div>
                    </div>
                    <div style="text-align: right;">
                        <div><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></div>
                        <div style="margin-top: 4px;">
                            <span class="validation-badge badge-<%= validationStatus.equals("active") || validationStatus.equals("approved") ? "active" : (validationStatus.equals("rejected") ? "rejected" : "pending") %>">
                                <i class="fas <%= validationStatus.equals("active") || validationStatus.equals("approved") ? "fa-check-circle" : (validationStatus.equals("rejected") ? "fa-times-circle" : "fa-spinner fa-spin") %>"></i>
                                Medical Aid: <%= validationText %>
                            </span>
                        </div>
                    </div>
                </div>
            <% } } %>
        </div>
    </div>

    <div class="quick-grid">
        <% if ("active".equals(aidStatus)) { %>
            <a href="bookAppointment.jsp" class="quick-card">
                <i class="fas fa-calendar-plus qc-icon"></i>
                <h4>Book Appointment</h4>
                <p>Schedule a visit with a specialist</p>
            </a>
        <% } else { %>
            <div class="quick-card disabled" style="opacity:0.5; cursor:not-allowed;">
                <i class="fas fa-calendar-plus qc-icon"></i>
                <h4>Book Appointment</h4>
                <p style="color: var(--danger);">⚠️ Medical aid approval required</p>
            </div>
        <% } %>
        <a href="myAppointments.jsp" class="quick-card">
            <i class="fas fa-list-ul qc-icon"></i>
            <h4>My Appointments</h4>
            <p>View and manage your visits</p>
        </a>
        <a href="profile.jsp" class="quick-card">
            <i class="fas fa-user-edit qc-icon"></i>
            <h4>Update Profile</h4>
            <p>Manage personal and medical aid info</p>
        </a>
    </div>
    
    <!-- Auto-refresh every 30 seconds -->
    <script>
        setTimeout(function() {
            location.reload();
        }, 30000);
    </script>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>
</body>
</html>