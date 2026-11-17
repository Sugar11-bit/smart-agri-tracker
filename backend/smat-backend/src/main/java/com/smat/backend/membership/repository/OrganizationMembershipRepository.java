
package com.smat.backend.membership.repository;

import com.smat.backend.membership.entity.OrganizationMembership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface OrganizationMembershipRepository
        extends JpaRepository<OrganizationMembership, Long> {

    // A membership grants access only while its organization is active.
    @Query("""
            select m from OrganizationMembership m, Organization o
            where m.organizationId = o.id and m.userId = :userId
              and m.active = true and o.status = 'ACTIVE'
            """)
    List<OrganizationMembership> findByUserIdAndActiveTrue(
            @Param("userId") Long userId
    );

    boolean existsByOrganizationIdAndUserIdAndRoleAndActiveTrue(
            Long organizationId,
            Long userId,
            String role
    );
}
