
package com.smat.backend.assignment.dto;

import jakarta.validation.constraints.NotNull;

public record CreatePlotAssignmentRequest(
        @NotNull Long plotId,
        @NotNull Long membershipId
) {}
