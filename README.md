IHVS - Intelligent Health Validation System
A comprehensive healthcare management platform for streamlining medical aid validation, appointment scheduling, and patient reliability tracking.

https://img.shields.io/badge/Java-11%252B-orange.svg
https://img.shields.io/badge/GlassFish-5.0%252B-blue.svg
https://img.shields.io/badge/Apache%2520Derby-10.15%252B-green.svg
https://img.shields.io/badge/License-Academic%2520Use-yellow.svg

📋 Table of Contents
Project Overview

Key Features

System Architecture

Technology Stack

Installation Guide

Database Setup

Live Demo Credentials

Security Features

Project Structure

Test Cases

Screenshots

Contributing

License

🏥 Project Overview
IHVS (Intelligent Health Validation System) is a web-based healthcare platform designed specifically for small-to-medium clinics in South Africa. It addresses critical operational challenges:

❌ Problem: Fragmented systems causing missed appointments, rejected medical aid claims, and revenue loss

✅ Solution: Integrated platform with real-time eligibility validation, automated reminders, and analytics

🎯 Core Objectives
Objective	Description
Reduce No-Shows	Automated reminders + Patient Reliability Index (PRI)
Prevent Claim Rejections	Real-time medical aid validation before booking
Improve Efficiency	Role-based dashboards for all stakeholders
Enhance Visibility	Analytics and performance metrics
👥 User Roles
Role	Description	Key Capabilities
👤 Patient	End-users seeking healthcare	Book/cancel appointments, view history, track reliability score
👨‍⚕️ Doctor	Healthcare providers	Manage availability, view appointments, track no-show stats
🛡️ Medical Aid	Insurance providers	Validate patient claims, approve/reject memberships
👑 Admin	System administrators	Full oversight, user management, reports, system settings
✨ Key Features
1. 🔐 Role-Based Authentication & Security
Secure registration with password hashing (BCrypt)

Role-based access control (RBAC)

15-minute session timeout with inactivity monitoring

Activity logging and audit trails

2. 📅 Intelligent Appointment Booking
Real-time doctor availability checking

Medical aid eligibility validation before confirmation

Automatic status tracking: Pending → Confirmed → Completed/No-show

Validation timestamp and outcome recording

3. 🔄 Appointment Lifecycle Management
text
Pending → Confirmed → Completed
  ↓          ↓
Cancelled   No-Show
Complete traceability of every appointment state change.

4. ⏰ Automated Reminder Engine
24-hour pre-appointment notification

1-hour pre-appointment notification

Reduces no-show rates through structured tracking

5. ⭐ Patient Reliability Index (PRI) - Innovation Component
Dynamic scoring based on:

Attendance history

Cancellation frequency

No-show percentage

Applications:

Identification of high-risk patients

Analytical reporting

Future integration with penalty/prioritization systems

6. 📊 Comprehensive Dashboards
Admin: User management, appointment trends, validation success rates, no-show percentages, revenue risk indicators

Doctor: Upcoming appointments, attendance marking, no-show statistics, patient reliability indicators

Patient: Personal health overview, appointment history, reliability score, medical aid status

Medical Aid: Pending validations, member approvals/rejections, utilization metrics

🏗️ System Architecture
Layered MVC Architecture
text
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION TIER                        │
│              (JSP, HTML, CSS, JavaScript)                   │
│   • Role-specific dashboards                                │
│   • Client-side validation                                  │
│   • Chart.js visualizations                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CONTROLLER TIER                          │
│              (Servlets, Filters)                            │
│   • Request handling & routing                              │
│   • Session management                                      │
│   • Authentication & authorization                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC TIER                      │
│              (Services, Business Rules)                     │
│   • Medical aid validation logic                            │
│   • PRI calculation engine                                  │
│   • Reminder scheduling                                     │
│   • Audit logging                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA TIER                             │
│                   (DAO, JDBC, MySQL)                        │
│   • Prepared Statements (SQL injection protection)          │
│   • Connection pooling                                      │
│   • Transaction management                                  │
└─────────────────────────────────────────────────────────────┘
Technology Stack
Layer	Technology	Version	Purpose
Backend	Java (Servlets & JSP)	11+	Core programming
MVC Architecture	-	Design pattern
Application Server	GlassFish	5.0 / 6.0+	Servlet container
Database	MySQL / Apache Derby	8.0+ / 10.15+	Relational database
Frontend	HTML5, CSS3, JavaScript	-	UI rendering
Security	jBCrypt	0.4	Password hashing
Charts	Chart.js	3.x	Data visualization
Reports	iTextPDF	5.x	PDF export
Version Control	Git	-	Source control
🚀 Installation Guide
Prerequisites
text
☐ Java JDK 11 or higher
☐ GlassFish 5.0 / 6.0+ Application Server
☐ MySQL 8.0+ or Apache Derby 10.15+
☐ Internet connection (for CDN libraries)
☐ Git (for cloning)
Step 1: Clone Repository
bash
git clone https://github.com/yourusername/IHVS.git
cd IHVS
Step 2: Install & Configure Database
Option A: MySQL (Recommended)
sql
-- Create database
CREATE DATABASE ihvs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Import schema and sample data
mysql -u root -p ihvs < database/database_scripts.sql
Option B: Apache Derby
bash
# Download Derby from https://db.apache.org/derby/
# Start Derby Network Server
java -jar derbyrun.jar server start

# Create database and run scripts
connect 'jdbc:derby://localhost:1527/IHVS;create=true';
run 'database/database_scripts.sql';
Step 3: Configure Database Connection
Update src/util/DBConnection.java:

java
// For MySQL
private static final String URL = "jdbc:mysql://localhost:3306/ihvs";
private static final String USERNAME = "root";
private static final String PASSWORD = "your_password";

// For Derby
private static final String URL = "jdbc:derby://localhost:1527/IHVS";
private static final String USERNAME = "app";
private static final String PASSWORD = "123";
Step 4: Deploy to GlassFish
bash
# Option A: Build WAR file
jar -cvf IHVS.war *

# Option B: Deploy via Admin Console
# 1. Open http://localhost:4848
# 2. Go to Applications → Deploy
# 3. Upload IHVS.war
# 4. Context Root: /IHVS

# Option C: Deploy via Command Line
asadmin deploy --contextroot IHVS IHVS.war

# Option D: Copy to Autodeploy
cp IHVS.war $GLASSFISH_HOME/domains/domain1/autodeploy/
Step 5: Configure GlassFish JNDI Resource
Via Admin Console (http://localhost:4848):

Navigate to Resources → JDBC → Connection Pools

Create new pool with name: DerbyPool or MySQLPool

Add JDBC Resource with JNDI Name: jdbc/IHVS

Alternative: Using sun-resources.xml:

xml
<resources>
    <jdbc-connection-pool 
        name="DerbyPool" 
        res-type="javax.sql.DataSource">
        <property name="URL" value="jdbc:derby://localhost:1527/IHVS"/>
        <property name="User" value="app"/>
        <property name="Password" value="123"/>
    </jdbc-connection-pool>
    <jdbc-resource 
        jndi-name="jdbc/IHVS" 
        pool-name="DerbyPool"/>
</resources>
Step 6: Start GlassFish & Access
bash
# Start GlassFish
$GLASSFISH_HOME/bin/asadmin start-domain

# Verify deployment
$GLASSFISH_HOME/bin/asadmin list-applications

# Access the system
http://localhost:8080/IHVS
🗄️ Database Schema
Core Tables
Table	Description	Key Fields
users	All user accounts	user_id, username, password_hash, role, is_active
patients	Patient profiles	patient_id, user_id, medical_aid_provider, reliability_score
doctors	Doctor profiles	doctor_id, user_id, specialization, consultation_fee
appointments	All appointments	appointment_id, patient_id, doctor_id, date, time, status
doctor_schedule	Doctor availability	schedule_id, doctor_id, day_of_week, start_time, end_time
reminders	Automated reminders	reminder_id, appointment_id, type, scheduled_time, status
audit_log	Security audit trail	log_id, user_id, action, details, ip_address, log_time
validation_log	Medical aid history	validation_id, patient_id, provider_name, validation_result

Entity Relationship Diagram
text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     users       │     │    patients     │     │    doctors      │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ PK user_id      │◄─── │ FK user_id      │     │ PK doctor_id   │
│    username     │     │ PK patient_id   │     │ FK user_id      │
│    password_hash│     │ reliability_scr │     │ specialization  │
│    full_name    │     │ membership_stat │     └────────┬────────┘
│    email        │     └─────────────────┘              │
│    role         │            │                         │
│    is_active    │            │                         │
└─────────────────┘            │                         │
         │                      │                         │
         │              ┌───────▼────────┐         ┌──────▼─────────┐
         │              │  appointments  │         │ doctor_schedule│
         │              ├────────────────┤         ├────────────────┤
         └─────────────►│ PK appointment │         │ PK schedule_id │
                        │ FK patient_id   │         │ FK doctor_id   │
                        │ FK doctor_id    │         │ day_of_week    │
                        │ appointment_date│         │ start_time     │
                        │ appointment_time│         │ end_time       │
                        │ validation_stat │         └────────────────┘
                        │ cancellation_rsn│
                        └─────────────────┘
🔑 Live Demo Credentials
Role	Username	Password	Purpose
👑 Admin	admin	admin123	Full system access
👨‍⚕️ Doctor	dr.smith	doctor123	Manage appointments
👤 Patient	nolwazi	patient123	Book appointments
🛡️ Medical Aid	sfiso	med123	Validate claims
⚠️ Note: Demo credentials are for testing purposes only. Change all default passwords in production.

🔐 Security Features
Feature	Implementation	Description
Password Hashing	jBCrypt (work factor 12)	PasswordUtil.java
Session Management	15-minute timeout	LoginServlet.java
Role-Based Access	AuthenticationFilter	URL pattern restrictions
Audit Logging	Asynchronous executor	AuditLogger.java
SQL Injection Protection	PreparedStatement	All DAO classes
Input Validation	Client + Server-side	JSP validation + Servlets
Error Handling	Custom error pages	error404.jsp, error500.jsp
📁 Project Structure
text
IHVS/
├── src/
│   ├── controller/           # Servlets
│   │   ├── LoginServlet.java
│   │   ├── RegisterServlet.java
│   │   ├── AdminServlet.java
│   │   ├── DoctorServlet.java
│   │   ├── PatientServlet.java
│   │   ├── MedicalAidServlet.java
│   │   ├── BookAppointmentServlet.java
│   │   ├── UpdateAppointmentServlet.java
│   │   ├── CheckAvailabilityServlet.java
│   │   └── ReminderServlet.java
│   │
│   ├── dao/                  # Data Access Objects
│   │   ├── UserDAO.java
│   │   ├── PatientDAO.java
│   │   ├── DoctorDAO.java
│   │   ├── AppointmentDAO.java
│   │   ├── MedicalAidDAO.java
│   │   ├── ReminderDAO.java
│   │   ├── AuditLogDAO.java
│   │   └── AdminDAO.java
│   │
│   ├── model/                # Entity Models
│   │   ├── User.java
│   │   ├── Patient.java
│   │   ├── Doctor.java
│   │   ├── Appointment.java
│   │   ├── MedicalAidProvider.java
│   │   ├── DoctorSchedule.java
│   │   ├── Reminder.java
│   │   ├── AuditLog.java
│   │   └── ValidationLog.java
│   │
│   ├── filter/               # Filters
│   │   ├── AuthenticationFilter.java
│   │   └── CharacterEncodingFilter.java
│   │
│   ├── listener/             # Listeners
│   │   └── ReminderScheduler.java
│   │
│   └── util/                 # Utilities
│       ├── DBConnection.java
│       ├── PasswordUtil.java
│       └── AuditLogger.java
│
├── web/
│   ├── WEB-INF/
│   │   ├── web.xml
│   │   └── lib/              # JAR dependencies
│   │
│   ├── css/
│   │   └── style.css
│   │
│   ├── admin/                # Admin pages
│   │   ├── dashboard.jsp
│   │   ├── users.jsp
│   │   └── reports.jsp
│   │
│   ├── doctor/               # Doctor pages
│   │   ├── dashboard.jsp
│   │   └── manageAppointments.jsp
│   │
│   ├── patient/              # Patient pages
│   │   ├── dashboard.jsp
│   │   └── bookAppointment.jsp
│   │
│   ├── medicalaid/           # Medical Aid pages
│   │   └── dashboard.jsp
│   │
│   ├── index.jsp
│   ├── login.jsp
│   └── register.jsp
│
└── database/
    └── database_scripts.sql
🧪 Test Cases
Test ID	Test Case	Steps	Expected Result
TC-01	Patient Registration	Fill registration form → Submit	Account created, redirect to login
TC-02	Valid Login	Enter credentials → Submit	Redirect to role dashboard
TC-03	Invalid Login	Wrong password → Submit	Error message displayed
TC-04	Book Appointment	Select doctor → Pick date/time → Submit	Appointment created, reminder scheduled
TC-05	Medical Aid Validation	Login as Medical Aid → Approve patient	Patient active, appointments approved
TC-06	Doctor Confirms Appointment	Login as Doctor → Click Confirm	Status changes to confirmed
TC-07	Export Report (CSV)	Go to Reports → Click Export CSV	CSV file downloads
TC-08	Role-Based Access	Access admin page as patient	403 Forbidden or redirect
TC-09	PRI Score Update	Mark patient as no-show	Reliability score decreases by 10
📸 Screenshots
1. Homepage
Landing page showcasing IHVS features and statistics

2. Admin Dashboard - User Management
Admin panel showing all system users with role-based controls

Key Features Visible:

✅ 17 active users, 1 deactivated

✅ Roles: Admin, Doctor, Patient, Medical Aid

✅ Edit, Deactivate, Delete actions

3. Admin Reports
Comprehensive reporting dashboard with monthly statistics

Reports Available:

📊 Doctor Performance

📊 Medical Aid Utilization

📊 Patient Reliability (PRI scores)

📊 Monthly Statistics with KPIs

Export Options: CSV Export | PDF Export

4. Doctor Dashboard
Doctor's view showing appointments and validation status

Features:

📅 Recent appointments

👤 Patient information

✅ Medical aid validation status

🔄 Appointment actions (Confirm, Cancel, Complete)

5. Medical Aid Dashboard
Interface for validating patient claims

Features:

📊 Pending validations count

✅ Approved members

❌ Rejected members

⚡ Approve/Reject actions

6. Patient Dashboard
Personal health overview and appointment management

Features:

⭐ Reliability Score (100%)

📅 Total Appointments

📈 Upcoming Appointments

✅ Medical Aid Status (ACTIVE)

📊 Non-Functional Requirements
Category	Requirement	Target
Performance	Booking response time	≤ 3 seconds
Eligibility check	≤ 5 seconds
Dashboard load	≤ 5 seconds
Concurrent users	Support 200
Availability	Uptime (working hours)	95%
Database backups	Daily
Security	Session timeout	15 minutes
Password hashing	BCrypt
Audit logging	Enabled
Reliability	No duplicate bookings	Enforced
Real-time updates	Immediate

🤝 Contributing
Fork the repository

Create your feature branch: git checkout -b feature/amazing-feature

Commit your changes: git commit -m 'Add some amazing feature'

Push to the branch: git push origin feature/amazing-feature

Open a Pull Request

Development Guidelines
Follow MVC architecture patterns

Use PreparedStatement for all database queries

Implement comprehensive error handling

Write meaningful commit messages

Update documentation for new features

📄 License
This project is for academic purposes. All rights reserved © 2026 A-Team, University of South Africa.

📞 Contact & Support
Project Manager: B.B. Magagule

Developer Team: N. Mchunu, M.P. Khumalo, S.S. Mnisi, G. Mmeia, M. Mampholo

Course: Software Project Assessment 1

Institution: Tshwane University of Technology

🏆 Acknowledgements

Open-source community for essential libraries

📌 Quick Links
Live Demo (Local deployment)

GlassFish Documentation

Apache Derby Documentation

📝 Change Log
Version	Date	Changes
1.0	2026-06-18	Initial release - Complete system implementation
1.1	2026-06-20	Added reminder engine and PRI calculations
1.2	2026-06-25	Implemented reports and analytics dashboard

✨ Key Differentiators
What makes IHVS unique:

Integrated Validation - Real-time medical aid checking before booking

Patient Reliability Index - Behavioral scoring system

South African Healthcare Focus - Designed for local clinic needs

Academic-Grade Architecture - MVC with comprehensive security

Complete Traceability - Audit logs for all actions

Built with ❤️ for the South African healthcare community




