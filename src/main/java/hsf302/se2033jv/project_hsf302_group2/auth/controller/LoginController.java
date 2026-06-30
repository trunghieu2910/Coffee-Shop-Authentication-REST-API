package hsf302.se2033jv.project_hsf302_group2.auth.controller;

import hsf302.se2033jv.project_hsf302_group2.auth.dto.ApiResponse;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.GoogleAuthRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.JwtAuthResponse;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.LoginRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.Role;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;
import hsf302.se2033jv.project_hsf302_group2.auth.jwt.JwtTokenProvider;
import hsf302.se2033jv.project_hsf302_group2.auth.repository.RoleRepository;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class LoginController {

    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserService userService;
    private final RoleRepository roleRepository;

    public LoginController(AuthenticationManager authenticationManager, JwtTokenProvider jwtTokenProvider, UserService userService, RoleRepository roleRepository) {
        this.authenticationManager = authenticationManager;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userService = userService;
        this.roleRepository = roleRepository;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<JwtAuthResponse>> authenticateUser(@RequestBody LoginRequest loginRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getUsername(),
                            loginRequest.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            String token = jwtTokenProvider.generateToken(authentication);
            List<String> roles = authentication.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .collect(Collectors.toList());

            ApiResponse<JwtAuthResponse> response = ApiResponse.<JwtAuthResponse>builder()
                    .status(HttpStatus.OK.value())
                    .message("Login successful")
                    .data(new JwtAuthResponse(token, roles))
                    .build();

            return ResponseEntity.ok(response);
        } catch (org.springframework.security.core.AuthenticationException e) {
            ApiResponse<JwtAuthResponse> response = ApiResponse.<JwtAuthResponse>builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Invalid username or password")
                    .data(null)
                    .build();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } catch (Exception e) {
            ApiResponse<JwtAuthResponse> response = ApiResponse.<JwtAuthResponse>builder()
                    .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                    .message("Login failed: " + e.getMessage())
                    .data(null)
                    .build();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<String>> logoutUser() {
        // Stateless JWT logout is handled by client deleting token.
        // We just return a success message.
        return ResponseEntity.ok(ApiResponse.<String>builder()
                .status(HttpStatus.OK.value())
                .message("Logout successful. Please delete your token on the client side.")
                .data(null)
                .build());
    }

    @PostMapping("/google")
    public ResponseEntity<ApiResponse<JwtAuthResponse>> authenticateGoogle(@RequestBody GoogleAuthRequest googleAuthRequest) {
        try {
            RestTemplate restTemplate = new RestTemplate();
            String url = "https://oauth2.googleapis.com/tokeninfo?id_token=" + googleAuthRequest.getIdToken();
            
            // Calling Google API to verify token
            Map<String, Object> googleProfile = restTemplate.getForObject(url, Map.class);
            if (googleProfile == null || googleProfile.containsKey("error")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.<JwtAuthResponse>builder()
                                .status(HttpStatus.UNAUTHORIZED.value())
                                .message("Invalid Google Token")
                                .build()
                );
            }

            String email = (String) googleProfile.get("email");
            String name = (String) googleProfile.get("name");

            User user = userService.findByEmail(email);
            if (user == null) {
                // Register new dummy user
                user = new User();
                user.setEmail(email);
                user.setFirstName(name);
                user.setLastName("");
                user.setUsername(email.split("@")[0]);
                user.setPasswordHash("GOOGLE_OAUTH_DUMMY_HASH");
                user.setAvatarUrl("avatar.jpeg");
                user.setStatus(true);
                user.setPhone(""); // Prompt them to update later

                Role customerRole = roleRepository.findByRoleName("CUSTOMER");
                if (customerRole == null) {
                    Role r = new Role();
                    r.setRoleName("CUSTOMER");
                    customerRole = roleRepository.save(r);
                }
                user.setRole(customerRole);
                userService.saveUser(user);
            }

            // Generate our own JWT token for the user
            // We use UsernamePasswordAuthenticationToken for Spring context but we don't authenticate with AuthenticationManager
            final String roleName = user.getRole().getRoleName();
            List<GrantedAuthority> authorities = List.of((GrantedAuthority) () -> "ROLE_" + roleName);
            Authentication authentication = new UsernamePasswordAuthenticationToken(user.getUsername(), null, authorities);
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
            String token = jwtTokenProvider.generateToken(authentication);

            ApiResponse<JwtAuthResponse> response = ApiResponse.<JwtAuthResponse>builder()
                    .status(HttpStatus.OK.value())
                    .message("Google Login successful")
                    .data(new JwtAuthResponse(token, authorities.stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList())))
                    .build();

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.<JwtAuthResponse>builder()
                            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                            .message("Google Login failed: " + e.getMessage())
                            .build()
            );
        }
    }
}