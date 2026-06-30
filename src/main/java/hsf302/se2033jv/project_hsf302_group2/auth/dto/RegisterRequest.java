package hsf302.se2033jv.project_hsf302_group2.auth.dto;

import lombok.Data;

@Data
public class RegisterRequest {
    private String firstName;
    private String lastName;
    private String username;
    private String email;
    private String phone;
    private String password;
}
