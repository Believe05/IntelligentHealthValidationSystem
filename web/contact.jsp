
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Us | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .contact-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        .contact-header {
            text-align: center;
            margin-bottom: 40px;
        }
        .contact-header h1 {
            font-size: 36px;
            margin-bottom: 16px;
        }
        .contact-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        .contact-card {
            background: white;
            border-radius: 16px;
            padding: 30px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        .contact-card:hover {
            transform: translateY(-5px);
        }
        .contact-icon {
            width: 70px;
            height: 70px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .contact-icon i {
            font-size: 30px;
            color: white;
        }
        .contact-card h3 {
            margin-bottom: 15px;
            font-size: 20px;
        }
        .contact-card p {
            color: #64748b;
            margin-bottom: 10px;
        }
        .contact-card a {
            color: #2563eb;
            text-decoration: none;
            font-weight: 500;
        }
        .contact-card a:hover {
            text-decoration: underline;
        }
        .contact-form {
            background: white;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            max-width: 800px;
            margin: 0 auto;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
        }
        .form-group input, .form-group select, .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            font-family: inherit;
        }
        .form-group input:focus, .form-group textarea:focus {
            outline: none;
            border-color: #2563eb;
        }
        .btn-submit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            width: 100%;
        }
        .map-container {
            margin-top: 40px;
            border-radius: 16px;
            overflow: hidden;
        }
        .business-hours {
            background: #f8fafc;
            border-radius: 16px;
            padding: 20px;
            margin-top: 20px;
        }
        .business-hours h4 {
            margin-bottom: 15px;
        }
        .hour-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        @media (max-width: 768px) {
            .contact-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

<nav class="landing-nav">
    <div class="nav-container">
        <div class="nav-logo">
            <span class="logo-icon">🏥</span>
            <span class="logo-text">IHVS</span>
        </div>
        <div class="nav-links">
            <a href="index.jsp">Home</a>
            <a href="index.jsp#features">Features</a>
            <a href="index.jsp#how-it-works">How It Works</a>
            <a href="index.jsp#benefits">Benefits</a>
            <a href="contact.jsp" class="active">Contact</a>
            <a href="login.jsp" class="nav-btn btn-outline">Sign In</a>
            <a href="register.jsp" class="nav-btn btn-primary">Get Started</a>
        </div>
        <div class="nav-mobile-toggle" onclick="toggleMobileMenu()">☰</div>
    </div>
</nav>

<div class="contact-container">
    <div class="contact-header">
        <h1><i class="fas fa-headset"></i> Contact Us</h1>
        <p>We're here to help! Reach out to us through any of these channels</p>
    </div>

    <div class="contact-grid">
        <!-- Phone -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fas fa-phone-alt"></i></div>
            <h3>Call Us</h3>
            <p><a href="tel:+27878463181">078 846 3181</a></p>
            <p><small>Mon-Fri, 8am-5pm</small></p>
        </div>

        <!-- WhatsApp -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fab fa-whatsapp"></i></div>
            <h3>WhatsApp</h3>
            <p><a href="https://wa.me/27878463181" target="_blank">078 846 3181</a></p>
            <p><small>Quick response within 24h</small></p>
        </div>

        <!-- Email -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fas fa-envelope"></i></div>
            <h3>Email Us</h3>
            <p><a href="mailto:support@ihvs.co.za">support@ihvs.co.za</a></p>
            <p><a href="mailto:info@ihvs.co.za">info@ihvs.co.za</a></p>
        </div>
    </div>

    <div class="contact-grid">
        <!-- Social Media -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fas fa-share-alt"></i></div>
            <h3>Social Media</h3>
            <div style="display: flex; gap: 20px; justify-content: center; margin-top: 15px;">
                <a href="#" target="_blank" style="color: #1877f2; font-size: 28px;"><i class="fab fa-facebook"></i></a>
                <a href="#" target="_blank" style="color: #1da1f2; font-size: 28px;"><i class="fab fa-twitter"></i></a>
                <a href="#" target="_blank" style="color: #0a66c2; font-size: 28px;"><i class="fab fa-linkedin"></i></a>
                <a href="#" target="_blank" style="color: #e4405f; font-size: 28px;"><i class="fab fa-instagram"></i></a>
            </div>
        </div>

        <!-- Address -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fas fa-map-marker-alt"></i></div>
            <h3>Visit Us</h3>
            <p>123 Health Avenue<br>Sandton, Johannesburg<br>2196, South Africa</p>
        </div>

        <!-- Emergency -->
        <div class="contact-card">
            <div class="contact-icon"><i class="fas fa-ambulance"></i></div>
            <h3>Emergency</h3>
            <p><strong>24/7 Emergency Hotline</strong></p>
            <p><a href="tel:+27878463181" style="color: #ef4444; font-size: 20px;">078 846 3181</a></p>
        </div>
    </div>

    <!-- Business Hours -->
    <div class="business-hours">
        <h4><i class="fas fa-clock"></i> Business Hours</h4>
        <div class="hour-row"><span>Monday - Friday</span><span>8:00 AM - 5:00 PM</span></div>
        <div class="hour-row"><span>Saturday</span><span>9:00 AM - 1:00 PM</span></div>
        <div class="hour-row"><span>Sunday</span><span>Closed</span></div>
        <div class="hour-row"><span>Public Holidays</span><span>Closed</span></div>
    </div>

    <!-- Contact Form -->
    <div class="contact-form">
        <h3 style="text-align: center; margin-bottom: 30px;"><i class="fas fa-paper-plane"></i> Send us a message</h3>
        <form action="#" method="post">
            <div class="form-group">
                <label>Your Name</label>
                <input type="text" name="name" placeholder="Enter your full name" required>
            </div>
            <div class="form-group">
                <label>Email Address</label>
                <input type="email" name="email" placeholder="Enter your email" required>
            </div>
            <div class="form-group">
                <label>Subject</label>
                <select name="subject">
                    <option>General Inquiry</option>
                    <option>Technical Support</option>
                    <option>Medical Aid Validation</option>
                    <option>Appointment Issues</option>
                    <option>Feedback</option>
                    <option>Partnership</option>
                </select>
            </div>
            <div class="form-group">
                <label>Message</label>
                <textarea name="message" rows="5" placeholder="Write your message here..." required></textarea>
            </div>
            <button type="submit" class="btn-submit"><i class="fas fa-send"></i> Send Message</button>
        </form>
    </div>

    <!-- Map -->
    <div class="map-container">
        <iframe 
            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3581.123456789!2d28.047305!3d-26.107135!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x1e9571b5f2b8c5c7%3A0x7d3f2b9c8d5e2f1a!2sSandton%2C%20Johannesburg!5e0!3m2!1sen!2sza!4v1700000000000!5m2!1sen!2sza" 
            width="100%" 
            height="300" 
            style="border:0;" 
            allowfullscreen="" 
            loading="lazy">
        </iframe>
    </div>
</div>

<footer class="landing-footer">
    <div class="container">
        <div class="footer-grid">
            <div class="footer-col">
                <div class="footer-logo"><span class="logo-icon">🏥</span><span class="logo-text">IHVS</span></div>
                <p>Intelligent Health Validation System</p>
            </div>
            <div class="footer-col">
                <h4>Quick Links</h4>
                <a href="index.jsp">Home</a>
                <a href="index.jsp#features">Features</a>
                <a href="index.jsp#how-it-works">How It Works</a>
                <a href="contact.jsp">Contact</a>
            </div>
            <div class="footer-col">
                <h4>Contact Info</h4>
                <a href="tel:+27878463181"><i class="fas fa-phone"></i> 078 846 3181</a>
                <a href="https://wa.me/27878463181"><i class="fab fa-whatsapp"></i> WhatsApp</a>
                <a href="mailto:support@ihvs.co.za"><i class="fas fa-envelope"></i> support@ihvs.co.za</a>
            </div>
            <div class="footer-col">
                <h4>Connect With Us</h4>
                <div style="display: flex; gap: 15px;">
                    <a href="#" style="color: #1877f2;"><i class="fab fa-facebook fa-lg"></i></a>
                    <a href="#" style="color: #1da1f2;"><i class="fab fa-twitter fa-lg"></i></a>
                    <a href="#" style="color: #0a66c2;"><i class="fab fa-linkedin fa-lg"></i></a>
                    <a href="#" style="color: #e4405f;"><i class="fab fa-instagram fa-lg"></i></a>
                    <a href="https://wa.me/27878463181" style="color: #25D366;"><i class="fab fa-whatsapp fa-lg"></i></a>
                </div>
            </div>
        </div>
        <div class="footer-copyright">
            © 2026 Intelligent Health Validation System. All rights reserved.
        </div>
    </div>
</footer>

<script>
function toggleMobileMenu() {
    document.querySelector('.nav-links').classList.toggle('show');
}
</script>
</body>
</html>