
package com.smat.backend.assignment.service;

import com.smat.backend.assignment.dto.MyAssignedPlotResponse;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class MyPlotsService {

    private final JdbcTemplate jdbc;

    public MyPlotsService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<MyAssignedPlotResponse> getMyPlots(Jwt jwt) {

        long userId;

        try {
            userId = Long.parseLong(jwt.getSubject());
        } catch (RuntimeException ex) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid authentication"
            );
        }

        String sql = """
            SELECT DISTINCT
                p.organization_id,
                p.id AS plot_id,
                p.plot_code,
                p.plot_name,
                m.role
            FROM users u
            JOIN organization_memberships m
              ON m.user_id = u.id
            JOIN plot_assignments pa
              ON pa.membership_id = m.id
             AND pa.organization_id = m.organization_id
            JOIN plots p
              ON p.id = pa.plot_id
             AND p.organization_id = pa.organization_id
            JOIN organizations o
              ON o.id = p.organization_id
            WHERE u.id = ?
              AND u.is_active = TRUE
              AND m.is_active = TRUE
              AND m.role IN ('FARMER', 'QC')
              AND pa.ended_at IS NULL
              AND p.status = 'ACTIVE'
              AND o.status = 'ACTIVE'
            ORDER BY p.organization_id, p.plot_code, m.role
            """;

        return jdbc.query(sql, (rs, rowNum) ->
                new MyAssignedPlotResponse(
                        rs.getLong("organization_id"),
                        rs.getLong("plot_id"),
                        rs.getString("plot_code"),
                        rs.getString("plot_name"),
                        rs.getString("role")
                ), userId);
    }
}
