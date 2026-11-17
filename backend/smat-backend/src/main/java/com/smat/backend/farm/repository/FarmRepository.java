
package com.smat.backend.farm.repository;

import com.smat.backend.farm.entity.Farm;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FarmRepository
        extends JpaRepository<Farm, Long> {

    List<Farm> findByOrganizationId(Long organizationId);
    boolean existsByOrganizationIdAndFarmCode(
            Long organizationId,
            String farmCode
    );
    boolean existsByOrganizationIdAndId(
            Long organizationId,
            Long id
    );
}
