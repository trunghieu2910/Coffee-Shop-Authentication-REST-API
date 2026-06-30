package hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces;

public interface OtpService {
    String generateOtp(String email);
    boolean validateOtp(String email, String otp);
}