package hsf302.se2033jv.project_hsf302_group2.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JwtAuthResponse {
    private String token;
    private String tokenType = "Bearer";
    private List<String> roles;

    public JwtAuthResponse(String token, List<String> roles) {
        this.token = token;
        this.roles = roles;
    }
}
