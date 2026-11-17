
package com.smat.backend.auth.dto;

import java.util.List;

public record AuthMeResponse(
        Long userId,
        String username,
        String fullName,
        List<MembershipInfo> memberships
) {
    public record MembershipInfo(
            Long organizationId,
            String role
    ) {}
}
