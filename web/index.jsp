<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IHVS – Intelligent Health Validation System</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <!-- External Library: Chart.js for future analytics (Assessment 5) -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
 
<div class="landing-page">
    <!-- Navigation Bar -->
    <nav class="landing-nav">
        <div class="nav-container">
            <div class="nav-logo">
                <span class="logo-icon">🏥</span>
                <span class="logo-text">IHVS</span>
            </div>
            <div class="nav-links">
                <a href="#features">Features</a>
                <a href="#how-it-works">How It Works</a>
                <a href="#benefits">Benefits</a>
                <a href="login.jsp" class="nav-btn btn-outline">Sign In</a>
                <a href="register.jsp" class="nav-btn btn-primary">Get Started</a>
            </div>
            <div class="nav-mobile-toggle" onclick="toggleMobileMenu()">☰</div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="hero-section">
        <div class="hero-container">
            <div class="hero-content">
                <h1 class="hero-title">
                    Intelligent Health <span class="text-gradient">Validation System</span>
                </h1>
                <p class="hero-description">
                    Streamlining healthcare appointments with real-time medical aid validation, 
                    automated reminders, and patient reliability tracking.
                </p>
                <div class="hero-actions">
                    <a href="register.jsp" class="btn btn-primary btn-lg">Get Started →</a>
                    <a href="#features" class="btn btn-outline btn-lg">Learn More</a>
                </div>
                <div class="hero-stats">
                    <div class="stat-item">
                        <div class="stat-number">1000+</div>
                        <div class="stat-label">Patients Served</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number">50+</div>
                        <div class="stat-label">Doctors</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number">95%</div>
                        <div class="stat-label">Success Rate</div>
                    </div>
                </div>
            </div>
            <div class="hero-image">
                <div class="hero-illustration">
                    <div class="ill-card ill-card-1"><span>📅</span> Smart Booking</div>
                    <div class="ill-card ill-card-2"><span>✓</span> Real-time Validation</div>
                    <div class="ill-card ill-card-3"><span>⭐</span> Reliability Score</div>
                    <div class="ill-card ill-card-4"><span>🔔</span> Automated Reminders</div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features-section">
        <div class="container">
            <div class="section-header centered">
                <h2>Why Choose IHVS?</h2>
                <p>Comprehensive healthcare management for all stakeholders</p>
            </div>
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">🩺</div>
                    <h3>For Patients</h3>
                    <ul><li>✓ Book appointments online 24/7</li><li>✓ Track your reliability score</li><li>✓ Manage medical aid details</li><li>✓ Receive automated reminders</li><li>✓ View appointment history</li></ul>
                    <a href="register.jsp" class="feature-link">Register as Patient →</a>
                </div>
                <div class="feature-card featured">
                    <div class="feature-icon">👨‍⚕️</div>
                    <h3>For Doctors</h3>
                    <ul><li>✓ Manage availability schedule</li><li>✓ Confirm/cancel appointments</li><li>✓ View patient reliability scores</li><li>✓ Track no-show statistics</li><li>✓ Access patient history</li></ul>
                    <a href="register.jsp" class="feature-link">Register as Doctor →</a>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">🛡️</div>
                    <h3>For Medical Aid</h3>
                    <ul><li>✓ Validate member eligibility</li><li>✓ Track validation history</li><li>✓ Monitor usage patterns</li><li>✓ Real-time approval system</li><li>✓ Integration ready</li></ul>
                    <a href="register.jsp" class="feature-link">Partner with us →</a>
                </div>
            </div>
        </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="how-it-works-section">
        <div class="container">
            <div class="section-header centered">
                <h2>How IHVS Works</h2>
                <p>Simple, secure, and efficient healthcare coordination</p>
            </div>
            <div class="steps-grid">
                <div class="step-item"><div class="step-number">1</div><h4>Register & Setup</h4><p>Create your account and complete your profile with medical aid details</p></div>
                <div class="step-item"><div class="step-number">2</div><h4>Book Appointment</h4><p>Choose a doctor, date, and time that works for you</p></div>
                <div class="step-item"><div class="step-number">3</div><h4>Instant Validation</h4><p>Medical aid eligibility verified in real-time</p></div>
                <div class="step-item"><div class="step-number">4</div><h4>Attend & Track</h4><p>Receive reminders and track your reliability score</p></div>
            </div>
        </div>
    </section>

    <!-- Benefits Section -->
    <section id="benefits" class="benefits-section">
        <div class="container">
            <div class="section-header centered">
                <h2>Key Benefits</h2>
                <p>Transforming healthcare administration</p>
            </div>
            <div class="benefits-grid">
                <div class="benefit-item"><div class="benefit-icon">⏱️</div><h4>Reduce No-Shows</h4><p>Automated reminders decrease missed appointments by up to 40%</p></div>
                <div class="benefit-item"><div class="benefit-icon">💰</div><h4>Prevent Claim Rejections</h4><p>Real-time validation ensures medical aid eligibility before consultation</p></div>
                <div class="benefit-item"><div class="benefit-icon">📊</div><h4>Patient Reliability Index</h4><p>Unique scoring system to identify high-risk patients</p></div>
                <div class="benefit-item"><div class="benefit-icon">🔒</div><h4>Secure & Compliant</h4><p>Enterprise-grade security with role-based access control</p></div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
        <div class="container">
            <div class="cta-card">
                <h2>Ready to transform your healthcare experience?</h2>
                <p>Join hundreds of patients and doctors already using IHVS</p>
                <div class="cta-actions">
                    <a href="register.jsp" class="btn btn-primary btn-lg">Create Free Account</a>
                    <a href="login.jsp" class="btn btn-outline-light btn-lg">Sign In</a>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer with Social Media Links (Assessment 5) -->
    <!-- Footer with Social Media Links (Assessment 5) -->
<footer class="landing-footer">
    <div class="container">
        <div class="footer-grid">
            <div class="footer-col">
                <div class="footer-logo"><span class="logo-icon">🏥</span><span class="logo-text">IHVS</span></div>
                <p>Intelligent Health Validation System</p>
                <p style="font-size: 12px; margin-top: 10px;">Making healthcare accessible and efficient for everyone.</p>
            </div>
            <div class="footer-col">
                <h4>Quick Links</h4>
                <a href="#features">Features</a>
                <a href="#how-it-works">How It Works</a>
                <a href="#benefits">Benefits</a>
                <a href="contact.jsp">Contact Us</a>
            </div>
            <div class="footer-col">
                <h4>Support</h4>
                <a href="#">Help Center</a>
                <a href="contact.jsp">FAQs</a>
                <a href="#">Privacy Policy</a>
                <a href="#">Terms of Service</a>
            </div>
            <div class="footer-col">
                <h4>Contact Info</h4>
                <div style="margin-bottom: 10px;">
                    <i class="fas fa-phone"></i> <a href="tel:+27878463181">078 846 3181</a>
                </div>
                <div style="margin-bottom: 10px;">
                    <i class="fab fa-whatsapp" style="color: #25D366;"></i> 
                    <a href="https://wa.me/27878463181" target="_blank">WhatsApp Chat</a>
                </div>
                <div style="margin-bottom: 10px;">
                    <i class="fas fa-envelope"></i> <a href="mailto:support@ihvs.co.za">support@ihvs.co.za</a>
                </div>
                <div>
                    <i class="fas fa-map-marker-alt"></i> Sandton, Johannesburg
                </div>
            </div>
        </div>
        <div class="footer-copyright">
            <p>© 2026 Intelligent Health Validation System. All rights reserved.</p>
            <div style="display: flex; gap: 15px; justify-content: center; margin-top: 15px;">
                <a href="#" style="color: #1877f2;"><i class="fab fa-facebook fa-lg"></i></a>
                <a href="#" style="color: #1da1f2;"><i class="fab fa-twitter fa-lg"></i></a>
                <a href="#" style="color: #0a66c2;"><i class="fab fa-linkedin fa-lg"></i></a>
                <a href="#" style="color: #e4405f;"><i class="fab fa-instagram fa-lg"></i></a>
                <a href="https://wa.me/27878463181" style="color: #25D366;"><i class="fab fa-whatsapp fa-lg"></i></a>
            </div>
        </div>
    </div>
</footer>

<!-- Floating WhatsApp Button -->
<a href="https://wa.me/27878463181" target="_blank" class="whatsapp-float">
    <i class="fab fa-whatsapp"></i>
    <span>Chat with us</span>
</a>
</div>

<script>
function toggleMobileMenu() {
    document.querySelector('.nav-links').classList.toggle('show');
}
</script>
</body>
</html>