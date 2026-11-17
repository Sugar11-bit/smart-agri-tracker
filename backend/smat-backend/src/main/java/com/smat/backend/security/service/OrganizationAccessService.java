
package com.smat.backend.security.service;

import com.smat.backend.membership.repository.OrganizationMembershipRepository;
import com.smat.backend.user.repository.UserRepository;
import com.smat.backend.organization.repository.OrganizationRepository;

import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class OrganizationAccessService {

    private final OrganizationMembershipRepository memberships;
    private final UserRepository users;
    private final OrganizationRepository organizations;

    public OrganizationAccessService(
            OrganizationMembershipRepository memberships,
            UserRepository users,
            OrganizationRepository organizations) {

        this.memberships = memberships;
        this.users = users;
        this.organizations = organizations;
    }

    @Transactional(readOnly = true)
    public void requireAdmin(
            Jwt jwt,
            Long organizationId) {

        if (jwt == null || organizationId == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        Long userId;

        try {
            userId = Long.valueOf(jwt.getSubject());
        } catch (NumberFormatException e) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        boolean userActive = users.findById(userId)
                .map(u -> Boolean.TRUE.equals(u.getActive()))
                .orElse(false);

        if (!userActive) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED
            );
        }

        boolean organizationActive = organizations.findById(organizationId)
                .map(o -> "ACTIVE".equals(o.getStatus()))
                .orElse(false);

        if (!organizationActive) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Organization is not active"
            );
        }

        boolean allowed =
                memberships
                        .existsByOrganizationIdAndUserIdAndRoleAndActiveTrue(
                                organizationId,
                                userId,
                                "ADMIN"
                        );

        if (!allowed) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No ADMIN permission for this organization"
            );
        }
        var organization = organizations.findById(organizationId)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.FORBIDDEN,
                                "Organization unavailable"
                        )
                );

        if (!"ACTIVE".equals(organization.getStatus())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Organization is not active"
            );
        }
    }


}
