package hsf302.se2033jv.project_hsf302_group2.auth.security;

import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

public class CustomUserDetails implements UserDetails {
    private final User user;

    public CustomUserDetails(User user) {
        this.user = user;
    }

    public User getUser() {
        return this.user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        if (user != null) {
            return user.getAuthorities();
        }
        return List.of();
    }

    @Override
    public String getPassword() {
        return (user != null) ? user.getPasswordHash() : null;
    }

    @Override
    public String getUsername() {
        return (user != null) ? user.getUsername() : null;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        if (user != null) {
            return user.isStatus();
        }
        return true;
    }
}
