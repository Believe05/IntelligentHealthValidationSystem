package model;

public class AppointmentStatus {
    private int    statusId;
    private String statusName;    // pending | confirmed | cancelled | rescheduled | completed | no-show

    public AppointmentStatus() {}

    public int getStatusId() { return statusId; }
    public void setStatusId(int statusId) { this.statusId = statusId; }

    public String getStatusName() { return statusName; }
    public void setStatusName(String statusName) { this.statusName = statusName; }

    @Override
    public String toString() {
        return statusName;
    }
}