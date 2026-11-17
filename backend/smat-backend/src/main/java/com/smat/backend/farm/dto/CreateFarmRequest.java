
package com.smat.backend.farm.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateFarmRequest(
        @NotBlank
        @Size(max = 40)
        String farmCode,

        @NotBlank
        @Size(max = 150)
        String farmName,

        String addressText
) {}
