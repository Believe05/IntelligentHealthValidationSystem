<%@page import="dao.MedicalAidDAO"%>
<%@page import="model.MedicalAidProvider"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    MedicalAidDAO medicalAidDAO = new MedicalAidDAO();
    List<MedicalAidProvider> providers = medicalAidDAO.getAllProviders();
    
    String firstName = admin.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Medical Aid Providers | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .providers-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }
        
        .provider-list {
            max-height: 500px;
            overflow-y: auto;
        }
        
        .provider-item {
            padding: 12px;
            border-bottom: 1px solid var(--border);
            cursor: pointer;
            transition: background 0.2s;
        }
        
        .provider-item:hover {
            background: var(--bg-hover);
        }
        
        .provider-item.selected {
            background: #dbeafe;
            border-left: 3px solid var(--primary);
        }
        
        .form-card {
            position: sticky;
            top: 20px;
        }
        
        @media (max-width: 768px) {
            .providers-grid {
                grid-template-columns: 1fr;
            }
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
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="providers.jsp" class="nav-item active"><i class="fas fa-shield-alt"></i> Medical Aid</a>
            <a href="reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a>
            <a href="settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a>
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
        <h1>Medical Aid Providers</h1>
        <p>Manage medical aid providers for patient registration</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error") %></div>
    <% } %>

    <div class="providers-grid">
        <!-- Left: List of Providers -->
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-list"></i> Existing Providers</h3>
                <span class="badge badge-active"><%= providers.size() %> Active</span>
            </div>
            <div class="card-body provider-list">
                <% if (providers.isEmpty()) { %>
                    <p class="text-center" style="padding: 40px; color: var(--text-muted);">
                        <i class="fas fa-database" style="font-size: 48px; opacity: 0.5;"></i><br>
                        No medical aid providers found.<br>
                        Use the form to add one.
                    </p>
                <% } else { 
                    for (MedicalAidProvider p : providers) { %>
                        <div class="provider-item" onclick="selectProvider(<%= p.getProviderId() %>, '<%= p.getProviderName() %>', '<%= p.getContactPerson() != null ? p.getContactPerson() : "" %>', '<%= p.getEmail() != null ? p.getEmail() : "" %>', '<%= p.getPhone() != null ? p.getPhone() : "" %>', <%= p.isActive() %>)">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <strong><%= p.getProviderName() %></strong>
                                <span class="badge <%= p.isActive() ? "badge-active" : "badge-pending" %>">
                                    <%= p.isActive() ? "Active" : "Inactive" %>
                                </span>
                            </div>
                            <div style="font-size: 12px; color: var(--text-muted); margin-top: 5px;">
                                <%= p.getEmail() != null ? p.getEmail() : "No email" %> | 
                                <%= p.getPhone() != null ? p.getPhone() : "No phone" %>
                            </div>
                        </div>
                <% } } %>
            </div>
        </div>

        <!-- Right: Add/Edit Form -->
        <div class="card form-card">
            <div class="card-header">
                <h3 id="formTitle"><i class="fas fa-plus-circle"></i> Add New Provider</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/AdminServlet" method="post" id="providerForm">
                    <input type="hidden" name="action" id="formAction" value="createProvider">
                    <input type="hidden" name="providerId" id="providerId" value="">
                    
                    <div class="form-group">
                        <label class="form-label" for="providerName">Provider Name *</label>
                        <input type="text" class="form-control" id="providerName" name="providerName" required>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label" for="contactPerson">Contact Person</label>
                        <input type="text" class="form-control" id="contactPerson" name="contactPerson">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label" for="email">Email Address</label>
                        <input type="email" class="form-control" id="email" name="email">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label" for="phone">Phone Number</label>
                        <input type="tel" class="form-control" id="phone" name="phone">
                    </div>
                    
                    <div class="form-group" id="activeField" style="display: none;">
                        <label class="checkbox-label">
                            <input type="checkbox" name="isActive" id="isActive"> Active
                        </label>
                    </div>
                    
                    <div class="btn-group" style="display: flex; gap: 12px; margin-top: 20px;">
                        <button type="submit" class="btn btn-primary" id="submitBtn">
                            <i class="fas fa-save"></i> Create Provider
                        </button>
                        <button type="button" class="btn btn-outline" onclick="resetForm()">
                            <i class="fas fa-undo"></i> Clear
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.
</footer>

<script>
    function selectProvider(id, name, contactPerson, email, phone, isActive) {
        document.getElementById('formAction').value = 'updateProvider';
        document.getElementById('providerId').value = id;
        document.getElementById('providerName').value = name;
        document.getElementById('contactPerson').value = contactPerson;
        document.getElementById('email').value = email;
        document.getElementById('phone').value = phone;
        document.getElementById('isActive').checked = isActive === true || isActive === 'true';
        
        document.getElementById('activeField').style.display = 'block';
        document.getElementById('formTitle').innerHTML = '<i class="fas fa-edit"></i> Edit Provider';
        document.getElementById('submitBtn').innerHTML = '<i class="fas fa-save"></i> Update Provider';
        
        // Scroll to form
        document.querySelector('.form-card').scrollIntoView({ behavior: 'smooth' });
        
        // Highlight selected
        document.querySelectorAll('.provider-item').forEach(item => {
            item.classList.remove('selected');
        });
        event.currentTarget.classList.add('selected');
    }
    
    function resetForm() {
        document.getElementById('formAction').value = 'createProvider';
        document.getElementById('providerId').value = '';
        document.getElementById('providerName').value = '';
        document.getElementById('contactPerson').value = '';
        document.getElementById('email').value = '';
        document.getElementById('phone').value = '';
        document.getElementById('isActive').checked = false;
        
        document.getElementById('activeField').style.display = 'none';
        document.getElementById('formTitle').innerHTML = '<i class="fas fa-plus-circle"></i> Add New Provider';
        document.getElementById('submitBtn').innerHTML = '<i class="fas fa-save"></i> Create Provider';
        
        document.querySelectorAll('.provider-item').forEach(item => {
            item.classList.remove('selected');
        });
    }
</script>
</body>
</html>