
package com.smat.backend.farminglog.repository;

import com.smat.backend.farminglog.entity.FarmingLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FarmingLogRepository
        extends JpaRepository<FarmingLog, Long> {

    Optional<FarmingLog> findByClientLogId(
            UUID clientLogId
    );

    List<FarmingLog>
    findByOrganizationIdAndFarmerUserIdOrderByIdDesc(
            Long organizationId,
            Long farmerUserId
    );

    List<FarmingLog>
    findByOrganizationIdAndPlotIdOrderByIdDesc(
            Long organizationId,
            Long plotId
    );
}
