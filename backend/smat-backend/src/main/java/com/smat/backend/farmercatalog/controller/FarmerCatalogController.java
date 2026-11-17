
package com.smat.backend.farmercatalog.controller;

import com.smat.backend.farmercatalog.service.FarmerCatalogService;
import com.smat.backend.planting.dto.PlantingResponse;
import com.smat.backend.productioncycle.dto.ProductionCycleResponse;

import jakarta.validation.constraints.Positive;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Validated
@RestController
@RequestMapping("/api/v1/me")
public class FarmerCatalogController {

    private final FarmerCatalogService service;

    public FarmerCatalogController(
            FarmerCatalogService service
    ) {
        this.service = service;
    }

    @GetMapping("/plantings")
    public List<PlantingResponse> getPlantings(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam @Positive Long organizationId,
            @RequestParam @Positive Long plotId
    ) {
        return service.getPlantings(
                jwt,
                organizationId,
                plotId
        );
    }

    @GetMapping("/production-cycles")
    public List<ProductionCycleResponse> getCycles(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam @Positive Long organizationId,
            @RequestParam @Positive Long plantingId
    ) {
        return service.getCycles(
                jwt,
                organizationId,
                plantingId
        );
    }
}
