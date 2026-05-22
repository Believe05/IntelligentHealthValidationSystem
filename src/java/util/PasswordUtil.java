package util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Utility class for hashing and verifying passwords using BCrypt.
 * Requires jbcrypt-0.4.jar on the classpath.
 */
public class PasswordUtil {

    private static final int WORK_FACTOR = 12;

    /** Hash a plain-text password. */
    public static String hash(String plainPassword) {
        if (plainPassword == null || plainPassword.trim().isEmpty()) {
            throw new IllegalArgumentException("Password cannot be empty");
        }
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(WORK_FACTOR));
    }

    /** Return true if plainPassword matches the stored hash. */
    public static boolean verify(String plainPassword, String storedHash) {
        if (plainPassword == null || plainPassword.trim().isEmpty()) {
            return false;
        }
        if (storedHash == null || storedHash.trim().isEmpty()) {
            return false;
        }
        // Accept both $2a$ and $2b$ BCrypt formats
        if (!storedHash.startsWith("$2a$") && !storedHash.startsWith("$2b$")) {
            return false;
        }
        try {
            return BCrypt.checkpw(plainPassword, storedHash);
        } catch (Exception e) {
            System.err.println("Password verification error: " + e.getMessage());
            return false;
        }
    }
    
    /** Generate a random temporary password */
    public static String generateTempPassword() {
        // Simple temp password generator
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            int index = (int)(Math.random() * chars.length());
            sb.append(chars.charAt(index));
        }
        return sb.toString();
    }
}