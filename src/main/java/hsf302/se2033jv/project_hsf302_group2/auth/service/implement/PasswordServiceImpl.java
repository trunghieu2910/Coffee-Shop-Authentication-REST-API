package hsf302.se2033jv.project_hsf302_group2.auth.service.implement;

import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.OtpService;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.PasswordService;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;
import hsf302.se2033jv.project_hsf302_group2.auth.repository.UserRepository;

@Service
public class PasswordServiceImpl implements PasswordService {
    UserRepository userRepository;
    OtpService otpService;
    JavaMailSender mailSender;
    private static final String PASSWORD_REGEX = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$";
    private static final String EMAIL_REGEX = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";

    public PasswordServiceImpl(UserRepository userRepository, OtpService otpService, JavaMailSender mailSender) {
        this.userRepository = userRepository;
        this.otpService = otpService;
        this.mailSender = mailSender;
    }

    public void sendOtpForRegister(String email) {
        if (email == null || email.isEmpty()) {
            throw new IllegalArgumentException("The email cannot be empty!");
        }

        if (!email.matches(EMAIL_REGEX)) {
            throw new IllegalArgumentException("Email format is invalid! Example: example@gmail.com");
        }
        String otp = otpService.generateOtp(email);
        sendHtmlEmail(email, "Your OTP Code for Registration", otp);
    }

    public void sendOtpToEmail(String email) {
        if (email == null || email.isEmpty()) {
            throw new IllegalArgumentException("The email cannot be empty!");
        }

        if (!email.matches(EMAIL_REGEX)) {
            throw new IllegalArgumentException("Email format is invalid! Example: example@gmail.com");
        }

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            throw new IllegalArgumentException("The email address was not found.");
        }

        if (user.getPasswordHash().equals("GOOGLE_OAUTH_DUMMY_HASH")) {
            throw new IllegalArgumentException("This account was created with Google. Please login with Google.");
        }

        String otp = otpService.generateOtp(email);
        sendHtmlEmail(email, "Your OTP Code for Reset Password", otp);
    }

    private void sendHtmlEmail(String to, String subject, String otp) {
        try {
            jakarta.mail.internet.MimeMessage message = mailSender.createMimeMessage();
            org.springframework.mail.javamail.MimeMessageHelper helper = new org.springframework.mail.javamail.MimeMessageHelper(message, true, "UTF-8");
            helper.setTo(to);
            helper.setSubject(subject);
            
            String htmlContent = "<div style=\"font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 12px; background-color: #f4f7f6; color: #333;\">\n" +
                    "    <div style=\"text-align: center; margin-bottom: 30px;\">\n" +
                    "        <h1 style=\"color: #2c3e50; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 1px;\">Bean & Brew</h1>\n" +
                    "        <p style=\"color: #7f8c8d; font-size: 14px; margin-top: 5px;\">Coffee Management System</p>\n" +
                    "    </div>\n" +
                    "    <div style=\"background-color: #ffffff; padding: 40px 30px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); text-align: center;\">\n" +
                    "        <h2 style=\"color: #34495e; font-size: 22px; margin-top: 0; margin-bottom: 20px;\">OTP Verification Code</h2>\n" +
                    "        <p style=\"color: #555; font-size: 16px; line-height: 1.6; margin-bottom: 30px;\">Hello,<br>Here is your secure OTP code. Please use it to verify your request. This code will expire in <strong style=\"color: #e74c3c;\">3 minutes</strong>.</p>\n" +
                    "        <div style=\"margin: 35px 0;\">\n" +
                    "            <span style=\"display: inline-block; padding: 15px 40px; font-size: 36px; font-weight: 800; color: #ffffff; background: linear-gradient(135deg, #3498db, #2980b9); border-radius: 8px; letter-spacing: 6px; box-shadow: 0 4px 10px rgba(52, 152, 219, 0.3);\">" + otp + "</span>\n" +
                    "        </div>\n" +
                    "        <p style=\"color: #95a5a6; font-size: 14px; margin-bottom: 0; margin-top: 30px;\">If you didn't request this code, you can safely ignore and delete this email.</p>\n" +
                    "    </div>\n" +
                    "    <div style=\"text-align: center; margin-top: 30px; color: #bdc3c7; font-size: 12px;\">\n" +
                    "        <p style=\"margin: 0;\">&copy; 2026 Bean & Brew Coffee. All rights reserved.</p>\n" +
                    "    </div>\n" +
                    "</div>";

            helper.setText(htmlContent, true); // true indicates HTML
            mailSender.send(message);
        } catch (jakarta.mail.MessagingException e) {
            System.err.println("Failed to send HTML OTP email: " + e.getMessage());
            throw new RuntimeException("Lỗi hệ thống khi gửi email xác thực!");
        }
    }

    public void resetPassword(String email, String otp, String newPassword, String confirmPassword) {
        if (otp == null || otp.isEmpty()) {
            throw new IllegalArgumentException("The OTP cannot be empty.");
        }
        if (newPassword == null || newPassword.isEmpty()) {
            throw new IllegalArgumentException("The new password cannot be empty.");
        }
        if (confirmPassword == null || confirmPassword.isEmpty()) {
            throw new IllegalArgumentException("The confirm password cannot be empty.");
        }

        boolean isValidOtp = otpService.validateOtp(email, otp);
        if (!isValidOtp) {
            throw new IllegalArgumentException("Invalid or expired OTP!");
        }

        if (!newPassword.equals(confirmPassword)) {
            throw new IllegalArgumentException("New password does not match!");
        }

        if (!newPassword.matches(PASSWORD_REGEX)) {
            throw new IllegalArgumentException("Password must be at least 8 characters long and include uppercase letters, " +
                    "lowercase letters, numbers, and special characters!");
        }

        User user = userRepository.findByEmail(email).orElseThrow(() -> new IllegalArgumentException("User not found!"));
        String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
        user.setPasswordHash(hashedPassword);
        userRepository.save(user);
    }
}
