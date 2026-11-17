
package com.smat.backend.farm.controller;

import com.smat.backend.farm.dto.CreateFarmRequest;
import com.smat.backend.farm.dto.FarmResponse;
import com.smat.backend.farm.service.FarmService;
import com.smat.backend.security.service.OrganizationAccessService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/farms")
public class AdminFarmController {

    private final FarmService farmService;
    private final OrganizationAccessService access;

    public AdminFarmController(
            FarmService farmService,
            OrganizationAccessService access) {

        this.farmService = farmService;
        this.access = access;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FarmResponse create(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId,
            @Valid @RequestBody CreateFarmRequest request) {

        access.requireAdmin(jwt, organizationId);

        return farmService.create(organizationId, request);
    }
}
