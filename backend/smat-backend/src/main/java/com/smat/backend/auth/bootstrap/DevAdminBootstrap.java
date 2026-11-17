
package com.smat.backend.auth.bootstrap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.support.TransactionTemplate;

@Configuration
@Profile("dev")
@ConditionalOnProperty(
        name = "smat.bootstrap.enabled",
        havingValue = "true"
)
public class DevAdminBootstrap {

    @Bean
    public ApplicationRunner createInitialAdmin(
            JdbcTemplate jdbc,
            PasswordEncoder encoder,
            TransactionTemplate transactionTemplate,
            @Value("${smat.bootstrap.username}") String username,
            @Value("${smat.bootstrap.password}") String password,
            @Value("${smat.bootstrap.organization-id}") Long orgId) {

        return args -> transactionTemplate.executeWithoutResult(status -> {

            if (username.isBlank() || password.length() < 12) {
                throw new IllegalStateException(
                        "Invalid bootstrap credentials"
                );
            }

            Integer orgCount = jdbc.queryForObject(
                    """
                    SELECT COUNT(*)
                    FROM organizations
                    WHERE id = ? AND status = 'ACTIVE'
                    """,
                    Integer.class,
                    orgId
            );

            if (orgCount == null || orgCount != 1) {
                throw new IllegalStateException(
                        "Active organization not found"
                );
            }

            Integer userCount = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM users WHERE username = ?",
                    Integer.class,
                    username
            );

            if (userCount != null && userCount > 0) {
                throw new IllegalStateException(
                        "Bootstrap username already exists; " +
                                "disable bootstrap and inspect the existing account"
                );
            }

            String hash = encoder.encode(password);

            Long userId = jdbc.queryForObject(
                    """
                    INSERT INTO users
                        (username, password_hash, full_name, is_active)
                    VALUES (?, ?, ?, TRUE)
                    RETURNING id
                    """,
                    Long.class,
                    username,
                    hash,
                    "Initial Administrator"
            );

            jdbc.update(
                    """
                    INSERT INTO organization_memberships
                        (organization_id, user_id, role, is_active)
                    VALUES (?, ?, 'ADMIN', TRUE)
                    """,
                    orgId,
                    userId
            );
        });
    }
}
