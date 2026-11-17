package com.smat.backend.productioncycle.service;

import com.smat.backend.planting.repository.PlantingRepository;
import com.smat.backend.productioncycle.dto.CreateProductionCycleRequest;
import com.smat.backend.productioncycle.dto.ProductionCycleResponse;
import com.smat.backend.productioncycle.entity.ProductionCycle;
import com.smat.backend.productioncycle.repository.ProductionCycleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class ProductionCycleService {
    private final ProductionCycleRepository cycles;
    private final PlantingRepository plantings;

    public ProductionCycleService(ProductionCycleRepository cycles, PlantingRepository plantings) {
        this.cycles = cycles;
        this.plantings = plantings;
    }

    @Transactional
    public ProductionCycleResponse create(
            Long organizationId,
            CreateProductionCycleRequest request) {
        requirePlanting(organizationId, request.plantingId());
        if (request.endDate() != null && request.endDate().isBefore(request.startDate())) {
            throw new IllegalArgumentException("End date must not precede start date");
        }
        if (cycles.existsByOrganizationIdAndCycleCode(organizationId, request.cycleCode().trim())) {
            throw new IllegalStateException("Cycle code already exists");
        }
        return ProductionCycleResponse.from(cycles.save(new ProductionCycle(organizationId, request)));
    }

    @Transactional(readOnly = true)
    public List<ProductionCycleResponse> list(Long organizationId, Long plantingId) {
        requirePlanting(organizationId, plantingId);
        return cycles.findByOrganizationIdAndPlantingIdOrderByIdAsc(organizationId, plantingId)
                .stream().map(ProductionCycleResponse::from).toList();
    }

    private void requirePlanting(Long organizationId, Long plantingId) {
        if (!plantings.existsByOrganizationIdAndId(organizationId, plantingId)) {
            throw new IllegalArgumentException("Planting does not belong to organization");
        }
    }
}
