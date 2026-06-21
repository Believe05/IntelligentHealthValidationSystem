# 🏥 IHVS — Intelligent Health Validation System

> A web-based healthcare appointment and medical aid management platform built with Java EE, JSP, and Apache Derby.

---

## ✨ What It Does

IHVS is a multi-role health system that connects **patients**, **doctors**, **medical aid providers**, and **admins** in one place. It handles everything from booking appointments to validating medical aid claims — with automated email reminders to keep everyone in the loop.

---

## 👥 User Roles

| Role | What They Can Do |
|---|---|
| 🧑‍⚕️ **Patient** | Book appointments, view history, manage profile |
| 🩺 **Doctor** | Manage schedule & availability, handle appointments |
| 🏢 **Medical Aid** | Validate claims, view utilization history |
| 🔧 **Admin** | Manage all users, view reports, export PDFs, send reminders |

---

## 🛠️ Tech Stack

- **Backend:** Java EE (Servlets, Filters, Listeners)
- **Frontend:** JSP, HTML/CSS, JavaScript
- **Database:** Apache Derby (embedded connection pool)
- **PDF Export:** iTextPDF
- **Email:** JavaMail (`EmailService`)
- **Server:** GlassFish / any Java EE-compatible container
- **Build Tool:** Apache Ant (NetBeans project)

---

## 📁 Project Structure

```
IHVS_INTELLIGENT/
├── src/java/
│   ├── controller/     # Servlets (Admin, Doctor, Patient, MedicalAid, etc.)
│   ├── dao/            # Data Access Objects
│   ├── model/          # POJOs (User, Patient, Doctor, Appointment…)
│   ├── service/        # EmailService
│   ├── filter/         # Auth & encoding filters
│   ├── listener/       # App context & reminder scheduler
│   └── util/           # DBConnection pool, StoredProcedures, PasswordUtil
├── web/
│   ├── admin/          # Admin JSP pages
│   ├── doctor/         # Doctor JSP pages
│   ├── patient/        # Patient JSP pages
│   ├── medicalaid/     # Medical Aid JSP pages
│   ├── css/style.css
│   └── WEB-INF/web.xml
├── build.xml           # Ant build config
└── dist/               # Compiled .war file
```

---

## 🚀 Getting Started

### Prerequisites

- Java JDK 8+
- Apache Derby database
- GlassFish Server (or compatible Java EE server)
- NetBeans IDE *(recommended)* or any IDE with Ant support

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/your-username/IHVS_INTELLIGENT.git
   ```

2. **Set up the Derby database**
   - Start your Derby server on port `1527`
   - Create a database named `IHVS2` with user `app` / password `123`
   - Run the SQL schema scripts to create the required tables

3. **Configure (optional)**  
   You can override DB credentials via system properties:
   ```
   -Dihvs.db.url=jdbc:derby://localhost:1527/IHVS2
   -Dihvs.db.user=app
   -Dihvs.db.password=yourpassword
   ```

4. **Build & deploy**
   ```bash
   ant build
   # Deploy IHVS_INTELLIGENT.war to your GlassFish server
   ```

5. **Open in browser**
   ```
   http://localhost:8080/IHVS_INTELLIGENT/
   ```

---

## ⚙️ Key Features

- 🔐 **Role-based authentication** with session management and auth filters
- 📅 **Appointment booking** with real-time doctor availability checks
- 💊 **Medical aid validation** with history tracking
- 📊 **Admin reports** — doctor performance, patient reliability, medical aid utilization
- 📄 **PDF export** of reports via iTextPDF
- ⏰ **Automated email reminders** via a background scheduler
- 🧾 **Audit logging** for all critical admin actions
- 🔒 **Password hashing** via `PasswordUtil`

---

## 📬 Contact & Contribution

Feel free to open an issue or submit a pull request if you'd like to contribute or report a bug!

---

> Built with ☕ Java and a lot of care for healthcare workflows.
