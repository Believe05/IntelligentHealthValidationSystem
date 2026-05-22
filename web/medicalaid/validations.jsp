<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page import="model.Appointment"%>
<%@page import="model.MedicalAidProvider"%>
<%@page import="model.Patient"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.MedicalAidDAO"%>
<%@page import="dao.PatientDAO"%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"medicalaid".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  // Get attributes from MedicalAidServlet
  List<Appointment> pending = (List<Appointment>) request.getAttribute("pendingValidations");
  if (pending == null) pending = new java.util.ArrayList<>();
  
  MedicalAidProvider provider = (MedicalAidProvider) request.getAttribute("provider");
  
  // Also get pending patients
  PatientDAO patientDAO = new PatientDAO();
  List<Patient> pendingPatients = new java.util.ArrayList<>();
  
  if (provider != null && provider.getProviderName() != null) {
      pendingPatients = patientDAO.getPatientsByProviderAndStatus(provider.getProviderName(), "pending");
      if (pendingPatients == null) pendingPatients = new java.util.ArrayList<>();
  }
  
  int totalPending = pending.size() + pendingPatients.size();
  
  String firstName = "";
  if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
      firstName = user.getFullName().split(" ")[0];
  } else {
      firstName = "Provider";
  }
  
  String providerName = (provider != null && provider.getProviderName() != null) ? provider.getProviderName() : "Medical Aid Provider";
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Pending Validations | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <style>
    .pending-item {
      border-left: 3px solid #f59e0b;
    }
    .badge-pending {
      background: #fed7aa;
      color: #92400e;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }
    .badge-active {
      background: #d1fae5;
      color: #065f46;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }
    .badge-rejected {
      background: #fee2e2;
      color: #991b1b;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }
    .empty-state {
      text-align: center;
      padding: 60px;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      margin-bottom: 30px;
    }
    .stat-card {
      background: white;
      padding: 20px;
      border-radius: 12px;
      text-align: center;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .stat-card .value {
      font-size: 32px;
      font-weight: 700;
    }
    .stat-card .label {
      font-size: 14px;
      color: #64748b;
      margin-top: 5px;
    }
    .btn-group {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }
    .btn-sm {
      padding: 5px 12px;
      font-size: 12px;
    }
    .table-wrapper {
      overflow-x: auto;
    }
    .data-table {
      width: 100%;
      border-collapse: collapse;
    }
    .data-table th, .data-table td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #e2e8f0;
    }
    .data-table th {
      background: #f8fafc;
      font-weight: 600;
    }
  </style>
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links">
      <a href="${pageContext.request.contextPath}/medicalaid/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
      <a href="${pageContext.request.contextPath}/medicalaid/validations.jsp" class="nav-item active"><i class="fas fa-check-circle"></i> Validations</a>
      <a href="${pageContext.request.contextPath}/medicalaid/history.jsp" class="nav-item"><i class="fas fa-history"></i> History</a>
    </div>
    <div class="user-menu">
      <div class="user-avatar"><%= firstName.charAt(0) %></div>
      <div class="user-info">
        <div class="name"><%= user.getFullName() != null ? user.getFullName() : "Provider" %></div>
        <div class="role">Medical Aid - <%= providerName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
    </div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header">
    <h1><i class="fas fa-clock"></i> Pending Validations</h1>
    <p><%= providerName %> - Review and validate patient medical aid requests</p>
  </div>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="value" style="color: #f59e0b;"><%= totalPending %></div>
      <div class="label">Pending Validations</div>
    </div>
    <div class="stat-card">
      <div class="value" style="color: #3b82f6;"><%= pendingPatients.size() %></div>
      <div class="label">Pending Patient Registrations</div>
    </div>
  </div>

  <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
  <% } %>
  <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
  <% } %>

  <!-- Pending Patients -->
  <% if (!pendingPatients.isEmpty()) { %>
  <div class="card">
    <div class="card-header">
      <h3><i class="fas fa-users"></i> Pending Patient Registrations</h3>
      <span class="badge-pending"><%= pendingPatients.size() %> Pending</span>
    </div>
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
            <tr class="pending-item">
              <td><strong><%= p.getFullName() != null ? p.getFullName() : "Unknown" %></strong></td>
              <td><%= p.getEmail() != null ? p.getEmail() : "N/A" %></td>
              <td><%= p.getPhone() != null ? p.getPhone() : "N/A" %></td>
              <td><code><%= p.getMedicalAidNumber() != null ? p.getMedicalAidNumber() : "N/A" %></code></td>
              <td><%= p.getCreatedAt() != null ? p.getCreatedAt() : "N/A" %></td>
              <td class="btn-group">
                <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=approvePatient&patientId=<%= p.getPatientId() %>" 
                   class="btn btn-success btn-sm" 
                   onclick="return confirm('Approve medical aid for <%= p.getFullName() %>? This will approve all their appointments.')">
                  <i class="fas fa-check"></i> Approve
                </a>
                <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=rejectPatient&patientId=<%= p.getPatientId() %>" 
                   class="btn btn-danger btn-sm" 
                   onclick="return confirm('Reject medical aid for <%= p.getFullName() %>? This will reject all their appointments.')">
                  <i class="fas fa-times"></i> Reject
                </a>
              </td>
            </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>
  <% } %>

  <!-- Pending Appointments -->
  <div class="card">
    <div class="card-header">
      <h3><i class="fas fa-calendar-alt"></i> Pending Appointment Claims</h3>
      <span class="badge-pending"><%= pending.size() %> Pending</span>
    </div>
    <div class="table-wrapper">
      <% if (pending == null || pending.isEmpty() && pendingPatients.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-check-circle" style="font-size: 48px; color: #10b981; opacity: 0.5;"></i>
          <p style="margin-top: 16px;">No pending validations. All patients have been processed.</p>
          <p style="font-size: 14px; color: #64748b;">When patients register or book appointments, they will appear here.</p>
        </div>
      <% } else if (pending.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-check-circle" style="font-size: 48px; color: #10b981; opacity: 0.5;"></i>
          <p style="margin-top: 16px;">No pending appointment claims. All appointments have been processed.</p>
        </div>
      <% } else { %>
        <table class="data-table">
          <thead>
            <tr>
              <th>Appt #</th>
              <th>Date & Time</th>
              <th>Patient</th>
              <th>Medical Aid</th>
              <th>Member #</th>
              <th>Doctor</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% for (Appointment a : pending) { 
               if (a == null) continue;
               String memberNumber = "N/A"; 
               try { 
                 Patient p = patientDAO.getPatientById(a.getPatientId()); 
                 if (p != null && p.getMedicalAidNumber() != null) { 
                   memberNumber = p.getMedicalAidNumber(); 
                 } 
               } catch (Exception e) { 
                 memberNumber = "N/A"; 
               } 
            %>
              <tr class="pending-item">
                <td><strong>#<%= a.getAppointmentId() %></strong></td>
                <td><%= a.getAppointmentDate() != null ? a.getAppointmentDate() : "N/A" %> at <%= a.getAppointmentTime() != null ? a.getAppointmentTime() : "N/A" %></td>
                <td><strong><%= a.getPatientName() != null ? a.getPatientName() : "Unknown" %></strong></td>
                <td><%= a.getMedicalAidProvider() != null ? a.getMedicalAidProvider() : "Not set" %></td>
                <td><code><%= memberNumber %></code></td>
                <td><%= a.getDoctorName() != null ? a.getDoctorName() : "Unknown" %></td>
                <td class="btn-group">
                  <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=approve&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" 
                     class="btn btn-success btn-sm" onclick="return confirm('Approve this claim?')">
                    <i class="fas fa-check"></i> Approve
                  </a>
                  <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=reject&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" 
                     class="btn btn-danger btn-sm" onclick="return confirm('Reject this claim?')">
                    <i class="fas fa-times"></i> Reject
                  </a>
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </div>
  </div>

  <div class="info-box" style="margin-top: 24px;">
    <h4><i class="fas fa-info-circle"></i> How Validation Works</h4>
    <ul>
      <li><strong>Patient Registration:</strong> When patients register, they appear here for approval</li>
      <li><strong>Appointment Claims:</strong> When patients book appointments, claims appear here</li>
      <li><strong>Approve:</strong> Confirms medical aid coverage, patient can book appointments</li>
      <li><strong>Reject:</strong> Denies coverage, patient must update their details</li>
      <li><strong>Bulk Actions:</strong> Approving/Rejecting a patient affects all their appointments</li>
    </ul>
  </div>
</main>

<footer class="page-footer">
  &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>
</body>
</html>