package hsf302.se2033jv.project_hsf302_group2.auth.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Component;
import hsf302.se2033jv.project_hsf302_group2.auth.service.interfaces.UserService;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;

@Component
public class LoggedUser {

    private final UserService userService;

    public LoggedUser(UserService userService) {
        this.userService = userService;
    }

    public User getLoggedCustomer() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null) {
            return null;
        }

        Object principal = authentication.getPrincipal();

        if (principal instanceof CustomUserDetails userDetails) {
            return userDetails.getUser();
        }

        if (principal instanceof OidcUser oidcUser) {
            return userService.findByEmail(oidcUser.getEmail());
        }

        return null;
    }
}
