
package com.smat.backend.user.service;

import com.smat.backend.security.service.OrganizationAccessService;
import com.smat.backend.user.dto.CreateStaffRequest;
import com.smat.backend.user.dto.StaffResponse;
import com.smat.backend.user.repository.UserRepository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminUserService {

    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    private final OrganizationAccessService access;

    public AdminUserService(
            JdbcTemplate jdbc,
            PasswordEncoder passwordEncoder,
            UserRepository userRepository,
            OrganizationAccessService access) {

        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.userRepository = userRepository;
        this.access = access;
    }

    @Transactional
    public StaffResponse create(
            Jwt jwt,
            Long organizationId,
            CreateStaffRequest request) {

        // 1. Người tạo phải có quyền ADMIN.
        access.requireAdmin(jwt, organizationId);

        // 2. Chỉ cho phép cấp vai trò FARMER hoặc QC.
        String role = request.role().trim().toUpperCase();

        if (!role.equals("FARMER") && !role.equals("QC")) {
            throw new IllegalArgumentException(
                    "Only FARMER or QC accounts can be created"
            );
        }

        // 3. Kiểm tra username chưa tồn tại.
        String username = request.username().trim();

        if (userRepository.existsByUsername(username)) {
            throw new IllegalStateException(
                    "Username already exists"
            );
        }

        // 4. Mã hóa mật khẩu bằng BCrypt.
        String passwordHash =
                passwordEncoder.encode(request.password());

        // 5. Tạo User trong PostgreSQL.
        Long userId = jdbc.queryForObject(
                """
                INSERT INTO users
                    (username, password_hash, full_name, is_active)
                VALUES (?, ?, ?, TRUE)
                RETURNING id
                """,
                Long.class,
                username,
                passwordHash,
                request.fullName().trim()
        );

        // 6. Tạo membership trong cùng transaction.
        Long membershipId = jdbc.queryForObject(
                """
                INSERT INTO organization_memberships
                    (organization_id, user_id, role, is_active)
                VALUES (?, ?, ?, TRUE)
                RETURNING id
                """,
                Long.class,
                organizationId,
                userId,
                role
        );

        // 7. Không trả mật khẩu cho client.
        return new StaffResponse(
                userId,
                membershipId,
                organizationId,
                username,
                request.fullName().trim(),
                role
        );
    }
}
