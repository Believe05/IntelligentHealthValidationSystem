<%@page import="dao.PatientDAO"%>
<%@page import="dao.MedicalAidDAO"%>
<%@page import="model.MedicalAidProvider"%>
<%@page import="model.Patient"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());
    
    // Get all medical aid providers from database (not hardcoded!)
    MedicalAidDAO medicalAidDAO = new MedicalAidDAO();
    List<MedicalAidProvider> providers = medicalAidDAO.getAllProviders();

    String provider = (patient != null && patient.getMedicalAidProvider() != null) ? patient.getMedicalAidProvider() : "";
    String aidNumber = (patient != null && patient.getMedicalAidNumber() != null) ? patient.getMedicalAidNumber() : "";
    
    // Read actual membership_status from database
    String aidStatus = "pending";
    if (patient != null) {
        String status = patient.getMembershipStatus();
        if (status != null && !status.isEmpty()) {
            aidStatus = status;
        }
    }
    
    // Check if they have provider/number filled (for display purposes)
    boolean hasMedicalAidInfo = (provider != null && !provider.trim().isEmpty() 
            && aidNumber != null && !aidNumber.trim().isEmpty());
    
    int reliability = (patient != null) ? patient.getReliabilityScore() : 100;
    int noShows = (patient != null) ? patient.getNoShowCount() : 0;
    int totalAppts = (patient != null) ? patient.getTotalAppointments() : 0;
    int completed = (patient != null) ? patient.getCompletedCount() : 0;
    int cancelled = (patient != null) ? patient.getCancellationCount() : 0;
    
    double noShowRate = totalAppts > 0 ? (noShows * 100.0 / totalAppts) : 0;
    double completionRate = totalAppts > 0 ? (completed * 100.0 / totalAppts) : 0;
    double cancellationRate = totalAppts > 0 ? (cancelled * 100.0 / totalAppts) : 0;
    
    // Null-safe first name extraction
    String fullName = user.getFullName() != null ? user.getFullName() : "Patient";
    String firstName = fullName.isEmpty() ? "Patient" : fullName.split(" ")[0];
    
    // Status display variables
    String membershipStatus = aidStatus;
    String statusColor = "";
    String statusIcon = "";
    String statusMessage = "";
    
    switch (membershipStatus.toLowerCase()) {
        case "active":
            statusColor = "#166534";
            statusIcon = "✅";
            statusMessage = "Your medical aid is ACTIVE. You can book appointments.";
            break;
        case "pending":
            statusColor = "#92400e";
            statusIcon = "⏳";
            statusMessage = "Your medical aid is PENDING approval. Please wait for medical aid provider to verify your details.";
            break;
        case "rejected":
            statusColor = "#991b1b";
            statusIcon = "❌";
            statusMessage = "Your medical aid was REJECTED. Please update your details or contact support.";
            break;
        case "expired":
            statusColor = "#92400e";
            statusIcon = "⚠️";
            statusMessage = "Your medical aid has EXPIRED. Please update your details.";
            break;
        default:
            statusColor = "#64748b";
            statusIcon = "❓";
            statusMessage = "Medical aid status unknown. Please update your details.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | IHVS</title>
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
            <a href="${pageContext.request.contextPath}/patient/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/patient/bookAppointment.jsp" class="nav-item"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="${pageContext.request.contextPath}/patient/myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/patient/profile.jsp" class="nav-item active"><i class="fas fa-user-circle"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() != null ? user.getFullName() : "Patient" %></div>
                <div class="role">Patient</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>My Profile</h1>
        <p>Manage your personal information and medical aid details</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>
    
    <!-- MEDICAL AID STATUS BANNER - PROMINENT DISPLAY -->
    <div class="status-banner">
        <div class="status-icon"><%= statusIcon %></div>
        <div class="status-content">
            <div class="status-title" style="color: <%= statusColor %>;">
                Medical Aid Status: <%= membershipStatus.toUpperCase() %>
            </div>
            <div class="status-message"><%= statusMessage %></div>
        </div>
    </div>
    
    <% if (!"active".equalsIgnoreCase(membershipStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            <strong>Important:</strong> You cannot book appointments until your medical aid status is <strong>ACTIVE</strong>. 
            Please update your medical aid details below and wait for approval from your medical aid provider.
        </div>
    <% } %>
    
    <div class="profile-grid">
        <!-- Personal Information Card -->
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-user"></i> Personal Information</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/PatientServlet" method="post">
                    <input type="hidden" name="action" value="updateProfile">
                    <div class="form-group">
                        <label class="form-label">Username</label>
                        <input class="form-control" type="text" value="<%= user.getUsername() %>" disabled>
                        <small class="form-hint">Username cannot be changed.</small>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="fullName">Full Name</label>
                        <input class="form-control" type="text" id="fullName" name="fullName" value="<%= user.getFullName() != null ? user.getFullName() : "" %>" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="email">Email Address</label>
                        <input class="form-control" type="email" id="email" name="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="phone">Phone Number</label>
                        <input class="form-control" type="tel" id="phone" name="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>" required>
                    </div>
                    <button type="submit" class="btn btn-primary">Save Personal Info</button>
                </form>
            </div>
        </div>

        <!-- Medical Aid Information Card -->
        <div class="card" id="medicalAidSection">
            <div class="card-header">
                <h3><i class="fas fa-shield-alt"></i> Medical Aid Information</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/PatientServlet" method="post">
                    <input type="hidden" name="action" value="updateMedicalAid">
                    <div class="form-group">
                        <label class="form-label" for="medicalAidProvider">Medical Aid Provider</label>
                        <select class="form-control" id="medicalAidProvider" name="medicalAidProvider" required>
                            <option value="">— Select Provider —</option>
                            <% 
                                // Populate dropdown from database using MedicalAidDAO
                                for (MedicalAidProvider p : providers) { 
                                    String providerName = p.getProviderName();
                                    boolean isSelected = providerName != null && providerName.equals(provider);
                            %>
                                <option value="<%= providerName %>" <%= isSelected ? "selected" : "" %>>
                                    <%= providerName %>
                                </option>
                            <% } %>
                        </select>
                        <small class="form-hint">
                            <i class="fas fa-database"></i> Providers loaded from database (<%= providers.size() %> active providers)
                        </small>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="medicalAidNumber">Membership Number</label>
                        <input class="form-control" type="text" id="medicalAidNumber" name="medicalAidNumber" value="<%= aidNumber %>" placeholder="Enter your membership number" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Current Status</label>
                        <div>
                            <span class="badge badge-<%= aidStatus %>">
                                <%= aidStatus.toUpperCase() %>
                            </span>
                            <% if ("pending".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px;">
                                    <i class="fas fa-clock"></i> 
                                    <% if (hasMedicalAidInfo) { %>
                                        Your medical aid details are pending approval from the provider. 
                                        You will be notified once approved. <strong>You cannot book appointments until approved.</strong>
                                    <% } else { %>
                                        Please complete your medical aid details above. After submission, they will be validated by the medical aid provider.
                                    <% } %>
                                </small>
                            <% } else if ("rejected".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--danger);">
                                    <i class="fas fa-exclamation-triangle"></i> 
                                    Your medical aid was rejected. Please verify your membership number and provider, then update the information above for re-validation.
                                </small>
                            <% } else if ("active".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--success);">
                                    <i class="fas fa-check-circle"></i> 
                                    Your medical aid is active and validated. You can book appointments.
                                </small>
                            <% } else if ("expired".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--warning);">
                                    <i class="fas fa-calendar-times"></i> 
                                    Your medical aid coverage has expired. Please update your details.
                                </small>
                            <% } %>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary">Update Medical Aid</button>
                </form>
                
                <% if (patient != null && patient.getLastValidation() != null) { %>
                    <p style="margin-top: 15px; font-size: 12px; color: #888;">
                        Last updated: <%= patient.getLastValidation() %>
                    </p>
                <% } %>
            </div>
        </div>

        <!-- Account Statistics Card (Full Width) -->
        <div class="card" style="grid-column: 1 / -1;">
            <div class="card-header">
                <h3><i class="fas fa-chart-line"></i> Account Statistics</h3>
            </div>
            <div class="card-body">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-star"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= reliability %>%</div>
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
                        <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= completed %></div>
                            <div class="label">Completed</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-times-circle"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= noShows %></div>
                            <div class="label">No-Shows</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-ban"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= cancelled %></div>
                            <div class="label">Cancelled</div>
                        </div>
                    </div>
                </div>
                
                <div style="margin-top:24px; display:grid; grid-template-columns:repeat(3,1fr); gap:16px;">
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--success);"><%= String.format("%.1f", completionRate) %>%</div>
                        <div style="font-size:12px;">Completion Rate</div>
                    </div>
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--danger);"><%= String.format("%.1f", noShowRate) %>%</div>
                        <div style="font-size:12px;">No-Show Rate</div>
                    </div>
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--warning);"><%= String.format("%.1f", cancellationRate) %>%</div>
                        <div style="font-size:12px;">Cancellation Rate</div>
                    </div>
                </div>
                
                <% if (reliability < 70) { %>
                    <div class="alert alert-warning mt-4">
                        <i class="fas fa-exclamation-triangle"></i> 
                        Your reliability score is below 70%. Repeated no-shows may result in booking restrictions.
                    </div>
                <% } %>
                
                <% if (reliability >= 90 && totalAppts > 5) { %>
                    <div class="alert alert-success mt-4">
                        <i class="fas fa-trophy"></i> 
                        Excellent reliability! You have priority booking privileges.
                    </div>
                <% } %>
            </div>
        </div>
    </div>
    
    <div style="text-align: center; margin-top: 20px;">
        <a href="dashboard.jsp" style="color: var(--primary);">← Back to Dashboard</a>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition. All rights reserved.
</footer>
</body>
</html>