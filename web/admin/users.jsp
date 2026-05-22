<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page import="model.Patient"%>
<%@page import="dao.UserDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    UserDAO userDAO = new UserDAO();
    List<User> users = userDAO.getAllUsers();
    
    // Calculate active and inactive counts
    int activeCount = 0;
    int inactiveCount = 0;
    for (User u : users) {
        if (u.isActive()) {
            activeCount++;
        } else {
            inactiveCount++;
        }
    }

    PatientDAO patientDAO = new PatientDAO();
    java.util.Map<Integer, String> patientStatus = new java.util.HashMap<>();
    
    for (User u : users) {
        if ("patient".equals(u.getRole()) && u.isActive()) {
            Patient p = patientDAO.getPatientByUserId(u.getUserId());
            if (p != null) {
                String status = (p.getMedicalAidProvider() != null && p.getMedicalAidNumber() != null 
                    && !p.getMedicalAidProvider().trim().isEmpty() && !p.getMedicalAidNumber().trim().isEmpty()) 
                    ? "active" : "pending";
                patientStatus.put(u.getUserId(), status);
            }
        }
    }

    int pendingCount = 0;
    for (java.util.Map.Entry<Integer, String> entry : patientStatus.entrySet()) {
        if ("pending".equals(entry.getValue())) {
            pendingCount++;
        }
    }
    
    String firstName = admin.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .edit-panel {
            display: none;
            margin-top: 32px;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .action-buttons {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }
        
        .btn-sm {
            padding: 5px 12px;
            font-size: 0.75rem;
        }
        
        .badge-deactivated {
            background: #f0f0f0;
            color: #8b8b8b;
        }
        
        .badge-pending {
            background: #fed7aa;
            color: #92400e;
        }
        
        .delete-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            justify-content: center;
            align-items: center;
            z-index: 1000;
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .delete-modal-content {
            background: white;
            border-radius: var(--radius-lg);
            width: 500px;
            max-width: 90%;
            box-shadow: var(--shadow-xl);
            animation: slideUp 0.3s ease;
        }
        
        @keyframes slideUp {
            from { transform: translateY(30px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        .delete-modal-header {
            padding: 20px 24px;
            background: var(--danger-light);
            border-bottom: 1px solid var(--border-light);
            border-radius: var(--radius-lg) var(--radius-lg) 0 0;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .delete-modal-header i {
            font-size: 24px;
            color: var(--danger);
        }
        
        .delete-modal-header h3 {
            margin: 0;
            color: var(--danger);
            font-size: 1.2rem;
        }
        
        .delete-modal-body {
            padding: 24px;
        }
        
        .delete-modal-footer {
            padding: 16px 24px;
            border-top: 1px solid var(--border-light);
            display: flex;
            justify-content: flex-end;
            gap: 12px;
        }
        
        .warning-text {
            color: var(--danger);
            font-weight: bold;
        }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item active"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a>
            <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= admin.getFullName() %></div>
                <div class="role">Administrator</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Manage Users</h1>
        <p><%= activeCount %> active, <%= inactiveCount %> deactivated - <%= users.size() %> total registered accounts in the system</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error") %></div>
    <% } %>

    <% if (pendingCount > 0) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            <strong><%= pendingCount %></strong> patient(s) have pending medical aid information.
        </div>
    <% } %>

    <!-- Users Table -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-users"></i> All System Users</h3>
            <span class="badge badge-active"><%= activeCount %> Active</span>
        </div>
        <div class="table-wrapper">
            <table id="usersTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Full Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (User u : users) { 
                        String statusText = patientStatus.containsKey(u.getUserId()) ? patientStatus.get(u.getUserId()) : "—";
                        boolean isPending = "patient".equals(u.getRole()) && "pending".equals(statusText);
                        boolean isActiveUser = u.isActive();
                    %>
                    <tr>
                        <td><%= u.getUserId() %></td>
                        <td><%= u.getUsername() %></td>
                        <td><strong><%= u.getFullName() %></strong></td>
                        <td><%= u.getEmail() %></td>
                        <td><%= u.getPhone() != null ? u.getPhone() : "—" %></td>
                        <td><span class="badge badge-active"><%= u.getRole() %></span></td>
                        <td>
                            <% if ("patient".equals(u.getRole()) && isActiveUser) { %>
                                <span class="badge <%= isPending ? "badge-pending" : "badge-active" %>">
                                    <%= statusText %>
                                </span>
                            <% } else if (isActiveUser) { %>
                                <span class="badge badge-active">active</span>
                            <% } else { %>
                                <span class="badge badge-deactivated">deactivated</span>
                            <% } %>
                        </td>
                        <td>
                            <div class="action-buttons">
                                <% if (isActiveUser) { %>
                                    <button class="btn btn-outline btn-sm" onclick='openEditForm(<%= u.getUserId() %>, "<%= u.getFullName().replace("\"", "\\\"") %>", "<%= u.getEmail() %>", "<%= u.getPhone() != null ? u.getPhone().replace("\"", "\\\"") : "" %>")'>
                                        <i class="fas fa-edit"></i> Edit
                                    </button>
                                <% } %>
                                <% if (isPending && isActiveUser) { %>
                                    <a href="${pageContext.request.contextPath}/AdminServlet?action=validatePatient&userId=<%= u.getUserId() %>"
                                       class="btn btn-success btn-sm">Validate</a>
                                <% } %>
                                <% if (isActiveUser) { %>
                                    <!-- FIXED: Changed action from 'deactivateUser' to 'deleteUser' (no permanent param = soft deactivate) -->
                                    <a href="${pageContext.request.contextPath}/AdminServlet?action=deleteUser&userId=<%= u.getUserId() %>"
                                       class="btn btn-warning btn-sm" onclick="return confirmDeactivate('<%= u.getFullName().replace("\"", "\\\"") %>')">Deactivate</a>
                                <% } else { %>
                                    <a href="${pageContext.request.contextPath}/AdminServlet?action=activateUser&userId=<%= u.getUserId() %>"
                                       class="btn btn-success btn-sm" onclick="return confirmActivate('<%= u.getFullName().replace("\"", "\\\"") %>')">Activate</a>
                                <% } %>
                                <button class="btn btn-danger btn-sm" onclick="openDeleteModal(<%= u.getUserId() %>, '<%= u.getFullName().replace("\"", "\\\"") %>', '<%= u.getRole() %>')">
                                    <i class="fas fa-trash"></i> Delete
                                </button>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Edit User Panel -->
    <div id="editPanel" class="edit-panel">
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-user-edit"></i> Edit User</h3>
                <button onclick="closeEditForm()" class="btn btn-outline btn-sm"><i class="fas fa-times"></i> Close</button>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/AdminServlet" method="post">
                    <input type="hidden" name="action" value="updateUser">
                    <input type="hidden" id="editUserId" name="userId">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label" for="editFullName">Full Name</label>
                            <input class="form-control" type="text" id="editFullName" name="fullName" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="editEmail">Email Address</label>
                            <input class="form-control" type="email" id="editEmail" name="email" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label" for="editPhone">Phone Number</label>
                        <input class="form-control" type="tel" id="editPhone" name="phone">
                    </div>

                    <div class="btn-group">
                        <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                        <button type="button" onclick="closeEditForm()" class="btn btn-outline">Cancel</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</main>

<!-- Delete Confirmation Modal -->
<div id="deleteModal" class="delete-modal">
    <div class="delete-modal-content">
        <div class="delete-modal-header">
            <i class="fas fa-exclamation-triangle"></i>
            <h3>Permanently Delete User</h3>
        </div>
        <div class="delete-modal-body">
            <p>You are about to permanently delete <strong id="deleteUserName"></strong> (<span id="deleteUserRole"></span>).</p>
            <div class="alert alert-warning" style="margin: 16px 0;">
                <i class="fas fa-exclamation-triangle"></i> <strong>Warning:</strong> This action cannot be undone!
            </div>
            <p><strong>This will permanently delete:</strong></p>
            <ul style="margin-left: 20px; margin-bottom: 16px;">
                <li>The user account</li>
                <li>All appointments (past and future)</li>
                <li>All medical aid validation records</li>
                <li>All reminder history</li>
                <li>All audit log entries</li>
            </ul>
            <p class="warning-text">Are you absolutely sure you want to proceed?</p>
        </div>
        <div class="delete-modal-footer">
            <button onclick="closeDeleteModal()" class="btn btn-outline">Cancel</button>
            <button onclick="confirmDelete()" class="btn btn-danger"><i class="fas fa-trash"></i> Yes, Delete Permanently</button>
        </div>
    </div>
</div>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System.</footer>

<script>
    let currentDeleteUserId = null;
    let currentDeleteUserName = '';
    let currentDeleteUserRole = '';
    
    function openEditForm(userId, fullName, email, phone) {
        document.getElementById('editUserId').value = userId;
        document.getElementById('editFullName').value = fullName;
        document.getElementById('editEmail').value = email;
        document.getElementById('editPhone').value = phone || '';
        document.getElementById('editPanel').style.display = 'block';
        document.getElementById('editPanel').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    
    function closeEditForm() {
        document.getElementById('editPanel').style.display = 'none';
    }
    
    function confirmDeactivate(userName) {
        return confirm('Are you sure you want to deactivate ' + userName + '?\n\nThe user will not be able to log in, but their data will be preserved.\n\nYou can reactivate them later.');
    }
    
    function confirmActivate(userName) {
        return confirm('Are you sure you want to activate ' + userName + '?\n\nThe user will be able to log in again.');
    }
    
    function openDeleteModal(userId, userName, userRole) {
        currentDeleteUserId = userId;
        currentDeleteUserName = userName;
        currentDeleteUserRole = userRole;
        
        document.getElementById('deleteUserName').textContent = userName;
        document.getElementById('deleteUserRole').textContent = userRole;
        document.getElementById('deleteModal').style.display = 'flex';
    }
    
    function closeDeleteModal() {
        document.getElementById('deleteModal').style.display = 'none';
        currentDeleteUserId = null;
    }
    
    function confirmDelete() {
        if (currentDeleteUserId) {
            window.location.href = '${pageContext.request.contextPath}/AdminServlet?action=deleteUser&userId=' + currentDeleteUserId + '&permanent=true';
        }
        closeDeleteModal();
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('deleteModal');
        if (event.target === modal) {
            closeDeleteModal();
        }
    }
</script>
</body>
</html>