<%@page import="java.util.List"%>
<%@page import="model.Patient"%>
<%@page import="model.User"%>
<%@page import="dao.PatientDAO"%>
<%
    User admin = (User) session.getAttribute("user");
    if (admin == null || !"admin".equals(admin.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    PatientDAO patientDAO = new PatientDAO();
    List<Patient> patients = (List<Patient>) request.getAttribute("patients");
    if (patients == null) {
        patients = patientDAO.getAllPatients();
        if (patients != null) {
            patients.sort((p1, p2) -> Integer.compare(p1.getReliabilityScore(), p2.getReliabilityScore()));
        } else {
            patients = new java.util.ArrayList<>();
        }
    }
    
    int highRiskCount = 0;
    int mediumRiskCount = 0;
    int lowRiskCount = 0;
    int totalReliability = 0;
    
    if (patients != null) {
        for (Patient p : patients) {
            if (p == null) continue;
            int score = p.getReliabilityScore();
            totalReliability += score;
            if (score < 60) highRiskCount++;
            else if (score < 80) mediumRiskCount++;
            else lowRiskCount++;
        }
    }
    
    double avgReliability = (patients != null && patients.size() > 0) ? totalReliability * 1.0 / patients.size() : 0;
    String firstName = (admin.getFullName() != null && !admin.getFullName().trim().isEmpty()) 
        ? admin.getFullName().split(" ")[0] : "Admin";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Patient Reliability Report | IHVS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .risk-high { background: #fee2e2; color: #991b1b; }
        .risk-medium { background: #fed7aa; color: #92400e; }
        .risk-low { background: #d1fae5; color: #065f46; }
        .pri-excellent { color: #10b981; font-weight: bold; }
        .pri-good { color: #3b82f6; font-weight: bold; }
        .pri-average { color: #f59e0b; font-weight: bold; }
        .pri-poor { color: #ef4444; font-weight: bold; }
        .stats-summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        .risk-stat {
            background: white;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .risk-stat .value { font-size: 32px; font-weight: 700; }
        .risk-stat .label { font-size: 14px; color: #64748b; margin-top: 5px; }
        .export-buttons { display: flex; gap: 12px; margin-top: 20px; }
        .social-links { text-align: center; margin-top: 30px; padding: 20px; border-top: 1px solid #e2e8f0; }
        .social-links a { margin: 0 10px; font-size: 24px; }
        .table-wrapper { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th, .data-table td { padding: 10px; text-align: left; border-bottom: 1px solid #e2e8f0; }
        .data-table th { background: #f8fafc; font-weight: 600; }
        .badge { padding: 4px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; display: inline-block; }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item active"><i class="fas fa-chart-line"></i> Reports</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info"><div class="name"><%= admin.getFullName() != null ? admin.getFullName() : "Admin" %></div><div class="role">Admin</div></div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1><i class="fas fa-star"></i> Patient Reliability Report</h1>
        <p>Patient Reliability Index (PRI) scores and risk analysis</p>
    </div>
    
    <div class="stats-summary">
        <div class="risk-stat"><div class="value" style="color: #10b981;"><%= lowRiskCount %></div><div class="label">Low Risk (80-100 PRI)</div></div>
        <div class="risk-stat"><div class="value" style="color: #f59e0b;"><%= mediumRiskCount %></div><div class="label">Medium Risk (60-79 PRI)</div></div>
        <div class="risk-stat"><div class="value" style="color: #ef4444;"><%= highRiskCount %></div><div class="label">High Risk (&lt;60 PRI)</div></div>
        <div class="risk-stat"><div class="value"><%= String.format("%.1f", avgReliability) %>%</div><div class="label">Average PRI</div></div>
    </div>
    
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-chart-pie"></i> Risk Distribution</h3></div>
        <div class="card-body">
            <div style="max-width: 400px; margin: 0 auto;"><canvas id="riskChart"></canvas></div>
        </div>
    </div>
    
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-table"></i> Patient Reliability Details</h3>
            <div class="export-buttons">
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportPatientReliability&format=csv" class="btn btn-outline btn-sm"><i class="fas fa-file-csv"></i> Export CSV</a>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportPatientReliabilityPDF" class="btn btn-outline btn-sm"><i class="fas fa-file-pdf"></i> Export PDF</a>
            </div>
        </div>
        <div class="table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Patient Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Medical Aid</th>
                        <th>Total Appts</th>
                        <th>Completed</th>
                        <th>No-Shows</th>
                        <th>Cancelled</th>
                        <th>PRI Score</th>
                        <th>Risk Level</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (patients == null || patients.isEmpty()) { %>
                        <tr><td colspan="10" style="text-align:center; padding:40px;">No patient data available</td></tr>
                    <% } else { 
                        for (Patient p : patients) { 
                            if (p == null) continue;
                            int score = p.getReliabilityScore();
                            String riskClass = "";
                            String riskText = "";
                            String priClass = "";
                            if (score < 60) { 
                                riskClass = "risk-high"; 
                                riskText = "HIGH RISK"; 
                                priClass = "pri-poor"; 
                            } else if (score < 80) { 
                                riskClass = "risk-medium"; 
                                riskText = "MEDIUM RISK"; 
                                priClass = "pri-average"; 
                            } else { 
                                riskClass = "risk-low"; 
                                riskText = "LOW RISK"; 
                                priClass = (score >= 90) ? "pri-excellent" : "pri-good"; 
                            }
                            
                            String patientName = (p.getFullName() != null && !p.getFullName().trim().isEmpty()) ? p.getFullName() : "Unknown";
                            String email = (p.getEmail() != null) ? p.getEmail() : "N/A";
                            String phone = (p.getPhone() != null) ? p.getPhone() : "N/A";
                            String medAid = (p.getMedicalAidProvider() != null && !p.getMedicalAidProvider().trim().isEmpty()) ? p.getMedicalAidProvider() : "?";
                    %>
                        <tr>
                            <td><strong><%= patientName %></strong></td>
                            <td><%= email %></td>
                            <td><%= phone %></td>
                            <td><%= medAid %></td>
                            <td><%= p.getTotalAppointments() %></td>
                            <td><%= p.getCompletedCount() %></td>
                            <td style="color:#ef4444;"><%= p.getNoShowCount() %></td>
                            <td style="color:#f59e0b;"><%= p.getCancellationCount() %></td>
                            <td class="<%= priClass %>"><strong><%= score %>%</strong></td>
                            <td><span class="badge <%= riskClass %>"><%= riskText %></span></td>
                        </tr>
                    <% } 
                    } %>
                </tbody>
            </table>
        </div>
    </div>
    
    <div class="social-links">
        <h4>Follow IHVS</h4>
        <a href="#" style="color: #1877f2;"><i class="fab fa-facebook"></i></a>
        <a href="#" style="color: #1da1f2;"><i class="fab fa-twitter"></i></a>
        <a href="#" style="color: #0a66c2;"><i class="fab fa-linkedin"></i></a>
        <a href="#" style="color: #e4405f;"><i class="fab fa-instagram"></i></a>
        <a href="#" style="color: #ff0000;"><i class="fab fa-youtube"></i></a>
        <p style="margin-top: 15px; font-size: 12px; color: #64748b;">© 2026 Intelligent Health Validation System</p>
    </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
    const ctx = document.getElementById('riskChart').getContext('2d');
    new Chart(ctx, {
        type: 'pie',
        data: {
            labels: ['Low Risk (80-100)', 'Medium Risk (60-79)', 'High Risk (<60)'],
            datasets: [{ data: [<%= lowRiskCount %>, <%= mediumRiskCount %>, <%= highRiskCount %>], backgroundColor: ['#10b981', '#f59e0b', '#ef4444'] }]
        },
        options: { responsive: true, plugins: { legend: { position: 'bottom' } } }
    });
</script>
</body>
</html>