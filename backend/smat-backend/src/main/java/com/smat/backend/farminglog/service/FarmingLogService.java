
package com.smat.backend.farminglog.service;

import com.smat.backend.farminglog.dto.CreateFarmingLogRequest;
import com.smat.backend.farminglog.dto.FarmingLogResponse;
import com.smat.backend.farminglog.entity.FarmingLog;
import com.smat.backend.farminglog.repository.FarmingLogRepository;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.Date;
import java.sql.Types;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@Service
public class FarmingLogService {

    private static final Set<String> ACTIVITIES = Set.of(
            "WATERING",
            "FERTILIZING",
            "SPRAYING",
            "WEEDING",
            "PRUNING",
            "OTHER"
    );

    private final FarmingLogRepository logs;
    private final JdbcTemplate jdbc;

    public FarmingLogService(
            FarmingLogRepository logs,
            JdbcTemplate jdbc
    ) {
        this.logs = logs;
        this.jdbc = jdbc;
    }

    public record CreateResult(
            FarmingLogResponse log,
            boolean created
    ) {}

    @Transactional
    public CreateResult create(
            Jwt jwt,
            CreateFarmingLogRequest request
    ) {
        Long userId = authenticatedUserId(jwt);

        String activity = request.activityType().trim();
        String notes = request.notes() == null
                ? null
                : request.notes().trim();

        if (!ACTIVITIES.contains(activity)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Unsupported activity type"
            );
        }

        // Verify identity and active organization membership.
        requireActiveFarmer(
                userId,
                request.organizationId()
        );

        // Safe retry: return the original log only
        // when its owner and content match.
        var existing = logs.findByClientLogId(
                request.clientLogId()
        );

        if (existing.isPresent()) {
            return new CreateResult(
                    verifySameLog(
                            existing.get(),
                            userId,
                            request,
                            activity,
                            notes
                    ),
                    false
            );
        }

        // A new log requires a current plot assignment.
        requireAssignedPlot(
                userId,
                request.organizationId(),
                request.plotId()
        );

        requireValidCycle(request);

        // DB UNIQUE constraint handles concurrent requests.
        String sql = """
            INSERT INTO farming_logs (
                client_log_id,
                organization_id,
                farmer_user_id,
                plot_id,
                planting_id,
                production_cycle_id,
                activity_type,
                activity_date,
                notes,
                client_created_at
            )
            VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
            ON CONFLICT (client_log_id) DO NOTHING
            RETURNING id
            """;

        List<Long> inserted = jdbc.query(
                sql,
                (rs, index) -> rs.getLong("id"),
                request.clientLogId(),
                request.organizationId(),
                userId,
                request.plotId(),
                request.plantingId(),
                request.productionCycleId(),
                activity,
                Date.valueOf(request.activityDate()),
                notes,
                request.clientCreatedAt()
        );

        if (!inserted.isEmpty()) {
            FarmingLog saved = logs.findById(
                    inserted.get(0)
            ).orElseThrow();

            return new CreateResult(
                    FarmingLogResponse.from(saved),
                    true
            );
        }

        // Another request inserted the same UUID.
        FarmingLog saved = logs.findByClientLogId(
                request.clientLogId()
        ).orElseThrow(() ->
                new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Retry the request"
                )
        );

        return new CreateResult(
                verifySameLog(
                        saved, userId, request,
                        activity, notes
                ),
                false
        );
    }

    private Long authenticatedUserId(Jwt jwt) {
        if (jwt == null || jwt.getSubject() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        try {
            return Long.valueOf(jwt.getSubject());
        } catch (NumberFormatException ex) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }
    }

    private void requireActiveFarmer(
            Long userId,
            Long organizationId
    ) {
        String sql = """
            SELECT EXISTS (
                SELECT 1
                FROM users u
                JOIN organization_memberships m
                  ON m.user_id = u.id
                JOIN organizations o
                  ON o.id = m.organization_id
                WHERE u.id = ?
                  AND m.organization_id = ?
                  AND u.is_active = TRUE
                  AND m.is_active = TRUE
                  AND m.role = 'FARMER'
                  AND o.status = 'ACTIVE'
            )
            """;

        Boolean allowed = jdbc.queryForObject(
                sql, Boolean.class, userId, organizationId
        );

        if (!Boolean.TRUE.equals(allowed)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Active FARMER membership required"
            );
        }
    }

    private void requireAssignedPlot(
            Long userId,
            Long organizationId,
            Long plotId
    ) {
        String sql = """
            SELECT EXISTS (
                SELECT 1
                FROM plot_assignments pa
                JOIN organization_memberships m
                  ON m.id = pa.membership_id
                 AND m.organization_id = pa.organization_id
                JOIN plots p
                  ON p.id = pa.plot_id
                 AND p.organization_id = pa.organization_id
                WHERE m.user_id = ?
                  AND pa.organization_id = ?
                  AND pa.plot_id = ?
                  AND m.role = 'FARMER'
                  AND m.is_active = TRUE
                  AND pa.ended_at IS NULL
                  AND p.status = 'ACTIVE'
            )
            """;

        Boolean allowed = jdbc.queryForObject(
                sql,
                Boolean.class,
                userId,
                organizationId,
                plotId
        );

        if (!Boolean.TRUE.equals(allowed)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No active FARMER assignment for plot"
            );
        }
    }

    private void requireValidCycle(
            CreateFarmingLogRequest request
    ) {
        String sql = """
            SELECT EXISTS (
                SELECT 1
                FROM production_cycles c
                JOIN plantings p
                  ON p.id = c.planting_id
                 AND p.organization_id = c.organization_id
                WHERE c.organization_id = ?
                  AND p.plot_id = ?
                  AND p.id = ?
                  AND c.id = ?
                  AND p.status = 'ACTIVE'
            )
            """;

        Boolean valid = jdbc.queryForObject(
                sql,
                Boolean.class,
                request.organizationId(),
                request.plotId(),
                request.plantingId(),
                request.productionCycleId()
        );

        if (!Boolean.TRUE.equals(valid)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Planting or production cycle is invalid"
            );
        }
    }

    private FarmingLogResponse verifySameLog(
            FarmingLog saved,
            Long userId,
            CreateFarmingLogRequest request,
            String activity,
            String notes
    ) {
        boolean same =
                Objects.equals(
                        saved.getFarmerUserId(), userId
                )
                        && Objects.equals(
                        saved.getOrganizationId(),
                        request.organizationId()
                )
                        && Objects.equals(
                        saved.getPlotId(), request.plotId()
                )
                        && Objects.equals(
                        saved.getPlantingId(),
                        request.plantingId()
                )
                        && Objects.equals(
                        saved.getProductionCycleId(),
                        request.productionCycleId()
                )
                        && Objects.equals(
                        saved.getActivityType(), activity
                )
                        && Objects.equals(
                        saved.getActivityDate(),
                        request.activityDate()
                )
                        && Objects.equals(
                        saved.getNotes(), notes
                )
                        && saved.getClientCreatedAt()
                        .toInstant()
                        .equals(
                                request.clientCreatedAt().toInstant()
                        );

        if (!same) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Client log ID already used"
            );
        }

        return FarmingLogResponse.from(saved);
    }
}
