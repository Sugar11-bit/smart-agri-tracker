package com.smat.backend.productioncycle.repository;

import com.smat.backend.productioncycle.entity.ProductionCycle;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ProductionCycleRepository extends JpaRepository<ProductionCycle, Long> {
    boolean existsByOrganizationIdAndCycleCode(Long organizationId, String cycleCode);
    List<ProductionCycle> findByOrganizationIdAndPlantingIdOrderByIdAsc(Long organizationId, Long plantingId);
}
