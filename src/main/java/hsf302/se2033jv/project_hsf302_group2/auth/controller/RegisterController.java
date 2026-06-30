package hsf302.se2033jv.project_hsf302_group2.auth.controller;

import hsf302.se2033jv.project_hsf302_group2.auth.dto.ApiResponse;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.RegisterRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.VerifyOtpRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.web.bind.annotation.*;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.Role;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.UserService;
import hsf302.se2033jv.project_hsf302_group2.auth.repository.RoleRepository;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.OtpService;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.PasswordService;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
public class RegisterController {
    private final OtpService otpService;
    private final PasswordService passwordService;
    private final UserService userService;
    private final RoleRepository roleRepository;
    
    // In-memory cache to replace HttpSession for stateless API
    private final Map<String, User> pendingUsers = new ConcurrentHashMap<>();

    public RegisterController(OtpService otpService, PasswordService passwordService, UserService userService, RoleRepository roleRepository) {
        this.otpService = otpService;
        this.passwordService = passwordService;
        this.userService = userService;
        this.roleRepository = roleRepository;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<String>> doRegister(@RequestBody RegisterRequest request){
        String firstName = request.getFirstName();
        String lastName = request.getLastName();
        String username = request.getUsername();
        String phoneNumber = request.getPhone();
        String email = request.getEmail();
        String password = request.getPassword();

        if (firstName == null || firstName.isBlank()) return badRequest("First name cannot be null or blank");
        if (lastName == null || lastName.isBlank()) return badRequest("Last name cannot be null or blank");
        if (!firstName.matches("^[\\p{L} ]+$") || !lastName.matches("^[\\p{L} ]+$")) return badRequest("Name can only contain letters");

        if (username == null || username.isBlank()) return badRequest("Username cannot be null or blank");
        if (!username.matches("^[a-zA-Z0-9_]+$")) return badRequest("Username can only contain letters, digits, and underscores");
        if (userService.findByUsername(username) != null) return badRequest("Username is already in use");

        if (email == null || email.isBlank()) return badRequest("Email cannot be null or blank");
        if (!email.matches("^[\\w._%+-]+@[\\w.-]+\\.[a-zA-Z]{2,6}$")) return badRequest("Invalid email format");
        if (userService.findByEmail(email) != null) return badRequest("Email is already registered");

        if (phoneNumber == null || phoneNumber.isBlank()) return badRequest("Phone number cannot be null or blank");
        if (!phoneNumber.matches("\\d{10}")) return badRequest("Phone number must contain exactly 10 digits");
        if (phoneNumber.equals("0000000000")) return badRequest("Phone number cannot be all zeros");
        if (userService.findByPhoneNumber(phoneNumber) != null) return badRequest("Phone number is already in use");

        // Create User object
        User user = new User();
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setUsername(username);
        user.setEmail(email);
        user.setPhone(phoneNumber);
        
        String hashPassword = BCrypt.hashpw(password, BCrypt.gensalt());
        user.setPasswordHash(hashPassword);
        user.setAvatarUrl("avatar.jpeg");
        user.setStatus(true);

        Role customerRole = roleRepository.findByRoleName("CUSTOMER");
        if (customerRole == null) {
            Role r = new Role();
            r.setRoleName("CUSTOMER");
            customerRole = roleRepository.save(r);
        }
        user.setRole(customerRole);

        // Save to in-memory map instead of session
        pendingUsers.put(email, user);
        
        // Send OTP
        passwordService.sendOtpForRegister(email);

        return ResponseEntity.ok(ApiResponse.<String>builder()
                .status(HttpStatus.OK.value())
                .message("OTP sent successfully. Please verify your email.")
                .data(email)
                .build());
    }

    @PostMapping("/verify-email")
    public ResponseEntity<ApiResponse<String>> verifyOtp(@RequestBody VerifyOtpRequest request) {
        String email = request.getEmail();
        String otp = request.getOtp();
        
        User pendingUser = pendingUsers.get(email);

        if (pendingUser == null) {
            return badRequest("Session has expired or email not found!");
        }

        boolean valid = otpService.validateOtp(email, otp);

        if (!valid) {
            return badRequest("The OTP code is incorrect or has expired!");
        }

        try {
            userService.save(pendingUser);
            pendingUsers.remove(email); // Cleanup after successful registration
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("Your account has been successfully registered.")
                    .data(email)
                    .build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.<String>builder()
                            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                            .message(e.getMessage())
                            .build());
        }
    }
    
    private ResponseEntity<ApiResponse<String>> badRequest(String message) {
        return ResponseEntity.badRequest().body(ApiResponse.<String>builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .message(message)
                .build());
    }
}