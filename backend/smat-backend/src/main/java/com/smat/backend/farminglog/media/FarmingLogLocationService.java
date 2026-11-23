
package com.smat.backend.farminglog.media;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class FarmingLogLocationService {

    public record LocationRequest(
            Double latitude,
            Double longitude,
            Double accuracyMeters,
            OffsetDateTime capturedAt
    ) {}

    public record LocationResponse(
            Long farmingLogId,
            Double latitude,
            Double longitude,
            Double accuracyMeters,
            OffsetDateTime capturedAt
    ) {}

    public record SaveResult(
            LocationResponse location,
            boolean created
    ) {}

    private final JdbcTemplate jdbc;
    private final FarmingLogMediaAccessService access;

    public FarmingLogLocationService(
            JdbcTemplate jdbc,
            FarmingLogMediaAccessService access
    ) {
        this.jdbc = jdbc;
        this.access = access;
    }

    public SaveResult save(
            Jwt jwt,
            Long logId,
            LocationRequest request
    ) {
        access.requireWritableLog(jwt, logId);

        if (request == null ||
                request.latitude() == null ||
                request.longitude() == null ||
                request.accuracyMeters() == null ||
                request.capturedAt() == null ||
                !Double.isFinite(request.latitude()) ||
                !Double.isFinite(request.longitude()) ||
                !Double.isFinite(request.accuracyMeters()) ||
                Math.abs(request.latitude()) > 90 ||
                Math.abs(request.longitude()) > 180 ||
                request.accuracyMeters() < 0 ||
                request.accuracyMeters() >= 1000000) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid GPS data"
            );
        }

        String sql = """
            INSERT INTO farming_log_locations (
                farming_log_id,
                latitude,
                longitude,
                accuracy_meters,
                captured_at
            )
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT (farming_log_id) DO NOTHING
            RETURNING farming_log_id
            """;

        List<Long> inserted = jdbc.query(
                sql,
                (rs, index) ->
                        rs.getLong("farming_log_id"),
                logId,
                request.latitude(),
                request.longitude(),
                request.accuracyMeters(),
                request.capturedAt()
        );

        String selectSql = """
            SELECT
                farming_log_id,
                latitude,
                longitude,
                accuracy_meters,
                captured_at
            FROM farming_log_locations
            WHERE farming_log_id = ?
            """;

        LocationResponse saved = jdbc.queryForObject(
                selectSql,
                (rs, index) -> new LocationResponse(
                        rs.getLong("farming_log_id"),
                        rs.getDouble("latitude"),
                        rs.getDouble("longitude"),
                        rs.getDouble("accuracy_meters"),
                        rs.getObject(
                                "captured_at",
                                OffsetDateTime.class
                        )
                ),
                logId
        );

        boolean same =
                Double.compare(
                        saved.latitude(),
                        request.latitude()
                ) == 0
                        && Double.compare(
                        saved.longitude(),
                        request.longitude()
                ) == 0
                        && Double.compare(
                        saved.accuracyMeters(),
                        request.accuracyMeters()
                ) == 0
                        && saved.capturedAt().toInstant()
                        .equals(
                                request.capturedAt().toInstant()
                        );

        if (!same) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "GPS already exists with different data"
            );
        }

        return new SaveResult(
                saved,
                !inserted.isEmpty()
        );
    }
}
