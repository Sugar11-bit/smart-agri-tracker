
package com.smat.backend.farminglog.dto;

import com.smat.backend.farminglog.entity.FarmingLog;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public record FarmingLogResponse(
        Long id,
        UUID clientLogId,
        Long organizationId,
        Long farmerUserId,
        Long plotId,
        Long plantingId,
        Long productionCycleId,
        String activityType,
        LocalDate activityDate,
        String notes,
        OffsetDateTime clientCreatedAt,
        OffsetDateTime serverReceivedAt
) {
    public static FarmingLogResponse from(FarmingLog log) {
        return new FarmingLogResponse(
                log.getId(),
                log.getClientLogId(),
                log.getOrganizationId(),
                log.getFarmerUserId(),
                log.getPlotId(),
                log.getPlantingId(),
                log.getProductionCycleId(),
                log.getActivityType(),
                log.getActivityDate(),
                log.getNotes(),
                log.getClientCreatedAt(),
                log.getServerReceivedAt()
        );
    }
}
