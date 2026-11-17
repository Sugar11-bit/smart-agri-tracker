
package com.smat.backend.plot.repository;

import com.smat.backend.plot.entity.Plot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PlotRepository
        extends JpaRepository<Plot, Long> {

    List<Plot> findByOrganizationIdAndFarmId(
            Long organizationId, Long farmId
    );

    boolean existsByOrganizationIdAndPlotCode(
            Long organizationId, String plotCode
    );
    boolean existsByOrganizationIdAndId(
            Long organizationId, Long id
    );
}
