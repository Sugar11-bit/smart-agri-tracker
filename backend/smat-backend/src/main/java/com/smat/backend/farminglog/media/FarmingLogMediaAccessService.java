
package com.smat.backend.farminglog.media;

import com.smat.backend.farminglog.entity.FarmingLog;
import com.smat.backend.farminglog.repository.FarmingLogRepository;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class FarmingLogMediaAccessService {

    private final FarmingLogRepository logs;
    private final JdbcTemplate jdbc;

    public FarmingLogMediaAccessService(
            FarmingLogRepository logs,
            JdbcTemplate jdbc
    ) {
        this.logs = logs;
        this.jdbc = jdbc;
    }

    public FarmingLog requireWritableLog(
            Jwt jwt,
            Long logId
    )
    {
        if (jwt == null || jwt.getSubject() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        final Long userId;

        try {
            userId = Long.valueOf(jwt.getSubject());
        } catch (NumberFormatException ex) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        FarmingLog log = logs.findById(logId)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Farming Log not found"
                        )
                );

        String sql = """
            SELECT EXISTS (
                SELECT 1
                FROM users u
                JOIN organization_memberships m
                  ON m.user_id = u.id
                JOIN organizations o
                  ON o.id = m.organization_id
                JOIN plot_assignments pa
                  ON pa.membership_id = m.id
                 AND pa.organization_id = m.organization_id
                JOIN plots p
                  ON p.id = pa.plot_id
                 AND p.organization_id = pa.organization_id
                WHERE u.id = ?
                  AND u.id = ?
                  AND m.organization_id = ?
                  AND pa.plot_id = ?
                  AND u.is_active = TRUE
                  AND m.is_active = TRUE
                  AND m.role = 'FARMER'
                  AND o.status = 'ACTIVE'
                  AND p.status = 'ACTIVE'
                  AND pa.ended_at IS NULL
            )
            """;

        Boolean allowed = jdbc.queryForObject(
                sql,
                Boolean.class,
                userId,
                log.getFarmerUserId(),
                log.getOrganizationId(),
                log.getPlotId()
        );

        if (!Boolean.TRUE.equals(allowed)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Farmer has no current access to this log"
            );
        }

        return log;
    }
}
