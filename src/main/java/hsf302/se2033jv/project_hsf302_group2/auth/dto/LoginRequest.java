package hsf302.se2033jv.project_hsf302_group2.auth.dto;

import lombok.Data;

@Data
public class LoginRequest {
    private String username;
    private String password;
}
