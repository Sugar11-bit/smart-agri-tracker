
package com.smat.backend.planting.dto;

public record PlantingResponse(
        Long id,
        Long plotId,
        Long cropTypeId,
        String plantingCode,
        String status
) {}
