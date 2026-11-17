
package com.smat.backend.assignment.dto;

import java.time.OffsetDateTime;

public record PlotAssignmentResponse(
        Long id,
        Long organizationId,
        Long plotId,
        Long membershipId,
        Long assignedBy,
        OffsetDateTime assignedAt,
        OffsetDateTime endedAt
) {}
