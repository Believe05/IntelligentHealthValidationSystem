package util;

import java.sql.*;
import java.util.logging.*;

/**
 * FIX: Connection was acquired but never returned to pool in finally blocks.
 * Now uses try-with-resources for proper cleanup.
 */
public class ProcedureHelper {

    private static final Logger LOG = Logger.getLogger(ProcedureHelper.class.getName());

    // Called by: book_appointment_with_validation stored procedure
    public static void bookAppointment(int patientId, int doctorId, Date appointmentDate,
                                        String appointmentTime, String notes)
            throws SQLException {

        // FIX: Use try-with-resources to guarantee connection is returned to pool
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String insertSQL = "INSERT INTO appointments (patient_id, doctor_id, appointment_date, " +
                                  "appointment_time, notes, status_id, validation_status, created_at) " +
                                  "VALUES (?, ?, ?, ?, ?, 1, 'pending', CURRENT_TIMESTAMP)";
                try (PreparedStatement ps = conn.prepareStatement(insertSQL, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, patientId);
                    ps.setInt(2, doctorId);
                    ps.setDate(3, appointmentDate);
                    ps.setString(4, appointmentTime);
                    ps.setString(5, notes);
                    ps.executeUpdate();

                    ResultSet rs = ps.getGeneratedKeys();
                    if (rs.next()) {
                        int appointmentId = rs.getInt(1);
                        LOG.info("Created appointment ID: " + appointmentId);
                    }
                }

                String updateSQL = "UPDATE patients SET total_appointments = total_appointments + 1 " +
                                  "WHERE patient_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateSQL)) {
                    ps.setInt(1, patientId);
                    ps.executeUpdate();
                }

                conn.commit();
                LOG.info("Booked appointment for patient: " + patientId);
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // Called by: cancel_appointment_with_updates stored procedure
    public static void cancelAppointment(int appointmentId, String reason)
            throws SQLException {

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int patientId = -1;
                String selectSQL = "SELECT patient_id FROM appointments WHERE appointment_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(selectSQL)) {
                    ps.setInt(1, appointmentId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        patientId = rs.getInt("patient_id");
                    }
                }

                if (patientId == -1) {
                    throw new SQLException("Appointment not found: " + appointmentId);
                }

                String updateApptSQL = "UPDATE appointments SET status_id = " +
                                      "(SELECT status_id FROM appointment_status WHERE status_name = 'cancelled'), " +
                                      "cancellation_reason = ? WHERE appointment_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateApptSQL)) {
                    ps.setString(1, reason);
                    ps.setInt(2, appointmentId);
                    ps.executeUpdate();
                }

                String updatePatientSQL = "UPDATE patients SET cancellation_count = cancellation_count + 1 " +
                                         "WHERE patient_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updatePatientSQL)) {
                    ps.setInt(1, patientId);
                    ps.executeUpdate();
                }

                String recalcSQL = "UPDATE patients SET reliability_score = " +
                                  "CASE " +
                                  "  WHEN (100 - (no_show_count * 10) - (cancellation_count * 5)) < 0 THEN 0 " +
                                  "  WHEN (100 - (no_show_count * 10) - (cancellation_count * 5)) > 100 THEN 100 " +
                                  "  ELSE (100 - (no_show_count * 10) - (cancellation_count * 5)) " +
                                  "END WHERE patient_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(recalcSQL)) {
                    ps.setInt(1, patientId);
                    ps.executeUpdate();
                }

                conn.commit();
                LOG.info("Cancelled appointment: " + appointmentId);
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // Called by: complete_appointment_update stored procedure
    public static void completeAppointment(int appointmentId)
            throws SQLException {

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int patientId = -1;
                String selectSQL = "SELECT patient_id FROM appointments WHERE appointment_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(selectSQL)) {
                    ps.setInt(1, appointmentId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        patientId = rs.getInt("patient_id");
                    }
                }

                if (patientId == -1) {
                    throw new SQLException("Appointment not found: " + appointmentId);
                }

                String updateApptSQL = "UPDATE appointments SET status_id = " +
                                      "(SELECT status_id FROM appointment_status WHERE status_name = 'completed') " +
                                      "WHERE appointment_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateApptSQL)) {
                    ps.setInt(1, appointmentId);
                    ps.executeUpdate();
                }

                String updatePatientSQL = "UPDATE patients SET completed_count = completed_count + 1 " +
                                         "WHERE patient_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updatePatientSQL)) {
                    ps.setInt(1, patientId);
                    ps.executeUpdate();
                }

                String recalcSQL = "UPDATE patients SET reliability_score = " +
                                  "CASE " +
                                  "  WHEN (100 - (no_show_count * 10) - (cancellation_count * 5)) < 0 THEN 0 " +
                                  "  WHEN (100 - (no_show_count * 10) - (cancellation_count * 5)) > 100 THEN 100 " +
                                  "  ELSE (100 - (no_show_count * 10) - (cancellation_count * 5)) " +
                                  "END WHERE patient_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(recalcSQL)) {
                    ps.setInt(1, patientId);
                    ps.executeUpdate();
                }

                conn.commit();
                LOG.info("Completed appointment: " + appointmentId);
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
