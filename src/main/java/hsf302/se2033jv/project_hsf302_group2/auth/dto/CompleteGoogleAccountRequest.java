package hsf302.se2033jv.project_hsf302_group2.auth.dto;

import lombok.Data;

@Data
public class CompleteGoogleAccountRequest {
    private String phoneNumber;
    private String newPassword;
    private String confirmPassword;
}
