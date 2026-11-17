package com.smat.backend.productioncycle.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

public record CreateProductionCycleRequest(
        @NotNull @Positive Long plantingId,
        @NotBlank @Size(max = 40) String cycleCode,
        @Min(1900) @Max(2200) Integer cycleYear,
        @NotNull LocalDate startDate,
        LocalDate endDate) {}
