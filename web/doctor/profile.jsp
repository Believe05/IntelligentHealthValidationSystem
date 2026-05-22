<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Doctor, model.DoctorSchedule, dao.DoctorDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"doctor".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  DoctorDAO doctorDAO = new DoctorDAO();
  Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
  List<DoctorSchedule> schedule = null;
  
  if (doctor != null) {
      schedule = doctorDAO.getDoctorSchedule(doctor.getDoctorId());
  }
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Doctor Profile | IHVS</title>
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
      <a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
      <a href="schedule.jsp" class="nav-item"><i class="fas fa-clock"></i> Availability</a>
      <a href="profile.jsp" class="nav-item active"><i class="fas fa-user-md"></i> Profile</a>
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
    <h1>My Profile</h1>
    <p>Manage your professional information and availability</p>
  </div>

  <% String success = request.getParameter("success"); if(success != null){ %>
    <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= success.replace("+", " ") %></div>
  <% } %>
  <% String error = request.getParameter("error"); if(error != null){ %>
    <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= error.replace("+", " ") %></div>
  <% } %>

  <div class="profile-grid">
    <div class="card">
      <div class="card-header"><h3><i class="fas fa-user-edit"></i> Personal Information</h3></div>
      <div class="card-body">
        <form method="post" action="${pageContext.request.contextPath}/DoctorServlet" id="profileForm">
          <input type="hidden" name="action" value="updateProfile">
          <div class="form-group">
            <label class="form-label">Username</label>
            <input type="text" value="<%= user.getUsername() %>" class="form-control" disabled>
          </div>
          <div class="form-group">
            <label class="form-label" for="fullName">Full Name</label>
            <input type="text" id="fullName" name="fullName" value="<%= user.getFullName() %>" required class="form-control">
          </div>
          <div class="form-group">
            <label class="form-label" for="email">Email</label>
            <input type="email" id="email" name="email" value="<%= user.getEmail() %>" required class="form-control">
          </div>
          <div class="form-group">
            <label class="form-label" for="phone">Phone</label>
            <input type="tel" id="phone" name="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>" class="form-control">
          </div>
          <% if (doctor != null) { %>
          <div class="form-group">
            <label class="form-label" for="specialization">Specialization</label>
            <input type="text" id="specialization" name="specialization" value="<%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "" %>" class="form-control" placeholder="e.g., Cardiologist">
          </div>
          <div class="form-group">
            <label class="form-label" for="qualification">Qualification</label>
            <input type="text" id="qualification" name="qualification" value="<%= doctor.getQualification() != null ? doctor.getQualification() : "" %>" class="form-control" placeholder="e.g., MBChB">
          </div>
          <div class="form-group">
            <label class="form-label" for="consultationFee">Consultation Fee (ZAR)</label>
            <input type="number" id="consultationFee" name="consultationFee" value="<%= doctor.getConsultationFee() %>" step="0.01" min="0" class="form-control">
          </div>
          <% } %>
          <button type="submit" class="btn btn-primary" id="saveProfileBtn"><i class="fas fa-save"></i> Save Changes</button>
        </form>
      </div>
    </div>

    <div>
      <div class="card">
        <div class="card-header"><h3><i class="fas fa-id-card"></i> Account Details</h3></div>
        <div class="card-body">
          <div class="info-row"><span class="key">Role</span><span class="val">Doctor</span></div>
          <div class="info-row"><span class="key">Account Status</span><span class="val"><span class="badge badge-active">Active</span></span></div>
          <div class="info-row"><span class="key">Member Since</span><span class="val"><%= user.getCreatedAt() != null ? user.getCreatedAt() : "N/A" %></span></div>
        </div>
      </div>

      <% if (doctor != null) { %>
      <div class="card" style="margin-top:24px;">
        <div class="card-header"><h3><i class="fas fa-clock"></i> Current Schedule</h3></div>
        <div class="card-body">
          <% if (schedule == null || schedule.isEmpty()) { %>
            <p class="text-center" style="color:var(--text-muted); padding:20px;">No schedule set.</p>
          <% } else { 
            for (DoctorSchedule ds : schedule) { %>
              <div class="info-row">
                <span class="key"><strong><%= ds.getDayOfWeek() %></strong></span>
                <span class="val"><%= ds.getStartTime() %> - <%= ds.getEndTime() %></span>
              </div>
          <% } } %>
          <div style="margin-top:16px;">
            <a href="schedule.jsp" class="btn btn-outline btn-sm"><i class="fas fa-edit"></i> Manage Schedule</a>
          </div>
        </div>
      </div>
      <% } %>
    </div>
  </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
  // Prevent double form submission
  document.getElementById('profileForm').addEventListener('submit', function(e) {
    const submitBtn = document.getElementById('saveProfileBtn');
    if (submitBtn.disabled) {
      e.preventDefault();
      return;
    }
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
  });
</script>
</body>
</html>