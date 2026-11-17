
package com.smat.backend.assignment.controller;

import com.smat.backend.assignment.dto.*;
import com.smat.backend.assignment.service.PlotAssignmentService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/plot-assignments")
public class AdminPlotAssignmentController {

    private final PlotAssignmentService service;

    public AdminPlotAssignmentController(
            PlotAssignmentService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PlotAssignmentResponse create(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId,
            @Valid @RequestBody
            CreatePlotAssignmentRequest request) {

        return service.create(
                jwt, organizationId, request
        );
    }

    @GetMapping
    public List<PlotAssignmentResponse> findByPlot(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId,
            @RequestParam Long plotId) {

        return service.findByPlot(
                jwt, organizationId, plotId
        );
    }

    @PatchMapping("/{id}/end")
    public PlotAssignmentResponse end(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam Long organizationId,
            @PathVariable Long id) {

        return service.end(jwt, organizationId, id);
    }
}
