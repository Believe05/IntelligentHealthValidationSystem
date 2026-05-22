<!DOCTYPE html>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Patient, model.MedicalAidProvider, dao.PatientDAO, dao.MedicalAidDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"medicalaid".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  MedicalAidDAO medDAO = new MedicalAidDAO();
  PatientDAO patientDAO = new PatientDAO();
  
  MedicalAidProvider provider = medDAO.getProviderByUserId(user.getUserId());
  
  List<Patient> pendingPatients = new java.util.ArrayList<>();
  List<Patient> approvedPatients = new java.util.ArrayList<>();
  List<Patient> rejectedPatients = new java.util.ArrayList<>();
  
  if (provider != null && provider.getProviderName() != null) {
      try {
          pendingPatients = patientDAO.getPatientsByProviderAndStatus(provider.getProviderName(), "pending");
      } catch (Exception e) { pendingPatients = new java.util.ArrayList<>(); }
      try {
          approvedPatients = patientDAO.getPatientsByProviderAndStatus(provider.getProviderName(), "active");
      } catch (Exception e) { approvedPatients = new java.util.ArrayList<>(); }
      try {
          rejectedPatients = patientDAO.getPatientsByProviderAndStatus(provider.getProviderName(), "rejected");
      } catch (Exception e) { rejectedPatients = new java.util.ArrayList<>(); }
  }
  
  String firstName = "";
  if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
      firstName = user.getFullName().split(" ")[0];
  } else {
      firstName = "Provider";
  }
  
  String providerName = (provider != null && provider.getProviderName() != null) ? provider.getProviderName() : "Medical Aid Provider";
%>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Medical Aid Dashboard | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .badge-active { background: #d1fae5; color: #065f46; }
        .badge-pending { background: #fed7aa; color: #92400e; }
        .badge-rejected { background: #fee2e2; color: #991b1b; }
        * { box-sizing: border-box; }
        body { margin: 0; padding: 0; }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="validations.jsp" class="nav-item"><i class="fas fa-clock"></i> Pending Validations</a>
            <a href="history.jsp" class="nav-item"><i class="fas fa-history"></i> History</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() %></div>
                <div class="role">Medical Aid - <%= providerName %></div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Welcome, <%= firstName %>!</h1>
        <p><%= providerName %> - Manage patient medical aid validations</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-clock"></i></div>
            <div class="stat-info">
                <div class="value"><%= pendingPatients.size() %></div>
                <div class="label">Pending Validations</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= approvedPatients.size() %></div>
                <div class="label">Approved Members</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-times-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= rejectedPatients.size() %></div>
                <div class="label">Rejected Members</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-users"></i></div>
            <div class="stat-info">
                <div class="value"><%= pendingPatients.size() + approvedPatients.size() + rejectedPatients.size() %></div>
                <div class="label">Total Patients</div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-clock"></i> Pending Medical Aid Validations</h3>
            <span class="badge badge-pending"><%= pendingPatients.size() %> Pending</span>
        </div>
        <div class="card-body">
            <% if (pendingPatients == null || pendingPatients.isEmpty()) { %>
                <div style="padding: 60px; text-align: center;">
                    <i class="fas fa-check-circle" style="font-size: 64px; color: var(--success); opacity: 0.5;"></i>
                    <p style="margin-top: 16px;">No pending validations. All patients have been processed.</p>
                </div>
            <% } else { %>
                <div class="table-wrapper">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Patient Name</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Member Number</th>
                                <th>Registered Date</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Patient p : pendingPatients) { 
                                if (p == null) continue;
                            %>
                                <tr>
                                    <td><strong><%= p.getFullName() != null ? p.getFullName() : "Unknown" %></strong></td>
                                    <td><%= p.getEmail() != null ? p.getEmail() : "N/A" %></td>
                                    <td><%= p.getPhone() != null ? p.getPhone() : "N/A" %></td>
                                    <td><code><%= p.getMedicalAidNumber() != null ? p.getMedicalAidNumber() : "N/A" %></code></td>
                                    <td><%= p.getCreatedAt() != null ? p.getCreatedAt() : "N/A" %></td>
                                    <td class="btn-group">
                                        <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=approvePatient&patientId=<%= p.getPatientId() %>" 
                                           class="btn btn-success btn-sm" 
                                           onclick="return confirm('Approve medical aid for <%= p.getFullName() %>?')">
                                            <i class="fas fa-check"></i> Approve
                                        </a>
                                        <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=rejectPatient&patientId=<%= p.getPatientId() %>" 
                                           class="btn btn-danger btn-sm" 
                                           onclick="return confirm('Reject medical aid for <%= p.getFullName() %>?')">
                                            <i class="fas fa-times"></i> Reject
                                        </a>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } %>
        </div>
    </div>

    <% if (approvedPatients != null && !approvedPatients.isEmpty()) { %>
    <div class="card" style="margin-top: 24px;">
        <div class="card-header">
            <h3><i class="fas fa-check-circle"></i> Recently Approved Members</h3>
            <span class="badge badge-active"><%= approvedPatients.size() %> Approved</span>
        </div>
        <div class="card-body">
            <div class="table-wrapper">
                <table class="data-table">
                    <thead>
                        <tr><th>Patient Name</th><th>Member Number</th><th>Approved Date</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                        <% int count = 0; for (Patient p : approvedPatients) { 
                            if (count++ >= 10) break;
                            if (p == null) continue;
                        %>
                            <tr>
                                <td><%= p.getFullName() %></td>
                                <td><%= p.getMedicalAidNumber() %></td>
                                <td><%= p.getLastValidation() != null ? p.getLastValidation() : "N/A" %></td>
                                <td><span class="badge badge-active">ACTIVE</span></td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <% } %>

    <div class="info-box" style="margin-top: 24px;">
        <h4><i class="fas fa-info-circle"></i> How Patient Validation Works</h4>
        <ul>
            <li>Patients register and provide their medical aid details</li>
            <li>Their status is initially <strong>PENDING</strong> - they cannot book appointments</li>
            <li>You review their membership number and approve or reject</li>
            <li>Approved patients can immediately book appointments</li>
            <li>Rejected patients must update their details or contact support</li>
        </ul>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>
</body>
</html>