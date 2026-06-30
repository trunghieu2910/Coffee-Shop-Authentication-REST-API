package hsf302.se2033jv.project_hsf302_group2.auth.controller;

import hsf302.se2033jv.project_hsf302_group2.auth.dto.ApiResponse;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.ForgotPasswordRequest;
import hsf302.se2033jv.project_hsf302_group2.auth.dto.ResetPasswordRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.PasswordService;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
public class ForgotPasswordController {

    @Autowired
    private PasswordService passwordService;

    // Cache to limit resends (Stateless equivalent of HttpSession)
    private final Map<String, Integer> otpResendAttempts = new ConcurrentHashMap<>();
    private final Map<String, Long> otpFirstResendTime = new ConcurrentHashMap<>();
    private final Map<String, Integer> otpInvalidAttempts = new ConcurrentHashMap<>();

    private int handleResendOtpLimit(String email) {
        Integer resendAttempts = otpResendAttempts.getOrDefault(email, 0);
        Long firstResendTime = otpFirstResendTime.get(email);

        long currentTime = System.currentTimeMillis();
        long oneHour = 3600_000L; 

        if (firstResendTime == null || currentTime - firstResendTime > oneHour) {
            resendAttempts = 0;
            firstResendTime = currentTime;
            otpFirstResendTime.put(email, firstResendTime);
        }

        if (resendAttempts >= 3) {
            throw new IllegalStateException("You have reached the maximum number of OTP resends. Please try again after 1 hour.");
        }

        resendAttempts++;
        otpResendAttempts.put(email, resendAttempts);

        return resendAttempts;
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<String>> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        try {
            String email = request.getEmail();
            if (email == null || email.isBlank()) {
                return badRequest("Email cannot be blank.");
            }

            // Reset invalid attempts on a new forgot password request
            otpInvalidAttempts.remove(email);

            handleResendOtpLimit(email);
            passwordService.sendOtpToEmail(email);

            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("OTP has been sent to your email.")
                    .data(email)
                    .build());
        } catch (IllegalStateException e) {
            return badRequest(e.getMessage());
        } catch (IllegalArgumentException e) {
            return badRequest(e.getMessage());
        }
    }

    @PostMapping("/forgot-password/resend-otp")
    public ResponseEntity<ApiResponse<String>> resendOtp(@RequestBody ForgotPasswordRequest request) {
        try {
            String email = request.getEmail();
            if (email == null || email.isBlank()) {
                return badRequest("Email cannot be blank.");
            }

            int resendAttempts = handleResendOtpLimit(email);
            passwordService.sendOtpToEmail(email);

            otpInvalidAttempts.remove(email); // reset invalid attempts

            int remaining = 3 - resendAttempts;
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("A new OTP has been sent. You can resend " + remaining + " more times within 1 hour.")
                    .data(email)
                    .build());
        } catch (IllegalStateException e) {
            return badRequest(e.getMessage());
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<String>> setPassword(@RequestBody ResetPasswordRequest request) {
        String email = request.getEmail();
        
        Integer attempts = otpInvalidAttempts.getOrDefault(email, 0);
        if (attempts >= 3) {
            otpInvalidAttempts.remove(email);
            return badRequest("You have exceeded the maximum number of invalid attempts (3). Please request a new OTP.");
        }

        try {
            passwordService.resetPassword(email, request.getOtp(), request.getNewPassword(), request.getConfirmPassword());
            
            // Cleanup memory on success
            otpInvalidAttempts.remove(email);
            otpResendAttempts.remove(email);
            otpFirstResendTime.remove(email);
            
            return ResponseEntity.ok(ApiResponse.<String>builder()
                    .status(HttpStatus.OK.value())
                    .message("Reset password successfully!")
                    .data(email)
                    .build());
        } catch (IllegalArgumentException e) {
            attempts++;
            otpInvalidAttempts.put(email, attempts);
            return badRequest(e.getMessage());
        }
    }

    private ResponseEntity<ApiResponse<String>> badRequest(String message) {
        return ResponseEntity.badRequest().body(ApiResponse.<String>builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .message(message)
                .build());
    }
}


