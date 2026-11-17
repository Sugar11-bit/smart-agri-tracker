package com.smat.backend.productioncycle.dto;

import com.smat.backend.productioncycle.entity.ProductionCycle;

import java.time.LocalDate;

public record ProductionCycleResponse(Long id, Long organizationId, Long plantingId,
        String cycleCode, Integer cycleYear, LocalDate startDate, LocalDate endDate, String status) {
    public static ProductionCycleResponse from(ProductionCycle cycle) {
        return new ProductionCycleResponse(cycle.getId(), cycle.getOrganizationId(),
                cycle.getPlantingId(), cycle.getCycleCode(), cycle.getCycleYear(),
                cycle.getStartDate(), cycle.getEndDate(), cycle.getStatus());
    }
}
