
package com.smat.backend.planting.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record CreatePlantingRequest(

        @NotNull
        Long plotId,

        @NotNull
        Long cropTypeId,

        Long varietyId,

        @NotBlank
        @Size(max = 40)
        String plantingCode,

        LocalDate plantedAt

) {}
