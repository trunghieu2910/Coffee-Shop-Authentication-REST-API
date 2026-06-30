package hsf302.se2033jv.project_hsf302_group2.auth.controller;

import hsf302.se2033jv.project_hsf302_group2.auth.dto.ApiResponse;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.ChangePasswordRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.CompleteGoogleAccountRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;
import hsf302.se2033jv.project_hsf302_group2.auth.repository.UserRepository;
import hsf302.se2033jv.project_hsf302_group2.auth.security.LoggedUser;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/user")
public class UserController {

    private final UserService userService;
    private final LoggedUser loggedUser;
    private final UserRepository userRepository;

    public UserController(UserService userService, LoggedUser loggedUser, UserRepository userRepository) {
        this.userService = userService;
        this.loggedUser = loggedUser;
        this.userRepository = userRepository;
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<User>> viewProfile() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (!auth.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_CUSTOMER"))) {
            return badRequest("Unauthorized access");
        }
        
        User sessionUser = loggedUser.getLoggedCustomer();
        if (sessionUser == null) {
            return badRequest("User not found in context");
        }
        
        User user = userService.getUserById(sessionUser.getUserId());
        user.setPasswordHash(null); // Do not expose password hash
        
        return ResponseEntity.ok(ApiResponse.<User>builder()
                .status(HttpStatus.OK.value())
                .message("Profile retrieved successfully")
                .data(user)
                .build());
    }

    @PostMapping("/profile/edit")
    public ResponseEntity<ApiResponse<String>> editProfile(
            @ModelAttribute User userUpdateData,
            @RequestParam(value = "imgFile", required = false) MultipartFile imgFile) {
        
        try {
            User sessionUser = loggedUser.getLoggedCustomer();
            if (sessionUser == null) return badRequest("Unauthorized access");
            
            // To be secure, force the userId to be the logged in user
            userUpdateData.setUserId(sessionUser.getUserId());
            
            if (userUpdateData.getPhone() == null || userUpdateData.getPhone().isEmpty()) {
                return badRequest("Phone number cannot be empty.");
            }
            
            userService.updateUser(userUpdateData, imgFile);

            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("Profile updated successfully")
                    .data(null)
                    .build());
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    @PostMapping("/complete-google-account")
    public ResponseEntity<ApiResponse<String>> completeGoogleAccount(@RequestBody CompleteGoogleAccountRequest request) {
        try {
            User sessionUser = loggedUser.getLoggedCustomer();
            if (sessionUser == null) return badRequest("Unauthorized access");
            
            User user = userService.getUserById(sessionUser.getUserId());
            if (!"GOOGLE_OAUTH_DUMMY_HASH".equals(user.getPasswordHash())) {
                return badRequest("Account is already completed or not a Google account.");
            }

            // Using the current logged in user's ID and username, we only need to update phone and password
            userService.completeGoogleAccount(user.getUserId(), user.getUsername(), 
                                            request.getPhoneNumber(), request.getNewPassword(), request.getConfirmPassword());
            
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("Google account completed successfully")
                    .data(null)
                    .build());
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<String>> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            User sessionUser = loggedUser.getLoggedCustomer();
            if (sessionUser == null) return badRequest("Unauthorized access");

            userService.changePassword(sessionUser.getUserId(), request.getNewPassword(), 
                                       request.getConfirmPassword(), request.getCurrentPassword());
            
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("Password changed successfully")
                    .data(null)
                    .build());
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    private <T> ResponseEntity<ApiResponse<T>> badRequest(String message) {
        return ResponseEntity.badRequest().body(ApiResponse.<T>builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .message(message)
                .build());
    }
}
