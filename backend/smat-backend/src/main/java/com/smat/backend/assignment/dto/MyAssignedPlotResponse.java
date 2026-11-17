
package com.smat.backend.assignment.dto;

public record MyAssignedPlotResponse(
        Long organizationId,
        Long plotId,
        String plotCode,
        String plotName,
        String role
) {}
