package dao;

import model.Reminder;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReminderDAO {

    // ==================== CREATE ====================
    
    public boolean createReminder(Reminder reminder) {
        String sql = "INSERT INTO reminders (appointment_id, reminder_type, scheduled_time, channel, status, created_date) " +
                     "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, reminder.getAppointmentId());
            ps.setString(2, reminder.getReminderType());
            ps.setString(3, reminder.getScheduledTime());
            ps.setString(4, reminder.getChannel());
            ps.setString(5, reminder.getStatus());
            
            int rows = ps.executeUpdate();
            if (rows > 0) {
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    reminder.setReminderId(keys.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    // ==================== READ ====================
    
    public List<Reminder> getAllReminders() {
        List<Reminder> list = new ArrayList<>();
        String sql = "SELECT * FROM reminders ORDER BY scheduled_time ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }
    
    public List<Reminder> getRemindersByAppointment(int appointmentId) {
        List<Reminder> list = new ArrayList<>();
        String sql = "SELECT * FROM reminders WHERE appointment_id = ? ORDER BY scheduled_time ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }
    
    public List<Reminder> getPendingReminders() {
        List<Reminder> list = new ArrayList<>();
        String sql = "SELECT * FROM reminders WHERE status = 'pending' AND scheduled_time <= CURRENT_TIMESTAMP ORDER BY scheduled_time ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return list;
    }
    
    // ==================== UPDATE ====================
    
    public boolean markReminderAsSent(int reminderId) {
        String sql = "UPDATE reminders SET status = 'sent', sent_time = CURRENT_TIMESTAMP WHERE reminder_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, reminderId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    public boolean markReminderAsFailed(int reminderId) {
        String sql = "UPDATE reminders SET status = 'failed' WHERE reminder_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, reminderId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    // ==================== DELETE ====================
    
    public boolean deleteReminder(int reminderId) {
        String sql = "DELETE FROM reminders WHERE reminder_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, reminderId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    public boolean deleteRemindersForAppointment(int appointmentId) {
        String sql = "DELETE FROM reminders WHERE appointment_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, appointmentId);
            ps.executeUpdate();
            return true;
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    // FIX: Derby does not support "CURRENT_TIMESTAMP - 7 DAYS" arithmetic syntax.
    // Use {fn TIMESTAMPADD(SQL_TSI_DAY, -7, CURRENT_TIMESTAMP)} instead.
    public int deleteOldReminders() {
        String sql = "DELETE FROM reminders WHERE status = 'sent' " +
                     "AND sent_time <= {fn TIMESTAMPADD(SQL_TSI_DAY, -7, CURRENT_TIMESTAMP)}";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            return ps.executeUpdate();
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return 0;
    }
    
    // ==================== HELPER ====================
    
    private Reminder mapRow(ResultSet rs) throws SQLException {
        Reminder r = new Reminder();
        r.setReminderId(rs.getInt("reminder_id"));
        r.setAppointmentId(rs.getInt("appointment_id"));
        r.setReminderType(rs.getString("reminder_type"));
        r.setScheduledTime(rs.getString("scheduled_time"));
        r.setSentTime(rs.getString("sent_time"));
        r.setStatus(rs.getString("status"));
        r.setChannel(rs.getString("channel"));
        r.setCreatedAt(rs.getString("created_date"));
        return r;
    }
}
