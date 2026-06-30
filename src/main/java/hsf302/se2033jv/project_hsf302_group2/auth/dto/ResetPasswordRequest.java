package hsf302.se2033jv.project_hsf302_group2.auth.dto;

import lombok.Data;

@Data
public class ResetPasswordRequest {
    private String email;
    private String otp;
    private String newPassword;
    private String confirmPassword;
}
