package model;

public class AuditLog {
    private int     logId;
    private int     userId;
    private String  username;           // Joined field
    private String  userFullName;        // Joined field
    private String  action;
    private String  details;
    private String  ipAddress;
    private String  logTime;

    public AuditLog() {}

    // Getters and Setters
    public int getLogId() { return logId; }
    public void setLogId(int logId) { this.logId = logId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getUserFullName() { return userFullName; }
    public void setUserFullName(String userFullName) { this.userFullName = userFullName; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getLogTime() { return logTime; }
    public void setLogTime(String logTime) { this.logTime = logTime; }
}