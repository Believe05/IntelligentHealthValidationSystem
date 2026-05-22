package controller;

import dao.AppointmentDAO;
import model.Appointment;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.HashSet;
import java.util.Set;
import util.DBConnection;

@WebServlet("/CheckAvailabilityServlet")
public class CheckAvailabilityServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        int doctorId = -1;
        String doctorIdParam = req.getParameter("doctorId");
        String date = req.getParameter("date");
        
        try {
            doctorId = Integer.parseInt(doctorIdParam);
        } catch (NumberFormatException e) {
            doctorId = -1;
        }
        
        System.out.println("CheckAvailabilityServlet - doctorId: " + doctorId + ", date: " + date);
        
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"availableSlots\":[");
        
        if (doctorId != -1 && date != null && !date.isEmpty()) {
            try {
                Set<String> bookedSlots = getBookedSlots(doctorId, date);
                
                // Get doctor's schedule for this day to determine available times
                String dayOfWeek = getDayOfWeek(date);
                String[] scheduleTimes = getDoctorSchedule(doctorId, dayOfWeek);
                
                String[] allSlots = generateTimeSlots(scheduleTimes[0], scheduleTimes[1]);
                
                boolean first = true;
                for (String slot : allSlots) {
                    if (!bookedSlots.contains(slot)) {
                        if (!first) json.append(",");
                        json.append("\"").append(slot).append("\"");
                        first = false;
                    }
                }
            } catch (Exception e) {
                System.out.println("Error checking availability: " + e.getMessage());
                e.printStackTrace();
            }
        }
        
        json.append("]");
        json.append("}");
        
        System.out.println("Response: " + json.toString());
        
        PrintWriter out = res.getWriter();
        out.print(json.toString());
        out.flush();
    }
    
    private Set<String> getBookedSlots(int doctorId, String date) {
        Set<String> bookedSlots = new HashSet<>();
        
        String sql = "SELECT a.appointment_time FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE a.doctor_id = ? AND a.appointment_date = ? " +
                     "AND s.status_name NOT IN ('cancelled', 'no-show')";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, doctorId);
            ps.setString(2, date);
            
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String aptTime = rs.getString("appointment_time");
                if (aptTime != null) {
                    // Normalize time format to HH:MM
                    if (aptTime.length() > 5) {
                        aptTime = aptTime.substring(0, 5);
                    }
                    bookedSlots.add(aptTime);
                    System.out.println("Booked slot: " + aptTime);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error querying booked slots: " + e.getMessage());
            e.printStackTrace();
        }
        
        return bookedSlots;
    }
    
    private String getDayOfWeek(String date) {
        try {
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
            java.util.Date d = sdf.parse(date);
            java.text.SimpleDateFormat dayFormat = new java.text.SimpleDateFormat("EEEE");
            return dayFormat.format(d);
        } catch (Exception e) {
            return "Monday";
        }
    }
    
    private String[] getDoctorSchedule(int doctorId, String dayOfWeek) {
        String[] times = {"09:00", "17:00"}; // Default
        
        String sql = "SELECT start_time, end_time FROM doctor_schedule " +
                     "WHERE doctor_id = ? AND day_of_week = ?";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ps.setString(2, dayOfWeek);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String start = rs.getString("start_time");
                String end = rs.getString("end_time");
                if (start != null) {
                    if (start.length() > 5) start = start.substring(0, 5);
                    times[0] = start;
                }
                if (end != null) {
                    if (end.length() > 5) end = end.substring(0, 5);
                    times[1] = end;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return times;
    }
    
    private String[] generateTimeSlots(String startTime, String endTime) {
        java.util.List<String> slots = new java.util.ArrayList<>();
        
        try {
            // Parse start and end times
            String[] startParts = startTime.split(":");
            String[] endParts = endTime.split(":");
            
            int startHour = Integer.parseInt(startParts[0]);
            int startMinute = startParts.length > 1 ? Integer.parseInt(startParts[1]) : 0;
            int endHour = Integer.parseInt(endParts[0]);
            int endMinute = endParts.length > 1 ? Integer.parseInt(endParts[1]) : 0;
            
            // Round up start minute to 0 or 30
            if (startMinute > 0 && startMinute < 30) {
                startMinute = 30;
            } else if (startMinute > 30) {
                startHour++;
                startMinute = 0;
            }
            
            int currentHour = startHour;
            int currentMinute = startMinute;
            
            while (currentHour < endHour || (currentHour == endHour && currentMinute < endMinute)) {
                String timeSlot = String.format("%02d:%02d", currentHour, currentMinute);
                slots.add(timeSlot);
                
                currentMinute += 30;
                if (currentMinute >= 60) {
                    currentHour++;
                    currentMinute -= 60;
                }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            // Fallback slots
            slots.add("09:00");
            slots.add("09:30");
            slots.add("10:00");
            slots.add("10:30");
            slots.add("11:00");
            slots.add("11:30");
            slots.add("12:00");
            slots.add("14:00");
            slots.add("14:30");
            slots.add("15:00");
            slots.add("15:30");
            slots.add("16:00");
        }
        
        return slots.toArray(new String[0]);
    }
}