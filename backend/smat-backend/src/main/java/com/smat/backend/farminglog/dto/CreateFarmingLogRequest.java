
package com.smat.backend.farminglog.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public record CreateFarmingLogRequest(

        @NotNull
        UUID clientLogId,

        @NotNull
        @Positive
        Long organizationId,

        @NotNull
        @Positive
        Long plotId,

        @NotNull
        @Positive
        Long plantingId,

        @NotNull
        @Positive
        Long productionCycleId,

        @NotBlank
        @Size(max = 40)
        String activityType,

        @NotNull
        LocalDate activityDate,

        @Size(max = 5000)
        String notes,

        @NotNull
        OffsetDateTime clientCreatedAt
) {
}
