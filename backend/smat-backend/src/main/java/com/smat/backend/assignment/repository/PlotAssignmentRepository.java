
package com.smat.backend.assignment.repository;

import com.smat.backend.assignment.entity.PlotAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlotAssignmentRepository
        extends JpaRepository<PlotAssignment, Long> {

    boolean existsByOrganizationIdAndPlotIdAndMembershipIdAndEndedAtIsNull(
            Long organizationId,
            Long plotId,
            Long membershipId
    );

    List<PlotAssignment>
    findByOrganizationIdAndPlotIdOrderByAssignedAtDesc(
            Long organizationId,
            Long plotId
    );

    Optional<PlotAssignment> findByIdAndOrganizationId(
            Long id,
            Long organizationId
    );
}
