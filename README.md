# IHVS - Intelligent Health Validation System

A comprehensive healthcare management platform for streamlining medical aid validation, appointment scheduling, and patient reliability tracking.

![Java](https://img.shields.io/badge/Java-11%2B-orange.svg)
![GlassFish](https://img.shields.io/badge/GlassFish-5.0%2B-blue.svg)
![Apache Derby](https://img.shields.io/badge/Apache%20Derby-10.15%2B-green.svg)
![License](https://img.shields.io/badge/License-Academic%20Use-yellow.svg)

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Key Features](#-key-features)
- [System Architecture](#%EF%B8%8F-system-architecture)
- [Technology Stack](#technology-stack)
- [Installation Guide](#-installation-guide)
- [Database Schema](#%EF%B8%8F-database-schema)
- [Live Demo Credentials](#-live-demo-credentials)
- [Security Features](#-security-features)
- [Project Structure](#-project-structure)
- [Test Cases](#-test-cases)
- [Non-Functional Requirements](#-non-functional-requirements)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact & Support](#-contact--support)

---

## 🏥 Project Overview

**IHVS (Intelligent Health Validation System)** is a web-based healthcare platform designed specifically for small-to-medium clinics in South Africa. It addresses critical operational challenges:

* **❌ Problem:** Fragmented systems causing missed appointments, rejected medical aid claims, and revenue loss.
* **✅ Solution:** An integrated platform with real-time eligibility validation, automated reminders, and analytics.

### 🎯 Core Objectives

| Objective | Description |
| :--- | :--- |
| **Reduce No-Shows** | Automated reminders + Patient Reliability Index (PRI) |
| **Prevent Claim Rejections** | Real-time medical aid validation before booking |
| **Improve Efficiency** | Role-based dashboards for all stakeholders |
| **Enhance Visibility** | Analytics and performance metrics |

### 👥 User Roles

| Role | Description | Key Capabilities |
| :--- | :--- | :--- |
| **👤 Patient** | End-users seeking healthcare | Book/cancel appointments, view history, track reliability score |
| **👨‍⚕️ Doctor** | Healthcare providers | Manage availability, view appointments, track no-show stats |
| **🛡️ Medical Aid** | Insurance providers | Validate patient claims, approve/reject memberships |
| **👑 Admin** | System administrators | Full oversight, user management, reports, system settings |

---

## ✨ Key Features

### 1. 🔐 Role-Based Authentication & Security
* Secure registration with password hashing via BCrypt.
* Role-Based Access Control (RBAC).
* 15-minute session timeout with inactivity monitoring.
* Activity logging and audit trails.

### 2. 📅 Intelligent Appointment Booking
* Real-time doctor availability checking.
* Medical aid eligibility validation before confirmation.
* Automatic status tracking: `Pending` → `Confirmed` → `Completed`/`No-show`.
* Validation timestamp and outcome recording.

### 3. 🔄 Appointment Lifecycle Management

Pending ──> Confirmed ──> Completed
   │           │
   ▼           ▼
Cancelled   No-Show


### 4. ⏰ Automated Reminder Engine24-hour pre-appointment notification.1-hour pre-appointment notification.Reduces no-show rates through structured tracking.5. ⭐ Patient Reliability Index (PRI) - Innovation ComponentDynamic behavioral scoring based on:Attendance historyCancellation frequencyNo-show percentageApplications: Identification of high-risk patients, analytical reporting, and future integration with penalty/prioritization systems.6. 📊 Comprehensive DashboardsAdmin: User management, appointment trends, validation success rates, no-show percentages, revenue risk indicators.Doctor: Upcoming appointments, attendance marking, no-show statistics, patient reliability indicators.Patient: Personal health overview, appointment history, reliability score, medical aid status.Medical Aid: Pending validations, member approvals/rejections, utilization metrics.

###🏗️ System ArchitectureLayered MVC Architecture:
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

###Technology Stack

Layer,Technology,Version,Purpose
Backend,Java (Servlets & JSP),11+,Core programming
MVC Architecture,Design Pattern,-,Separation of concerns
Application Server,GlassFish,5.0 / 6.0+,Servlet container
Database,MySQL / Apache Derby,8.0+ / 10.15+,Relational database
Frontend,"HTML5, CSS3, JavaScript",-,UI rendering
Security,jBCrypt,0.4,Password hashing
Charts,Chart.js,3.x,Data visualization
Reports,iTextPDF,5.x,PDF export
Version Control,Git,-,Source control

🚀 Installation Guide
Prerequisites
[ ] Java JDK 11 or higher

[ ] GlassFish 5.0 / 6.0+ Application Server

[ ] MySQL 8.0+ or Apache Derby 10.15+

[ ] Internet connection (for CDN libraries)

[ ] Git (for cloning)

Step 1: Clone Repository
Bash
git clone [https://github.com/yourusername/IHVS.git](https://github.com/yourusername/IHVS.git)
cd IHVS
Step 2: Install & Configure Database
Option A: MySQL (Recommended)
SQL
-- Create database
CREATE DATABASE ihvs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Import schema and sample data
mysql -u root -p ihvs < database/database_scripts.sql
Option B: Apache Derby
Bash
# Download Derby from [https://db.apache.org/derby/](https://db.apache.org/derby/)
# Start Derby Network Server
java -jar derbyrun.jar server start

# Create database and run scripts
connect 'jdbc:derby://localhost:1527/IHVS;create=true';
run 'database/database_scripts.sql';
Step 3: Configure Database Connection
Update src/util/DBConnection.java:

Java
// For MySQL
private static final String URL = "jdbc:mysql://localhost:3306/ihvs";
private static final String USERNAME = "root";
private static final String PASSWORD = "your_password";

// For Derby
// private static final String URL = "jdbc:derby://localhost:1527/IHVS";
// private static final String USERNAME = "app";
// private static final String PASSWORD = "123";
Step 4: Deploy to GlassFish
Bash
# Option A: Build WAR file
jar -cvf IHVS.war *

# Option B: Deploy via Command Line
asadmin deploy --contextroot IHVS IHVS.war

# Option C: Copy to Autodeploy
cp IHVS.war $GLASSFISH_HOME/domains/domain1/autodeploy/
Alternatively, log into the Admin Console (http://localhost:4848) -> Applications -> Deploy -> Upload IHVS.war.

Step 5: Configure GlassFish JNDI Resource
Via Admin Console (http://localhost:4848):

Navigate to Resources ──> JDBC ──> Connection Pools

Create a new pool named: DerbyPool or MySQLPool

Add a JDBC Resource with JNDI Name: jdbc/IHVS

Alternatively, configure using sun-resources.xml:

XML
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
Bash
# Start GlassFish
$GLASSFISH_HOME/bin/asadmin start-domain

# Verify deployment
$GLASSFISH_HOME/bin/asadmin list-applications
Access the system via: http://localhost:8080/IHVS

🗄️ Database Schema

Table,Description,Key Fields
users,All user accounts,"user_id, username, password_hash, role, is_active"
patients,Patient profiles,"patient_id, user_id, medical_aid_provider, reliability_score"
doctors,Doctor profiles,"doctor_id, user_id, specialization, consultation_fee"
appointments,All appointments,"appointment_id, patient_id, doctor_id, date, time, status"
doctor_schedule,Doctor availability,"schedule_id, doctor_id, day_of_week, start_time, end_time"
reminders,Automated reminders,"reminder_id, appointment_id, type, scheduled_time, status"
audit_log,Security audit trail,"log_id, user_id, action, details, ip_address, log_time"
validation_log,Medical aid history,"validation_id, patient_id, provider_name, validation_result"

Entity Relationship Diagram
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     users       │     │    patients     │     │    doctors      │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ PK user_id      │◄─── │ FK user_id      │     │ PK doctor_id    │
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

  Role , Username, Password, Purpose
👑 Admin, admin, admin123, Full system access
👨‍⚕️ Doctor, dr.smith, doctor123, Manage appointments
👤 Patient, nolwazi, patient123, Book appointments
🛡️ Medical Aid ,sfiso, med123, Validate claims

🔐 Security Features

Feature,               Implementation,             Description
Password Hashing,     jBCrypt (work factor 12),    Handled securely via PasswordUtil.java
Session Management,  15-minute timeout,            Handled globally via LoginServlet.java
Role-Based Access,  AuthenticationFilter,          Custom interception rules on URL patterns
Audit Logging,      Asynchronous executor,          Background system logging via AuditLogger.java
SQL Injection Guard,  PreparedStatement,          Strictly used across all functional DAO packages
Input Validation,    Client + Server-side,          Double-layered checking with JSPs & Servlets
Error Handling,  Custom error pages,             Beautiful mappings for error404.jsp & error500.jsp

📁 Project Structure
IHVS/
├── src/
│   ├── controller/           # Servlets handling requests
│   │   ├── LoginServlet.java
│   │   ├── RegisterServlet.java
│   │   └── ...
│   ├── dao/                  # Data Access Objects
│   │   ├── UserDAO.java
│   │   └── ...
│   ├── model/                # Entity Models
│   │   ├── User.java
│   │   └── ...
│   ├── filter/               # Request filters
│   │   └── AuthenticationFilter.java
│   ├── listener/             # Context/Session Listeners
│   │   └── ReminderScheduler.java
│   └── util/                 # Structural Helpers
│       ├── DBConnection.java
│       └── PasswordUtil.java
├── web/
│   ├── WEB-INF/
│   │   ├── web.xml
│   │   └── lib/              # Structural JAR Dependencies
│   ├── css/
│   ├── admin/                # Restricted Admin Modules
│   ├── doctor/               # Doctor Dashboards
│   ├── patient/              # Booking Interfaces
│   └── index.jsp
└── database/
    └── database_scripts.sql


🤝 Contributing
Fork the repository.

Create your feature branch: git checkout -b feature/amazing-feature

Commit your changes: git commit -m 'Add some amazing feature'

Push to the branch: git push origin feature/amazing-feature

Open a Pull Request.

Development Guidelines
Follow structural MVC architecture patterns.

Use PreparedStatement variants exclusively for query execution.

Ensure code modifications match default audit trace specifications.

📄 License
This project is for academic purposes. All rights reserved © 2026 A-Team, University of South Africa.

📞 Contact & Support
Project Manager: B.B. Magagule

Developer Team: N. Mchunu, M.P. Khumalo, S.S. Mnisi, G. Mmeia, M. Mampholo

Course: Software Project Assessment 1

Institution: Tshwane University of Technology

🏆 Acknowledgements
The Open-source community for GlassFish, Derby, and UI styling utilities.

📌 Quick Links
GlassFish Documentation

Apache Derby Documentation
