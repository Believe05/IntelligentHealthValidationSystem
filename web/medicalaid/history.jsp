<%@page import="model.User"%>
<%@page import="model.MedicalAidProvider"%>
<%@page import="model.Patient"%>
<%@page import="model.Appointment"%>
<%@page import="dao.MedicalAidDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"medicalaid".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  MedicalAidDAO medDAO = new MedicalAidDAO();
  PatientDAO patientDAO = new PatientDAO();
  AppointmentDAO appointmentDAO = new AppointmentDAO();
  
  MedicalAidProvider provider = medDAO.getProviderByUserId(user.getUserId());
  String providerName = (provider != null && provider.getProviderName() != null) ? provider.getProviderName() : "";
  
  if (providerName.isEmpty() && user.getFullName() != null) {
      providerName = user.getFullName();
      if (!providerName.endsWith("Health")) {
          providerName = providerName + " Health";
      }
  }
  
  // Collections for different types
  List<Object[]> historyRecords = new ArrayList<>();
  
  if (providerName != null && !providerName.isEmpty()) {
      try {
          // Get all patients for this provider
          List<Patient> allPatients = patientDAO.getPatientsByProvider(providerName);
          if (allPatients != null) {
              for (Patient p : allPatients) {
                  if (p == null) continue;
                  Object[] record = new Object[6];
                  record[0] = p.getLastValidation() != null ? p.getLastValidation() : p.getCreatedAt();
                  record[1] = p.getFullName();
                  record[2] = p.getMedicalAidNumber();
                  record[3] = p.getMedicalAidProvider();
                  record[4] = "Patient Registration";
                  record[5] = p.getMembershipStatus();
                  historyRecords.add(record);
              }
          }
          
          // Get all appointments for this provider
          List<Appointment> allApps = appointmentDAO.getAllAppointments();
          if (allApps != null) {
              for (Appointment apt : allApps) {
                  if (apt == null) continue;
                  String medAidProvider = apt.getMedicalAidProvider();
                  if (medAidProvider != null && medAidProvider.equalsIgnoreCase(providerName)) {
                      Object[] record = new Object[6];
                      record[0] = apt.getValidationTimestamp() != null ? apt.getValidationTimestamp() : apt.getCreatedAt();
                      record[1] = apt.getPatientName();
                      record[2] = "--";
                      record[3] = apt.getMedicalAidProvider();
                      record[4] = "Appointment Claim";
                      record[5] = apt.getValidationStatus();
                      historyRecords.add(record);
                  }
              }
          }
      } catch (Exception e) {
          System.err.println("Error: " + e.getMessage());
      }
  }
  
  // Sort by date (newest first)
  historyRecords.sort((a, b) -> {
      String dateA = (String) a[0];
      String dateB = (String) b[0];
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
  });
  
  int approvedCount = 0;
  int rejectedCount = 0;
  int pendingCount = 0;
  
  for (Object[] record : historyRecords) {
      String status = (String) record[5];
      if (status == null) status = "pending";
      if ("active".equals(status) || "approved".equals(status)) {
          approvedCount++;
      } else if ("rejected".equals(status)) {
          rejectedCount++;
      } else {
          pendingCount++;
      }
  }
  
  String firstName = "";
  if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
      firstName = user.getFullName().split(" ")[0];
  } else {
      firstName = "Provider";
  }
  
  String displayProviderName = providerName != null && !providerName.isEmpty() ? providerName : "Medical Aid Provider";
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Validation History | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <style>
    * {
        box-sizing: border-box;
    }
    body {
        margin: 0;
        padding: 0;
        font-family: 'Inter', sans-serif;
        background: #f5f7fb;
    }
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
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
    .filter-buttons {
        display: flex;
        gap: 10px;
        margin-bottom: 20px;
        flex-wrap: wrap;
    }
    .btn-filter {
        background: white;
        border: 1px solid #e2e8f0;
        padding: 8px 16px;
        border-radius: 8px;
        cursor: pointer;
        font-family: inherit;
        font-size: 14px;
        transition: all 0.2s;
    }
    .btn-filter:hover {
        background: #f1f5f9;
    }
    .btn-filter.active {
        background: #2563eb;
        color: white;
        border-color: #2563eb;
    }
    .card {
        background: white;
        border-radius: 12px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        margin-bottom: 24px;
        overflow: hidden;
    }
    .card-header {
        padding: 16px 20px;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
    }
    .card-header h3 {
        margin: 0;
        font-size: 18px;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .table-wrapper {
        overflow-x: auto;
        padding: 0;
    }
    .history-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 14px;
    }
    .history-table th {
        background: #f8fafc;
        padding: 14px 12px;
        text-align: left;
        font-weight: 600;
        color: #1e293b;
        border-bottom: 2px solid #e2e8f0;
    }
    .history-table td {
        padding: 12px;
        text-align: left;
        border-bottom: 1px solid #e2e8f0;
        vertical-align: middle;
    }
    .history-table tr:hover {
        background: #f8fafc;
    }
    .badge-approved {
        background: #d1fae5;
        color: #065f46;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 600;
        display: inline-block;
    }
    .badge-rejected {
        background: #fee2e2;
        color: #991b1b;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 600;
        display: inline-block;
    }
    .badge-pending {
        background: #fed7aa;
        color: #92400e;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 600;
        display: inline-block;
    }
    .empty-state {
        text-align: center;
        padding: 60px;
        color: #64748b;
    }
    .empty-state i {
        font-size: 48px;
        opacity: 0.5;
        margin-bottom: 16px;
    }
    .info-box {
        background: #f8fafc;
        padding: 20px;
        border-radius: 12px;
        margin-top: 24px;
    }
    .info-box h4 {
        margin-top: 0;
        margin-bottom: 12px;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .info-box ul {
        margin: 0;
        padding-left: 20px;
    }
    .info-box li {
        margin: 8px 0;
        color: #475569;
    }
    .page-footer {
        text-align: center;
        padding: 20px;
        color: #64748b;
        font-size: 13px;
        border-top: 1px solid #e2e8f0;
        margin-top: 30px;
    }
    .top-nav {
        background: white;
        border-bottom: 1px solid #e2e8f0;
        padding: 0 24px;
        position: sticky;
        top: 0;
        z-index: 100;
    }
    .nav-container {
        max-width: 1400px;
        margin: 0 auto;
        display: flex;
        justify-content: space-between;
        align-items: center;
        height: 70px;
    }
    .logo-area {
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .logo-icon {
        font-size: 28px;
        color: #2563eb;
    }
    .brand-name {
        font-size: 22px;
        font-weight: 700;
        color: #1e293b;
    }
    .brand-tagline {
        font-size: 12px;
        color: #64748b;
    }
    .nav-links {
        display: flex;
        gap: 8px;
    }
    .nav-item {
        padding: 8px 16px;
        text-decoration: none;
        color: #64748b;
        border-radius: 8px;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .nav-item:hover {
        background: #f1f5f9;
        color: #2563eb;
    }
    .nav-item.active {
        background: #2563eb;
        color: white;
    }
    .user-menu {
        display: flex;
        align-items: center;
        gap: 16px;
    }
    .user-avatar {
        width: 40px;
        height: 40px;
        background: #2563eb;
        color: white;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 600;
        font-size: 18px;
    }
    .user-info .name {
        font-weight: 600;
        font-size: 14px;
    }
    .user-info .role {
        font-size: 12px;
        color: #64748b;
    }
    .main-content {
        max-width: 1400px;
        margin: 0 auto;
        padding: 32px 24px;
    }
    .page-header {
        margin-bottom: 32px;
    }
    .page-header h1 {
        margin: 0 0 8px 0;
        font-size: 28px;
    }
    .page-header p {
        margin: 0;
        color: #64748b;
    }
    .alert {
        padding: 12px 16px;
        border-radius: 8px;
        margin-bottom: 20px;
        display: flex;
        align-items: center;
        gap: 10px;
    }
    .alert-success {
        background: #d1fae5;
        color: #065f46;
    }
    .alert-error {
        background: #fee2e2;
        color: #991b1b;
    }
    @media (max-width: 768px) {
        .nav-links { display: none; }
        .stats-grid { grid-template-columns: 1fr; }
        .history-table { min-width: 700px; }
        .main-content { padding: 20px 16px; }
        .page-header h1 { font-size: 24px; }
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
      <a href="${pageContext.request.contextPath}/medicalaid/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
      <a href="${pageContext.request.contextPath}/medicalaid/validations.jsp" class="nav-item"><i class="fas fa-check-circle"></i> Validations</a>
      <a href="${pageContext.request.contextPath}/medicalaid/history.jsp" class="nav-item active"><i class="fas fa-history"></i> History</a>
    </div>
    <div class="user-menu">
      <div class="user-avatar"><%= firstName.charAt(0) %></div>
      <div class="user-info">
        <div class="name"><%= user.getFullName() != null ? user.getFullName() : "Provider" %></div>
        <div class="role">Medical Aid - <%= displayProviderName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
    </div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header">
    <h1><i class="fas fa-history"></i> Validation History</h1>
    <p><%= displayProviderName %> - Complete record of all patient validations</p>
  </div>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="value" style="color: #10b981;"><%= approvedCount %></div>
      <div class="label">Approved</div>
    </div>
    <div class="stat-card">
      <div class="value" style="color: #ef4444;"><%= rejectedCount %></div>
      <div class="label">Rejected</div>
    </div>
    <div class="stat-card">
      <div class="value" style="color: #3b82f6;"><%= historyRecords.size() %></div>
      <div class="label">Total Processed</div>
    </div>
  </div>

  <div class="filter-buttons">
    <button class="btn-filter active" onclick="filterTable('all')">Show All</button>
    <button class="btn-filter" onclick="filterTable('approved')">Show Approved Only</button>
    <button class="btn-filter" onclick="filterTable('rejected')">Show Rejected Only</button>
    <button class="btn-filter" onclick="filterTable('pending')">Show Pending Only</button>
  </div>

  <div class="card">
    <div class="card-header">
      <h3><i class="fas fa-list"></i> All Validations (<%= historyRecords.size() %>)</h3>
    </div>
    <div class="table-wrapper">
      <% if (historyRecords.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-history"></i>
          <p>No validation history yet.</p>
          <p style="font-size: 14px;">When you approve or reject patient requests, they will appear here.</p>
        </div>
      <% } else { %>
        <table class="history-table" id="historyTable">
          <thead>
            <tr>
              <th>Date & Time</th>
              <th>Patient Name</th>
              <th>Member #</th>
              <th>Provider</th>
              <th>Type</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            <% for (Object[] record : historyRecords) { 
                String dateTime = (String) record[0];
                String patientName = (String) record[1];
                String memberNumber = (String) record[2];
                String provName = (String) record[3];
                String type = (String) record[4];
                String status = (String) record[5];
                
                String badgeClass = "badge-pending";
                if ("active".equals(status) || "approved".equals(status)) {
                    badgeClass = "badge-approved";
                } else if ("rejected".equals(status)) {
                    badgeClass = "badge-rejected";
                }
                
                String displayStatus = "PENDING";
                if ("active".equals(status) || "approved".equals(status)) {
                    displayStatus = "APPROVED";
                } else if ("rejected".equals(status)) {
                    displayStatus = "REJECTED";
                }
            %>
              <tr data-status="<%= displayStatus.toLowerCase() %>">
                <td><%= dateTime != null ? dateTime : "N/A" %></td>
                <td><strong><%= patientName != null ? patientName : "Unknown" %></strong></td>
                <td><%= memberNumber != null ? memberNumber : "—" %></td>
                <td><%= provName != null ? provName : "—" %></td>
                <td><%= type %></td>
                <td><span class="<%= badgeClass %>"><%= displayStatus %></span></td>
              </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </div>
  </div>

  <div class="info-box">
    <h4><i class="fas fa-info-circle"></i> About Validation History</h4>
    <ul>
      <li><strong>Patient Registration</strong> - When patients register with your medical aid</li>
      <li><strong>Appointment Claim</strong> - When patients book appointments under your coverage</li>
      <li><strong>Approved</strong> - Medical aid verified and accepted</li>
      <li><strong>Rejected</strong> - Medical aid verification failed</li>
      <li><strong>Pending</strong> - Awaiting your review and decision</li>
    </ul>
  </div>
</main>

<footer class="page-footer">
  &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>

<script>
function filterTable(status) {
  const rows = document.querySelectorAll('#historyTable tbody tr');
  const buttons = document.querySelectorAll('.btn-filter');
  
  buttons.forEach(btn => btn.classList.remove('active'));
  
  if (status === 'all') {
    buttons[0].classList.add('active');
  } else if (status === 'approved') {
    buttons[1].classList.add('active');
  } else if (status === 'rejected') {
    buttons[2].classList.add('active');
  } else if (status === 'pending') {
    buttons[3].classList.add('active');
  }
  
  rows.forEach(row => {
    if (status === 'all') {
      row.style.display = '';
    } else {
      const rowStatus = row.getAttribute('data-status');
      row.style.display = rowStatus === status ? '' : 'none';
    }
  });
}
</script>
</body>
</html>