<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In – IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="auth-page">
    <!-- Back to home link -->
    <a href="index.jsp" class="back-home">← Back to Home</a>
    
    <div class="auth-card">
        <!-- Card Header -->
        <div class="auth-header">
            <div class="auth-logo">🏥 IHVS</div>
            <h1>Welcome Back</h1>
            <p>Sign in to your account to continue</p>
        </div>

        <!-- Card Body -->
        <div class="auth-body">
            <% if (request.getParameter("success") != null) { %>
                <div class="alert alert-success">
                    <span class="alert-icon">✓</span>
                    <%= request.getParameter("success").replace("+", " ") %>
                </div>
            <% } %>

            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">
                    <span class="alert-icon">✕</span>
                    <%= request.getAttribute("error") %>
                </div>
            <% } %>

            <form action="${pageContext.request.contextPath}/LoginServlet" method="post">
                <div class="form-group">
                    <label class="form-label" for="username">Username</label>
                    <input class="form-control"
                           type="text"
                           id="username"
                           name="username"
                           placeholder="Enter your username"
                           autocomplete="username"
                           required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password</label>
                    <input class="form-control"
                           type="password"
                           id="password"
                           name="password"
                           placeholder="Enter your password"
                           autocomplete="current-password"
                           required>
                </div>

                <div class="form-options">
                    <label class="checkbox-label">
                        <input type="checkbox" name="remember"> Remember me
                    </label>
                    <a href="#" class="forgot-password">Forgot password?</a>
                </div>

                <button type="submit" class="btn btn-primary btn-full btn-lg">
                    Sign In →
                </button>
            </form>

            <div class="auth-divider">
                <span>New to IHVS?</span>
            </div>

            <div class="auth-footer">
                <p>Don't have an account? <a href="register.jsp" class="auth-link">Create Account</a></p>
            </div>

            
        </div>
    </div>
</div>
</body>
</html>