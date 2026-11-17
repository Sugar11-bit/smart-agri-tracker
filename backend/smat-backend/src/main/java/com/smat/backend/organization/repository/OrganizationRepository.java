
package com.smat.backend.organization.repository;

import com.smat.backend.organization.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrganizationRepository
        extends JpaRepository<Organization, Long> {

}
