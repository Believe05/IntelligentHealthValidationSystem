<%@page import="java.util.List"%>
<%@page import="model.Doctor"%>
<%@page import="model.DoctorSchedule"%>
<%@page import="model.User"%>
<%@page import="dao.DoctorDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="model.Patient"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());
    
    String aidStatus = "pending";
    if (patient != null && "active".equals(patient.getMembershipStatus())) {
        aidStatus = "active";
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    List<Doctor> doctors = doctorDAO.getAllDoctors();
    
    java.util.Map<Integer, String> doctorScheduleMap = new java.util.HashMap<>();
    if (doctors != null) {
        for (Doctor d : doctors) {
            List<DoctorSchedule> schedule = doctorDAO.getDoctorSchedule(d.getDoctorId());
            if (schedule != null && !schedule.isEmpty()) {
                StringBuilder sb = new StringBuilder();
                for (DoctorSchedule ds : schedule) {
                    String start = ds.getStartTime();
                    String end = ds.getEndTime();
                    if (start != null && start.length() > 5) start = start.substring(0, 5);
                    if (end != null && end.length() > 5) end = end.substring(0, 5);
                    if (sb.length() > 0) sb.append("|");
                    sb.append(ds.getDayOfWeek()).append(":").append(start).append("-").append(end);
                }
                doctorScheduleMap.put(d.getDoctorId(), sb.toString());
            }
        }
    }
    
    String today = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    String firstName = "";
    if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
        firstName = user.getFullName().split(" ")[0];
    } else {
        firstName = "Patient";
    }
    
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Appointment | IHVS</title>
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
        </div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="bookAppointment.jsp" class="nav-item active"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user-circle"></i> Profile</a>
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
        <h1>Schedule New Appointment</h1>
        <p>Fill in the details below to book your visit with a specialist</p>
    </div>

    <% if (!"active".equals(aidStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            Your medical aid status is <strong><%= aidStatus %></strong>. 
            <a href="profile.jsp">Update your details here</a>
        </div>
    <% } %>

    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error">
            <i class="fas fa-times-circle"></i>
            <%= request.getParameter("error").replace("+", " ") %>
        </div>
    <% } %>

    <div class="booking-grid">
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-notes-medical"></i> Appointment Details</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/BookAppointmentServlet" method="post" id="appointmentForm" onsubmit="return validateBookingForm()">
                    <div class="form-group">
                        <label for="doctorId" class="form-label">Select Doctor</label>
                        <select id="doctorId" name="doctorId" class="form-control" required onchange="updateScheduleInfo()">
                            <option value="">— Choose a doctor —</option>
                            <% if (doctors != null) {
                                for (Doctor d : doctors) { %>
                                <option value="<%= d.getDoctorId() %>" data-schedule="<%= doctorScheduleMap.get(d.getDoctorId()) != null ? doctorScheduleMap.get(d.getDoctorId()) : "" %>">
                                    Dr. <%= d.getFullName() != null ? d.getFullName() : "Unknown" %> — <%= d.getSpecialization() != null ? d.getSpecialization() : "General" %> (R<%= String.format("%.0f", d.getConsultationFee()) %>)
                                </option>
                            <% } } %>
                        </select>
                    </div>

                    <div id="scheduleInfo" class="schedule-info" style="display:none;">
                        <strong><i class="fas fa-clock"></i> Doctor's Schedule:</strong>
                        <div id="scheduleDetails"></div>
                    </div>

                    <div class="form-row" style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                        <div class="form-group">
                            <label for="appointmentDate" class="form-label">Appointment Date</label>
                            <input type="date" id="appointmentDate" name="appointmentDate" class="form-control" min="<%= today %>" required>
                        </div>
                        <div class="form-group">
                            <label for="appointmentTime" class="form-label">Appointment Time</label>
                            <select id="appointmentTime" name="appointmentTime" class="form-control" required disabled>
                                <option value="">— Select doctor and date first —</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="notes" class="form-label">Symptoms / Reason for Visit</label>
                        <textarea id="notes" name="notes" class="form-control" rows="4" placeholder="Please describe your symptoms..." required></textarea>
                    </div>

                    <div class="btn-group" style="display: flex; gap: 12px; margin-top: 20px;">
                        <button type="submit" class="btn btn-primary" id="submitBtn"><i class="fas fa-check-circle"></i> Confirm Booking</button>
                        <a href="dashboard.jsp" class="btn btn-outline">Cancel</a>
                    </div>
                </form>
            </div>
        </div>

        <div>
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-shield-alt"></i> Medical Aid</h3>
                </div>
                <div class="card-body">
                    <div class="info-row"><span class="key">Provider</span><span class="val"><%= (patient != null && patient.getMedicalAidProvider() != null) ? patient.getMedicalAidProvider() : "Not set" %></span></div>
                    <div class="info-row"><span class="key">Status</span><span class="val"><span class="badge <%= "active".equals(aidStatus) ? "badge-active" : "badge-pending" %>"><%= aidStatus.toUpperCase() %></span></span></div>
                    <div class="info-row"><span class="key">Reliability Score</span><span class="val"><%= (patient != null) ? patient.getReliabilityScore() : 100 %>%</span></div>
                </div>
            </div>
            <div class="info-box">
                <h4><i class="fas fa-info-circle"></i> Important Notes</h4>
                <ul>
                    <li>Medical aid validated in background after booking</li>
                    <li>Reminders sent 24h & 1h before appointment</li>
                    <li>Cancellations must be at least 2 hours prior</li>
                    <li>Repeated no-shows reduce reliability score</li>
                </ul>
            </div>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System.
</footer>

<script>
    let doctorScheduleData = {};
    const contextPath = '<%= contextPath %>';
    
    // CLIENT-SIDE VALIDATION FUNCTION (Assessment 5 requirement)
    function validateBookingForm() {
        const doctorId = document.getElementById('doctorId').value;
        const appointmentDate = document.getElementById('appointmentDate').value;
        const appointmentTime = document.getElementById('appointmentTime').value;
        const notes = document.getElementById('notes').value;
        
        // Check if doctor selected
        if (!doctorId) {
            alert('Please select a doctor');
            return false;
        }
        
        // Check if date selected
        if (!appointmentDate) {
            alert('Please select an appointment date');
            return false;
        }
        
        // Check if date is not in the past
        const selectedDate = new Date(appointmentDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        if (selectedDate < today) {
            alert('Cannot book appointments in the past. Please select a future date.');
            return false;
        }
        
        // Check if time selected
        if (!appointmentTime) {
            alert('Please select an appointment time');
            return false;
        }
        
        // Check if notes/symptoms provided
        if (!notes || notes.trim().length < 10) {
            alert('Please provide a brief description of your symptoms (at least 10 characters)');
            return false;
        }
        
        // Check if medical aid status is active
        const aidStatus = '<%= aidStatus %>';
        if (aidStatus !== 'active') {
            alert('Your medical aid status is ' + aidStatus.toUpperCase() + '. Please update your medical aid details before booking.');
            return false;
        }
        
        return true;
    }
    
    function updateScheduleInfo() {
        const select = document.getElementById('doctorId');
        const selectedOption = select.options[select.selectedIndex];
        const scheduleData = selectedOption.getAttribute('data-schedule');
        const scheduleDiv = document.getElementById('scheduleInfo');
        const detailsDiv = document.getElementById('scheduleDetails');
        
        doctorScheduleData = {};
        
        if (scheduleData && scheduleData.length > 0) {
            const entries = scheduleData.split('|');
            let html = '<ul style="margin:0; padding-left:20px;">';
            
            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i];
                const firstColonIndex = entry.indexOf(':');
                if (firstColonIndex === -1) continue;
                
                const day = entry.substring(0, firstColonIndex);
                const timePart = entry.substring(firstColonIndex + 1);
                const times = timePart.split('-');
                
                if (times.length >= 2) {
                    let startTime = times[0].trim();
                    let endTime = times[1].trim();
                    html += '<li><strong>' + day + ':</strong> ' + startTime + ' - ' + endTime + '</li>';
                    doctorScheduleData[day] = { start: startTime, end: endTime };
                }
            }
            html += '</ul>';
            detailsDiv.innerHTML = html;
            scheduleDiv.style.display = 'block';
        } else {
            detailsDiv.innerHTML = '<p style="color:#92400e;">⚠️ No schedule set for this doctor yet.</p>';
            scheduleDiv.style.display = 'block';
        }
        
        document.getElementById('appointmentDate').value = '';
        document.getElementById('appointmentTime').innerHTML = '<option value="">— Select doctor and date first —</option>';
        document.getElementById('appointmentTime').disabled = true;
    }
    
    function checkAvailability() {
        const doctorId = document.getElementById('doctorId').value;
        const date = document.getElementById('appointmentDate').value;
        const timeSelect = document.getElementById('appointmentTime');
        
        if (!doctorId || !date) {
            timeSelect.innerHTML = '<option value="">— Select doctor and date first —</option>';
            timeSelect.disabled = true;
            return;
        }
        
        const selectedDate = new Date(date);
        const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayOfWeek = daysOfWeek[selectedDate.getDay()];
        
        if (!doctorScheduleData[dayOfWeek]) {
            timeSelect.innerHTML = '<option value="">❌ Doctor not available on ' + dayOfWeek + 's</option>';
            timeSelect.disabled = true;
            return;
        }
        
        timeSelect.disabled = false;
        timeSelect.innerHTML = '<option value="">Checking availability...</option>';
        
        const url = contextPath + '/CheckAvailabilityServlet?doctorId=' + doctorId + '&date=' + date;
        
        fetch(url)
            .then(function(response) {
                if (!response.ok) throw new Error('HTTP error! status: ' + response.status);
                return response.json();
            })
            .then(function(data) {
                const schedule = doctorScheduleData[dayOfWeek];
                if (!schedule) {
                    timeSelect.innerHTML = '<option value="">Doctor not available on this day</option>';
                    return;
                }
                
                let startTime = schedule.start;
                let endTime = schedule.end;
                
                let startHour = 9, startMinute = 0, endHour = 17, endMinute = 0;
                
                if (startTime && startTime.includes(':')) {
                    startHour = parseInt(startTime.split(':')[0]);
                    startMinute = parseInt(startTime.split(':')[1] || 0);
                }
                if (endTime && endTime.includes(':')) {
                    endHour = parseInt(endTime.split(':')[0]);
                    endMinute = parseInt(endTime.split(':')[1] || 0);
                }
                
                const allPossibleSlots = [];
                let currentHour = startHour;
                let currentMinute = startMinute;
                
                if (currentMinute > 0 && currentMinute < 30) currentMinute = 30;
                else if (currentMinute > 30) { currentHour++; currentMinute = 0; }
                
                let maxIterations = 100;
                let iterations = 0;
                
                while ((currentHour < endHour || (currentHour === endHour && currentMinute < endMinute)) && iterations < maxIterations) {
                    const timeString = (currentHour < 10 ? '0' + currentHour : currentHour) + ':' + (currentMinute < 10 ? '0' + currentMinute : currentMinute);
                    allPossibleSlots.push(timeString);
                    currentMinute += 30;
                    if (currentMinute >= 60) { currentHour++; currentMinute -= 60; }
                    iterations++;
                }
                
                let options = '<option value="">— Select time —</option>';
                for (var i = 0; i < allPossibleSlots.length; i++) {
                    var slot = allPossibleSlots[i];
                    if (data.availableSlots && data.availableSlots.indexOf(slot) !== -1) {
                        options += '<option value="' + slot + '">' + slot + '</option>';
                    } else if (data.availableSlots) {
                        options += '<option value="' + slot + '" disabled style="color:#999;">' + slot + ' (Booked)</option>';
                    }
                }
                timeSelect.innerHTML = options;
                timeSelect.disabled = false;
            })
            .catch(function(error) {
                console.error('Error:', error);
                timeSelect.disabled = false;
                timeSelect.innerHTML = '<option value="">Error loading times. Please refresh.</option>';
            });
    }
    
    document.getElementById('appointmentForm').addEventListener('submit', function(e) {
        const submitBtn = document.getElementById('submitBtn');
        if (submitBtn.disabled) {
            e.preventDefault();
            return;
        }
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    });
    
    document.addEventListener('DOMContentLoaded', function() {
        const dateInput = document.getElementById('appointmentDate');
        if (dateInput) dateInput.addEventListener('change', checkAvailability);
        
        const doctorSelect = document.getElementById('doctorId');
        if (doctorSelect) {
            doctorSelect.addEventListener('change', function() {
                const timeSelect = document.getElementById('appointmentTime');
                timeSelect.innerHTML = '<option value="">— Select date first —</option>';
                timeSelect.disabled = true;
                document.getElementById('appointmentDate').value = '';
            });
        }
    });
</script>
</body>
</html>