<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="dao.MedicalAidDAO, model.MedicalAidProvider, java.util.List" %>
<%
    // Load medical aid providers for dropdown
    MedicalAidDAO medicalAidDAO = new MedicalAidDAO();
    List<MedicalAidProvider> existingProviders = medicalAidDAO.getAllProviders();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Account – IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .provider-options {
            margin-top: 10px;
            padding: 12px;
            background: #f8fafc;
            border-radius: 8px;
        }
        .radio-group {
            display: flex;
            gap: 20px;
            margin-bottom: 15px;
        }
        .radio-group label {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }
        .new-provider-field {
            margin-top: 10px;
            padding-left: 20px;
            border-left: 2px solid var(--primary);
        }
        .helper-text {
            font-size: 12px;
            color: #64748b;
            margin-top: 5px;
        }
        .helper-text i {
            margin-right: 5px;
        }
    </style>
</head>
<body>
<div class="auth-page">
    <a href="index.jsp" class="back-home">← Back to Home</a>
    
    <div class="auth-card" style="max-width: 560px;">
        <div class="auth-header">
            <div class="auth-logo">🏥 IHVS</div>
            <h1>Create Account</h1>
            <p>Join the Intelligent Health Validation System</p>
        </div>

        <div class="auth-body">
            <% String error = (String) request.getAttribute("error"); %>
            <% if (error != null) { %>
                <div class="alert alert-error">
                    <span class="alert-icon">✕</span>
                    <%= error %>
                </div>
            <% } %>

            <!-- Role Selection -->
            <div class="form-group">
                <label class="form-label" for="roleSelect">Select Account Type</label>
                <select class="form-control" id="roleSelect" name="role" form="regForm" required onchange="toggleFields()">
                    <option value="">-- Select Role --</option>
                    <option value="patient">🩺 Patient</option>
                    <option value="doctor">👨‍⚕️ Doctor</option>
                    <option value="admin">👑 Administrator</option>
                    <option value="medicalaid">🛡️ Medical Aid Provider</option>
                </select>
            </div>

            <form method="post" action="${pageContext.request.contextPath}/RegisterServlet" id="regForm">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="fullName">Full Name</label>
                        <input type="text" class="form-control" id="fullName" name="fullName" 
                               placeholder="e.g. Thabo Nkosi" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="username">Username</label>
                        <input type="text" class="form-control" id="username" name="username" 
                               placeholder="Choose a username" required>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="email">Email Address</label>
                        <input type="email" class="form-control" id="email" name="email" 
                               placeholder="you@example.com" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="phone">Phone Number</label>
                        <input type="tel" class="form-control" id="phone" name="phone" 
                               placeholder="e.g. 0821234567" required>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="password">Password</label>
                        <input type="password" class="form-control" id="password" name="password" 
                               placeholder="Min. 8 characters" required minlength="8">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="confirmPassword">Confirm Password</label>
                        <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" 
                               placeholder="Repeat password" required>
                    </div>
                </div>

                <!-- Doctor-only fields -->
                <div id="doctorFields" style="display:none;" class="doctor-fields">
                    <div class="form-group">
                        <label class="form-label" for="specialization">Specialization</label>
                        <select class="form-control" id="specialization" name="specialization">
                            <option value="">-- Select Specialization --</option>
                            <option value="General Practitioner">General Practitioner</option>
                            <option value="Cardiologist">Cardiologist</option>
                            <option value="Pediatrician">Pediatrician</option>
                            <option value="Dermatologist">Dermatologist</option>
                            <option value="Orthopedic">Orthopedic</option>
                            <option value="Neurologist">Neurologist</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="consultationFee">Consultation Fee (ZAR)</label>
                        <input type="number" class="form-control" id="consultationFee" name="consultationFee" 
                               placeholder="e.g. 500" min="0" step="0.01">
                    </div>
                </div>

                <!-- Medical Aid Provider-only fields - WITH OPTION TO ADD NEW PROVIDER -->
                <div id="medicalAidFields" style="display:none;" class="medicalaid-fields">
                    <div class="form-group">
                        <label class="form-label">Provider Selection</label>
                        <div class="radio-group">
                            <label>
                                <input type="radio" name="providerOption" value="existing" checked onchange="toggleProviderInput()">
                                Select existing provider
                            </label>
                            <label>
                                <input type="radio" name="providerOption" value="new" onchange="toggleProviderInput()">
                                Add new provider
                            </label>
                        </div>
                    </div>
                    
                    <!-- Existing Provider Dropdown -->
                    <div id="existingProviderDiv">
                        <label class="form-label" for="providerId">Select Medical Aid Provider</label>
                        <select class="form-control" id="providerId" name="providerId">
                            <option value="">-- Select Provider --</option>
                            <% if (existingProviders != null && !existingProviders.isEmpty()) {
                                for (MedicalAidProvider p : existingProviders) { 
                                    if (p.isActive()) { %>
                                        <option value="<%= p.getProviderId() %>">
                                            <%= p.getProviderName() %>
                                        </option>
                            <%      }
                                }
                            } else { %>
                                <option value="" disabled>No providers available. Add a new one below.</option>
                            <% } %>
                        </select>
                    </div>
                    
                    <!-- New Provider Input Field -->
                    <div id="newProviderDiv" style="display:none;">
                        <div class="new-provider-field">
                            <label class="form-label" for="newProviderName">
                                <i class="fas fa-plus-circle"></i> New Provider Name
                            </label>
                            <input type="text" class="form-control" id="newProviderName" name="newProviderName" 
                                   placeholder="e.g., Bongi, Sethu, Discovery">
                            <div class="helper-text">
                                <i class="fas fa-info-circle"></i> 
                                <strong>Note:</strong> " Health" will be automatically added to your provider name.
                                <br>Example: Enter "Bongi" → Provider will be saved as <strong>"Bongi Health"</strong>
                            </div>
                        </div>
                        
                        <div class="form-group" style="margin-top: 15px;">
                            <label class="form-label" for="contactPerson">Contact Person Name</label>
                            <input type="text" class="form-control" id="contactPerson" name="contactPerson" 
                                   placeholder="Your name as contact person">
                        </div>
                    </div>
                </div>

                <!-- Admin Info -->
                <div id="adminInfo" style="display:none;" class="info-box">
                    <p><strong>Note:</strong> Admin accounts require activation by system administrator.</p>
                </div>

                <div class="terms-checkbox">
                    <label class="checkbox-label">
                        <input type="checkbox" required> I agree to the <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a>
                    </label>
                </div>

                <button type="submit" class="btn btn-primary btn-full btn-lg">
                    Create Account →
                </button>
            </form>

            <div class="auth-divider">
                <span>Already have an account?</span>
            </div>

            <div class="auth-footer">
                <p><a href="login.jsp" class="auth-link">Sign in to your account</a></p>
            </div>
        </div>
    </div>
</div>

<script>
function toggleFields() {
    var role = document.getElementById('roleSelect').value;
    var doctorFields = document.getElementById('doctorFields');
    var medicalAidFields = document.getElementById('medicalAidFields');
    var adminInfo = document.getElementById('adminInfo');
    
    doctorFields.style.display = 'none';
    medicalAidFields.style.display = 'none';
    if (adminInfo) adminInfo.style.display = 'none';
    
    if (role === 'doctor') {
        doctorFields.style.display = 'block';
        document.getElementById('specialization').required = true;
        document.getElementById('consultationFee').required = true;
    } else {
        if (document.getElementById('specialization')) {
            document.getElementById('specialization').required = false;
        }
        if (document.getElementById('consultationFee')) {
            document.getElementById('consultationFee').required = false;
        }
    }
    
    if (role === 'medicalaid') {
        medicalAidFields.style.display = 'block';
        toggleProviderInput(); // Set proper required fields
        if (adminInfo) adminInfo.style.display = 'block';
    } else {
        if (document.getElementById('providerId')) {
            document.getElementById('providerId').required = false;
        }
        if (document.getElementById('newProviderName')) {
            document.getElementById('newProviderName').required = false;
        }
    }
    
    if (role === 'admin') {
        if (adminInfo) adminInfo.style.display = 'block';
    }
}

function toggleProviderInput() {
    var option = document.querySelector('input[name="providerOption"]:checked').value;
    var existingDiv = document.getElementById('existingProviderDiv');
    var newDiv = document.getElementById('newProviderDiv');
    var providerSelect = document.getElementById('providerId');
    var newProviderInput = document.getElementById('newProviderName');
    
    if (option === 'existing') {
        existingDiv.style.display = 'block';
        newDiv.style.display = 'none';
        providerSelect.required = true;
        newProviderInput.required = false;
    } else {
        existingDiv.style.display = 'none';
        newDiv.style.display = 'block';
        providerSelect.required = false;
        newProviderInput.required = true;
    }
}

document.getElementById('confirmPassword').addEventListener('input', function() {
    var password = document.getElementById('password').value;
    var confirm = this.value;
    
    if (confirm.length > 0) {
        this.setCustomValidity(password === confirm ? '' : 'Passwords do not match');
    }
});

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    toggleFields();
});
</script>
</body>
</html>