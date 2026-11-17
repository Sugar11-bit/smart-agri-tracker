
package com.smat.backend.user.dto;

public record StaffResponse(
        Long userId,
        Long membershipId,
        Long organizationId,
        String username,
        String fullName,
        String role
) {}
