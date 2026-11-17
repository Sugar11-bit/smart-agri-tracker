
package com.smat.backend.plot.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record CreatePlotRequest(
        @NotNull Long farmId,
        @NotBlank @Size(max = 40) String plotCode,
        @NotBlank @Size(max = 150) String plotName,
        @NotNull @DecimalMin("0.0001")
        @Digits(integer = 8, fraction = 4)
        BigDecimal areaHectares
) {}
