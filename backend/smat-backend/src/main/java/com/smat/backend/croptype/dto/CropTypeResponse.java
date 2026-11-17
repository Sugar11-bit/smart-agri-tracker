
package com.smat.backend.croptype.dto;

public record CropTypeResponse(
        Long id,
        String cropCode,
        String cropName,
        String lifeCycle
) {}
