package hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces;

public interface PasswordService {
    void sendOtpForRegister(String email);
    void sendOtpToEmail(String email);
    void resetPassword(String email, String otp, String newPassword, String confirmPassword);
}