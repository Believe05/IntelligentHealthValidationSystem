<%@ page contentType="text/html;charset=UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>IHVS – Page Not Found</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"></head>
<body>
<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;background:#f0f2f5;">
  <div class="card" style="text-align:center;max-width:400px;padding:48px 40px;">
    <div style="font-size:64px;margin-bottom:16px;">&#128270;</div>
    <h2 style="margin-bottom:8px;">Page Not Found</h2>
    <p class="text-muted mb-2">The page you requested could not be found.</p>
    <a href="${pageContext.request.contextPath}/index.jsp" class="btn btn-primary">Go to Home</a>
  </div>
</div>
</body>
</html>
