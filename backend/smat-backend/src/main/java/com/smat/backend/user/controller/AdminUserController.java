
package com.smat.backend.user.controller;

import com.smat.backend.user.dto.*;
import com.smat.backend.user.service.AdminUserService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/users")
public class AdminUserController {

    private final AdminUserService service;

    public AdminUserController(AdminUserService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StaffResponse create(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId,
            @Valid @RequestBody CreateStaffRequest request) {

        return service.create(
                jwt,
                organizationId,
                request
        );
    }
}
