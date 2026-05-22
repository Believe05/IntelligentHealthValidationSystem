package controller;

import dao.DoctorDAO;
import dao.PatientDAO;
import dao.UserDAO;
import dao.MedicalAidDAO;
import model.MedicalAidProvider;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    private final UserDAO    userDAO    = new UserDAO();
    private final PatientDAO patientDAO = new PatientDAO();
    private final DoctorDAO  doctorDAO  = new DoctorDAO();
    private final MedicalAidDAO medicalAidDAO = new MedicalAidDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        
        // Load existing providers for the dropdown
        java.util.List<MedicalAidProvider> providers = medicalAidDAO.getAllProviders();
        req.setAttribute("existingProviders", providers);
        req.getRequestDispatcher("/register.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        try {
            // Get parameters
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            String confirmPassword = req.getParameter("confirmPassword");
            String fullName = req.getParameter("fullName");
            String email = req.getParameter("email");
            String phone = req.getParameter("phone");
            String role = req.getParameter("role");
            
            // For medical aid - comes from dropdown OR new text input
            String providerIdParam = req.getParameter("providerId");
            String newProviderNameRaw = req.getParameter("newProviderName");  // Raw input like "Bongi"
            String contactPerson = req.getParameter("contactPerson");
            
            int providerId = 0;
            try {
                providerId = Integer.parseInt(providerIdParam);
            } catch (NumberFormatException e) {
                providerId = 0;
            }
            
            System.out.println("=== Registration Attempt ===");
            System.out.println("Username: " + username);
            System.out.println("Email: " + email);
            System.out.println("Role: " + role);
            System.out.println("Provider ID from dropdown: " + providerId);
            System.out.println("New Provider Name entered (raw): " + newProviderNameRaw);

            // --- Validation ---
            if (isEmpty(username) || isEmpty(password) || isEmpty(fullName) ||
                    isEmpty(email) || isEmpty(phone) || isEmpty(role)) {
                req.setAttribute("error", "All fields are required.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            if (!password.equals(confirmPassword)) {
                req.setAttribute("error", "Passwords do not match.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            if (password.length() < 8) {
                req.setAttribute("error", "Password must be at least 8 characters.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Check if username exists
            if (userDAO.isUsernameExists(username)) {
                req.setAttribute("error", "Username already taken.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Check if email exists
            if (userDAO.isEmailExists(email)) {
                req.setAttribute("error", "Email already registered.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Validate role
            if (!"patient".equals(role) && !"doctor".equals(role) && 
                !"admin".equals(role) && !"medicalaid".equals(role)) {
                req.setAttribute("error", "Invalid role selected.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // For medicalaid, either providerId OR newProviderName is required
            if ("medicalaid".equals(role)) {
                if (providerId == 0 && (newProviderNameRaw == null || newProviderNameRaw.trim().isEmpty())) {
                    req.setAttribute("error", "Please select an existing Medical Aid Provider or enter a new provider name.");
                    req.getRequestDispatcher("/register.jsp").forward(req, res);
                    return;
                }
            }

            // Create user object
            User user = new User();
            user.setUsername(username.trim());
            user.setPassword(password);
            user.setFullName(fullName.trim());
            user.setEmail(email.trim().toLowerCase());
            user.setPhone(phone.trim());
            user.setRole(role);

            // Register user
            boolean registered = userDAO.registerUser(user);
            System.out.println("User registration result: " + registered);

            if (!registered) {
                req.setAttribute("error", "Registration failed. Database error.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            System.out.println("User registered with ID: " + user.getUserId());

            // Create role-specific profile
            if ("patient".equals(role)) {
                boolean patientCreated = patientDAO.createPatient(user.getUserId());
                System.out.println("Patient profile created: " + patientCreated);
                
            } else if ("doctor".equals(role)) {
                String specialization = req.getParameter("specialization");
                double fee = 0;
                
                try { 
                    String feeStr = req.getParameter("consultationFee");
                    if (feeStr != null && !feeStr.trim().isEmpty()) {
                        fee = Double.parseDouble(feeStr.trim());
                    }
                } catch (NumberFormatException e) {
                    System.out.println("Invalid consultation fee format, using default: " + e.getMessage());
                    fee = 350.00;
                }
                
                boolean doctorCreated = doctorDAO.createDoctor(
                    user.getUserId(),
                    isEmpty(specialization) ? "General Practitioner" : specialization.trim(),
                    fee
                );
                System.out.println("Doctor profile created: " + doctorCreated);
                
            } else if ("medicalaid".equals(role)) {
                boolean providerCreated = false;
                String finalProviderName = null;
                
                // Case 1: User selected an existing provider from dropdown
                if (providerId > 0) {
                    MedicalAidProvider existingProvider = medicalAidDAO.getProviderById(providerId);
                    if (existingProvider != null) {
                        finalProviderName = existingProvider.getProviderName();
                        providerCreated = linkMedicalAidProviderToUser(providerId, user.getUserId());
                        System.out.println("Linked existing medical aid provider (ID: " + providerId + ") to user: " + providerCreated);
                    }
                } 
                // Case 2: User entered a new provider name (e.g., "Bongi" -> becomes "Bongi Health")
                else if (newProviderNameRaw != null && !newProviderNameRaw.trim().isEmpty()) {
                    // ========== KEY FIX: APPEND " Health" TO THE PROVIDER NAME ==========
                    String cleanedName = newProviderNameRaw.trim();
                    
                    // Remove any existing "Health" suffix to avoid duplication (e.g., "Bongi Health" -> "Bongi")
                    if (cleanedName.toLowerCase().endsWith(" health")) {
                        cleanedName = cleanedName.substring(0, cleanedName.length() - 7);
                    }
                    
                    // Capitalize first letter of each word
                    String[] words = cleanedName.split(" ");
                    StringBuilder capitalized = new StringBuilder();
                    for (String word : words) {
                        if (word.length() > 0) {
                            capitalized.append(Character.toUpperCase(word.charAt(0)))
                                      .append(word.substring(1).toLowerCase())
                                      .append(" ");
                        }
                    }
                    String baseName = capitalized.toString().trim();
                    
                    // Append " Health" to create the full provider name
                    finalProviderName = baseName + " Health";
                    
                    System.out.println("Original input: '" + newProviderNameRaw + "'");
                    System.out.println("Base name: '" + baseName + "'");
                    System.out.println("Final provider name: '" + finalProviderName + "'");
                    
                    String contactPersonName = (contactPerson != null && !contactPerson.trim().isEmpty()) 
                                                ? contactPerson.trim() 
                                                : fullName.trim();
                    
                    providerCreated = createMedicalAidProvider(
                        user.getUserId(),
                        finalProviderName,  // This will be "Bongi Health" instead of just "Bongi"
                        contactPersonName,
                        email.trim(),
                        phone.trim()
                    );
                    System.out.println("Created NEW medical aid provider: " + finalProviderName + " - Result: " + providerCreated);
                }
                
                if (!providerCreated) {
                    System.out.println("WARNING: Medical aid provider profile creation/linking failed!");
                }
            }

            // Log successful registration
            AuditLogger.log(user.getUserId(), "REGISTER", 
                          "New " + role + " registered: " + username, 
                          req.getRemoteAddr());

            // Redirect to login with success message
            res.sendRedirect(req.getContextPath() + "/login.jsp?success=Registration+successful!+Please+login.");

        } catch (Exception e) {
            System.out.println("Unexpected error during registration: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Registration failed: " + e.getMessage());
            req.getRequestDispatcher("/register.jsp").forward(req, res);
        }
    }
    
    /**
     * Link an existing medical aid provider to a user account
     */
    private boolean linkMedicalAidProviderToUser(int providerId, int userId) {
        String sql = "UPDATE medical_aid_providers SET user_id = ? WHERE provider_id = ?";
        try (java.sql.Connection con = util.DBConnection.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, providerId);
            int updated = ps.executeUpdate();
            if (updated > 0) {
                System.out.println("Successfully linked provider ID " + providerId + " to user ID " + userId);
                return true;
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error linking provider to user: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Create a new medical aid provider record
     * The providerName already has " Health" appended before calling this method
     */
    private boolean createMedicalAidProvider(int userId, String providerName, String contactPerson, String email, String phone) {
        String sql = "INSERT INTO medical_aid_providers (user_id, provider_name, contact_person, email, phone, is_active, created_date) " +
                     "VALUES (?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)";
        
        try (java.sql.Connection con = util.DBConnection.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, providerName);  // Already has " Health" appended
            ps.setString(3, contactPerson);
            ps.setString(4, email);
            ps.setString(5, phone);
            int result = ps.executeUpdate();
            if (result > 0) {
                System.out.println("Created new medical aid provider: '" + providerName + "' for user: " + userId);
                return true;
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error creating medical aid provider: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    private boolean isEmpty(String s) { 
        return s == null || s.trim().isEmpty(); 
    }
}