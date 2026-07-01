package hsf302.se2033jv.project_hsf302_group2.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.filter.OncePerRequestFilter;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;
import hsf302.se2033jv.project_hsf302_group2.auth.security.LoggedUser;

import java.io.IOException;

public class ProfileCompletionFilter extends OncePerRequestFilter {

    private final LoggedUser loggedUser;

    public ProfileCompletionFilter(LoggedUser loggedUser) {
        this.loggedUser = loggedUser;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String requestURI = request.getRequestURI();

        if (requestURI.startsWith("/css/") || requestURI.startsWith("/js/") ||
                requestURI.startsWith("/img/") || requestURI.startsWith("/images/") ||
                requestURI.startsWith("/assets/")) {
            filterChain.doFilter(request, response);
            return;
        }

        if (requestURI.equals("/profile/complete-google-account") || requestURI.equals("/logout")) {
            filterChain.doFilter(request, response);
            return;
        }

        User user = loggedUser.getLoggedCustomer();

        if (user != null && "GOOGLE_OAUTH_DUMMY_HASH".equals(user.getPasswordHash())) {
            boolean isProfileIncomplete = user.getPhone() == null || user.getPhone().isEmpty() ||
                                          user.getUsername() == null || user.getUsername().equals(user.getEmail().split("@")[0]);

            if (isProfileIncomplete) {
                HttpSession session = request.getSession();
                session.setAttribute("profileReminder", "Please complete your profile to continue using our services.");
                response.sendRedirect(request.getContextPath() + "/profile/complete-google-account");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}
