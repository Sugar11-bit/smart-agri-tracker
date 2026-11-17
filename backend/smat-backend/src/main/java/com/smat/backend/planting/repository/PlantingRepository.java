
package com.smat.backend.planting.repository;

import com.smat.backend.planting.entity.Planting;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlantingRepository
        extends JpaRepository<Planting, Long> {

    boolean existsByOrganizationIdAndPlantingCode(
            Long organizationId,
            String plantingCode
    );

    boolean existsByOrganizationIdAndId(
            Long organizationId,
            Long id
    );
    Optional<Planting> findByOrganizationIdAndId(
            Long organizationId,
            Long id
    );
    List<Planting> findByOrganizationIdAndPlotId(
            Long organizationId,
            Long plotId
    );
}
