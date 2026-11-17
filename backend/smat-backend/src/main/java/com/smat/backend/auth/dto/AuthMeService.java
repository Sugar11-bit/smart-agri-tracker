
package com.smat.backend.auth.service;

import com.smat.backend.auth.dto.AuthMeResponse;
import com.smat.backend.membership.repository.OrganizationMembershipRepository;
import com.smat.backend.user.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthMeService {

    private final UserRepository users;
    private final OrganizationMembershipRepository memberships;

    public AuthMeService(
            UserRepository users,
            OrganizationMembershipRepository memberships) {
        this.users = users;
        this.memberships = memberships;
    }

    @Transactional(readOnly = true)
    public AuthMeResponse getCurrentUser(Jwt jwt) {

        Long userId;

        try {
            userId = Long.valueOf(jwt.getSubject());
        } catch (NumberFormatException e) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Invalid token subject"
            );
        }

        var user = users.findById(userId)
                .filter(u -> Boolean.TRUE.equals(u.getActive()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Account is inactive"
                ));

        var activeMemberships =
                memberships.findByUserIdAndActiveTrue(userId);

        var result = activeMemberships.stream()
                .map(m -> new AuthMeResponse.MembershipInfo(
                        m.getOrganizationId(),
                        m.getRole()
                ))
                .toList();

        return new AuthMeResponse(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                result
        );
    }
}
