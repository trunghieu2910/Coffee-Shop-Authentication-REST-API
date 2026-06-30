package hsf302.se2033jv.project_hsf302_group2.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import hsf302.se2033jv.project_hsf302_group2.auth.entity.User;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {
    User getUserByUserId(int userId);
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    User findByPhone(String phone);
    boolean existsByEmailIgnoreCase(String email);
}
