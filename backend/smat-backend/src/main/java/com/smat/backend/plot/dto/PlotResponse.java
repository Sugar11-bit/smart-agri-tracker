
package com.smat.backend.plot.dto;

import java.math.BigDecimal;

public record PlotResponse(
        Long id,
        Long farmId,
        String plotCode,
        String plotName,
        BigDecimal areaHectares
) {}
