package hsf302.se2033jv.project_hsf302_group2.auth.service.implement;

import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.OtpService;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpServiceImpl implements OtpService {

    private final Map<String, OtpData> otpStorage = new ConcurrentHashMap<>();

    private static class OtpData {
        private final String otp;
        private final LocalDateTime expiryTime;

        public OtpData(String otp, LocalDateTime expiryTime) {
            this.otp = otp;
            this.expiryTime = expiryTime;
        }

        public String getOtp() {
            return otp;
        }

        public LocalDateTime getExpiryTime() {
            return expiryTime;
        }
    }

    public String generateOtp(String email) {
        // Sinh OTP 6 chá»¯ sá»‘ (cÃ³ thá»ƒ cÃ³ 0 á»Ÿ Ä‘áº§u)
        String otp = String.format("%06d", new Random().nextInt(1_000_000));
        otpStorage.put(email, new OtpData(otp, LocalDateTime.now().plusMinutes(15)));
        System.out.println("[DEBUG] Generated OTP for " + email + " = " + otp);
        return otp;
    }

    public boolean validateOtp(String email, String otp) {
        OtpData data = otpStorage.get(email);
        System.out.println("[DEBUG] Input OTP: " + otp + " | Stored OTP: " + data.getOtp());
        if (data == null) {
            return false;
        }

        // Náº¿u OTP Ä‘Ã£ háº¿t háº¡n -> xÃ³a vÃ  tráº£ false
        if (data.getExpiryTime().isBefore(LocalDateTime.now())) {
            otpStorage.remove(email);
            return false;
        }

        // So sÃ¡nh OTP
        boolean isValid = data.getOtp().equals(otp);

        // Náº¿u há»£p lá»‡ thÃ¬ xÃ³a (chá»‰ dÃ¹ng 1 láº§n)
        if (isValid) {
            otpStorage.remove(email);
        }

        return isValid;
    }
}



