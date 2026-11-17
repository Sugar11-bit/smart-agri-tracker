
package com.smat.backend.user.dto;

import jakarta.validation.constraints.*;

public record CreateStaffRequest(

        @NotBlank
        @Size(max = 60)
        String username,

        @NotBlank
        @Size(min = 8, max = 72)
        String password,

        @NotBlank
        @Size(max = 150)
        String fullName,

        @NotBlank
        String role
) {}
