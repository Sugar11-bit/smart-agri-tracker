
package com.smat.backend.security.controller;

import com.smat.backend.security.service.OrganizationAccessService;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/access-test")
public class AdminAccessTestController {

    private final OrganizationAccessService access;

    public AdminAccessTestController(
            OrganizationAccessService access) {
        this.access = access;
    }

    @GetMapping
    public Map<String, String> test(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId) {

        access.requireAdmin(jwt, organizationId);

        return Map.of(
                "status", "ALLOWED",
                "role", "ADMIN"
        );
    }
}
