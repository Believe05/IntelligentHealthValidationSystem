<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Appointment, dao.AppointmentDAO, java.util.List, java.util.Collections, java.util.Comparator" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"admin".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  AppointmentDAO apptDAO = new AppointmentDAO();
  List<Appointment> appointments = apptDAO.getAllAppointments();
  
  // Sort appointments by date (newest first)
  if (appointments != null && !appointments.isEmpty()) {
    Collections.sort(appointments, new Comparator<Appointment>() {
      @Override
      public int compare(Appointment a1, Appointment a2) {
        // Sort by date descending (newest first), then by time
        String date1 = a1.getAppointmentDate();
        String date2 = a2.getAppointmentDate();
        if (date1 == null && date2 == null) return 0;
        if (date1 == null) return 1;
        if (date2 == null) return -1;
        return date2.compareTo(date1);
      }
    });
  }
  
  // Calculate statistics
  int totalAppointments = appointments != null ? appointments.size() : 0;
  int completedCount = 0;
  int cancelledCount = 0;
  int pendingCount = 0;
  int confirmedCount = 0;
  int noShowCount = 0;
  
  for (Appointment a : appointments) {
    String status = a.getStatus();
    if ("completed".equals(status)) completedCount++;
    else if ("cancelled".equals(status)) cancelledCount++;
    else if ("pending".equals(status)) pendingCount++;
    else if ("confirmed".equals(status)) confirmedCount++;
    else if ("no-show".equals(status)) noShowCount++;
  }
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>All Appointments | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <style>
    .stats-summary {
      display: flex;
      gap: 15px;
      margin-bottom: 20px;
      flex-wrap: wrap;
    }
    .stat-chip {
      background: white;
      padding: 8px 16px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 500;
      box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }
    .stat-chip i {
      margin-right: 6px;
    }
    .stat-chip.total { background: #2563eb; color: white; }
    .stat-chip.completed { background: #10b981; color: white; }
    .stat-chip.cancelled { background: #ef4444; color: white; }
    .stat-chip.pending { background: #f59e0b; color: white; }
    .stat-chip.confirmed { background: #3b82f6; color: white; }
    .stat-chip.no-show { background: #8b5cf6; color: white; }
    
    .table-container {
      overflow-x: auto;
      border-radius: 12px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }
    th {
      background: #f8fafc;
      padding: 12px 10px;
      text-align: left;
      font-weight: 600;
      color: #1e293b;
      border-bottom: 2px solid #e2e8f0;
    }
    td {
      padding: 10px;
      border-bottom: 1px solid #e2e8f0;
      vertical-align: middle;
    }
    tr:hover {
      background: #f8fafc;
    }
    .text-center {
      text-align: center;
    }
    .search-box {
      position: relative;
      max-width: 350px;
    }
    .search-box i {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      color: #94a3b8;
    }
    .search-box input {
      padding-left: 36px;
    }
    .badge {
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 600;
      display: inline-block;
    }
    .badge-completed { background: #d1fae5; color: #065f46; }
    .badge-cancelled { background: #fee2e2; color: #991b1b; }
    .badge-pending { background: #fed7aa; color: #92400e; }
    .badge-confirmed { background: #dbeafe; color: #1e40af; }
    .badge-no-show { background: #fef3c7; color: #92400e; }
    .badge-active, .badge-approved { background: #d1fae5; color: #065f46; }
    .badge-rejected { background: #fee2e2; color: #991b1b; }
    
    .btn-sm {
      padding: 4px 10px;
      font-size: 11px;
    }
    .patient-name {
      font-weight: 600;
      color: #1e293b;
    }
    .doctor-name {
      color: #475569;
    }
    .med-aid {
      font-size: 12px;
      color: #64748b;
    }
    .pri-score {
      font-weight: 700;
      text-align: center;
    }
    .pri-high { color: #10b981; }
    .pri-medium { color: #f59e0b; }
    .pri-low { color: #ef4444; }
    
    @media (max-width: 768px) {
      th, td { padding: 8px 6px; font-size: 12px; }
    }
  </style>
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links">
      <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
      <a href="users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
      <a href="appointments.jsp" class="nav-item active"><i class="fas fa-calendar-alt"></i> Appointments</a>
      <a href="reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a>
      <a href="settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a>
      <a href="providers.jsp" class="nav-item"><i class="fas fa-shield-alt"></i> Medical Aid</a>
    </div>
    <div class="user-menu">
      <div class="user-avatar"><%= firstName.charAt(0) %></div>
      <div class="user-info">
        <div class="name"><%= user.getFullName() %></div>
        <div class="role">Admin</div>
      </div>
      <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
    </div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header">
    <h1><i class="fas fa-calendar-alt"></i> All Appointments</h1>
    <p>Manage and monitor all patient appointments across the system</p>
  </div>

  <!-- Statistics Summary -->
  <div class="stats-summary">
    <div class="stat-chip total"><i class="fas fa-chart-line"></i> Total: <%= totalAppointments %></div>
    <div class="stat-chip completed"><i class="fas fa-check-circle"></i> Completed: <%= completedCount %></div>
    <div class="stat-chip confirmed"><i class="fas fa-check"></i> Confirmed: <%= confirmedCount %></div>
    <div class="stat-chip pending"><i class="fas fa-clock"></i> Pending: <%= pendingCount %></div>
    <div class="stat-chip cancelled"><i class="fas fa-times-circle"></i> Cancelled: <%= cancelledCount %></div>
    <div class="stat-chip no-show"><i class="fas fa-user-slash"></i> No-Show: <%= noShowCount %></div>
  </div>

  <!-- Search Box -->
  <div class="card" style="margin-bottom: 20px;">
    <div class="card-body">
      <div class="search-box">
        <i class="fas fa-search"></i>
        <input type="text" id="filterInput" placeholder="Search by patient, doctor, medical aid, or status..." class="form-control" onkeyup="filterTable()">
      </div>
    </div>
  </div>

  <!-- Appointments Table -->
  <div class="card">
    <div class="card-header">
      <h3><i class="fas fa-list-ul"></i> Appointment Records</h3>
      <span class="badge badge-active"><%= totalAppointments %> Records</span>
    </div>
    <div class="table-container">
      <table id="apptTable">
        <thead>
          <tr>
            <th>#ID</th>
            <th>Date</th>
            <th>Time</th>
            <th>Patient</th>
            <th>Doctor</th>
            <th>Medical Aid</th>
            <th>PRI</th>
            <th>Status</th>
            <th>Validation</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <% if (appointments == null || appointments.isEmpty()) { %>
            <tr class="text-center">
              <td colspan="10" style="padding: 60px; text-align: center;">
                <i class="fas fa-calendar-times" style="font-size: 48px; opacity: 0.5;"></i>
                <p style="margin-top: 16px;">No appointments found.</p>
              </td>
            </tr>
          <% } else { 
            for (Appointment a : appointments) { 
              String patientName = a.getPatientName() != null ? a.getPatientName() : "Unknown";
              String doctorName = a.getDoctorName() != null ? a.getDoctorName() : "Unknown";
              String medAid = a.getMedicalAidProvider() != null && !a.getMedicalAidProvider().isEmpty() ? a.getMedicalAidProvider() : "—";
              String status = a.getStatus() != null ? a.getStatus() : "pending";
              String validationStatus = a.getValidationStatus() != null ? a.getValidationStatus() : "pending";
              int pri = a.getReliabilityScore();
              
              // PRI color class
              String priClass = "pri-high";
              if (pri < 60) priClass = "pri-low";
              else if (pri < 80) priClass = "pri-medium";
          %>
            <tr>
              <td style="font-weight: 600; color: #64748b;">#<%= a.getAppointmentId() %></td>
              <td><%= a.getAppointmentDate() != null ? a.getAppointmentDate() : "—" %></td>
              <td><%= a.getAppointmentTime() != null ? a.getAppointmentTime() : "—" %></td>
              <td class="patient-name"><%= patientName %></td>
              <td class="doctor-name"><%= doctorName %></td>
              <td class="med-aid"><%= medAid %></td>
              <td class="pri-score <%= priClass %>"><%= pri %>%</td>
              <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
              <td><span class="badge badge-<%= "active".equals(validationStatus) || "approved".equals(validationStatus) ? "active" : validationStatus %>"><%= validationStatus.toUpperCase() %></span></td>
              <td class="btn-group">
                <% if (!"cancelled".equals(status) && !"completed".equals(status) && !"no-show".equals(status)) { %>
                  <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= a.getAppointmentId() %>&action=cancel" 
                     class="btn btn-danger btn-sm" 
                     onclick="return confirm('Cancel this appointment?')">
                    <i class="fas fa-times"></i> Cancel
                  </a>
                <% } else { %>
                  <span style="font-size: 11px; color: #94a3b8;">—</span>
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
function filterTable() {
  var input = document.getElementById('filterInput');
  var filter = input.value.toLowerCase();
  var rows = document.querySelectorAll('#apptTable tbody tr');
  
  rows.forEach(function(row) {
    if (row.querySelector('td[colspan]')) return;
    var text = row.textContent.toLowerCase();
    row.style.display = text.includes(filter) ? '' : 'none';
  });
}
</script>
</body>
</html>