
package com.smat.backend.farmercatalog.service;

import com.smat.backend.assignment.service.MyPlotsService;

import com.smat.backend.planting.dto.PlantingResponse;
import com.smat.backend.planting.entity.Planting;
import com.smat.backend.planting.repository.PlantingRepository;

import com.smat.backend.productioncycle.dto.ProductionCycleResponse;
import com.smat.backend.productioncycle.repository.ProductionCycleRepository;

import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Objects;

@Service
public class FarmerCatalogService {

    private final MyPlotsService myPlotsService;
    private final PlantingRepository plantingRepository;
    private final ProductionCycleRepository cycleRepository;

    public FarmerCatalogService(
            MyPlotsService myPlotsService,
            PlantingRepository plantingRepository,
            ProductionCycleRepository cycleRepository
    ) {
        this.myPlotsService = myPlotsService;
        this.plantingRepository = plantingRepository;
        this.cycleRepository = cycleRepository;
    }

    private void requirePlotAccess(
            Jwt jwt,
            Long organizationId,
            Long plotId
    ) {
        boolean allowed = myPlotsService.getMyPlots(jwt)
                .stream()
                .anyMatch(plot ->
                        Objects.equals(
                                plot.organizationId(),
                                organizationId
                        )
                                && Objects.equals(
                                plot.plotId(),
                                plotId
                        )
                                && "FARMER".equals(plot.role())
                );

        if (!allowed) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Farmer is not assigned to this Plot"
            );
        }
    }

    @Transactional(readOnly = true)
    public List<PlantingResponse> getPlantings(
            Jwt jwt,
            Long organizationId,
            Long plotId
    ) {
        requirePlotAccess(jwt, organizationId, plotId);

        return plantingRepository
                .findByOrganizationIdAndPlotId(
                        organizationId,
                        plotId
                )
                .stream()
                .filter(planting ->
                        "ACTIVE".equals(planting.getStatus())
                )
                .map(planting -> new PlantingResponse(
                        planting.getId(),
                        planting.getPlotId(),
                        planting.getCropTypeId(),
                        planting.getPlantingCode(),
                        planting.getStatus()
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductionCycleResponse> getCycles(
            Jwt jwt,
            Long organizationId,
            Long plantingId
    ) {
        Planting planting = plantingRepository
                .findByOrganizationIdAndId(
                        organizationId,
                        plantingId
                )
                .filter(p -> "ACTIVE".equals(p.getStatus()))
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Active Planting not found"
                        )
                );

        requirePlotAccess(
                jwt,
                organizationId,
                planting.getPlotId()
        );

        return cycleRepository
                .findByOrganizationIdAndPlantingIdOrderByIdAsc(
                        organizationId,
                        plantingId
                )
                .stream()
                .map(ProductionCycleResponse::from)
                .toList();
    }
}
