
package com.smat.backend.assignment.service;

import com.smat.backend.assignment.dto.*;
import com.smat.backend.assignment.entity.PlotAssignment;
import com.smat.backend.assignment.repository.PlotAssignmentRepository;
import com.smat.backend.membership.repository.OrganizationMembershipRepository;
import com.smat.backend.plot.repository.PlotRepository;
import com.smat.backend.security.service.OrganizationAccessService;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class PlotAssignmentService {

    private final PlotAssignmentRepository assignments;
    private final OrganizationMembershipRepository memberships;
    private final PlotRepository plots;
    private final OrganizationAccessService access;

    public PlotAssignmentService(
            PlotAssignmentRepository assignments,
            OrganizationMembershipRepository memberships,
            PlotRepository plots,
            OrganizationAccessService access) {

        this.assignments = assignments;
        this.memberships = memberships;
        this.plots = plots;
        this.access = access;
    }

    @Transactional
    public PlotAssignmentResponse create(
            Jwt jwt,
            Long organizationId,
            CreatePlotAssignmentRequest request) {

        access.requireAdmin(jwt, organizationId);

        if (!plots.existsByOrganizationIdAndId(
                organizationId, request.plotId())) {
            throw new IllegalArgumentException(
                    "Plot does not belong to organization"
            );
        }

        var membership = memberships.findById(
                request.membershipId()
        ).orElseThrow(() ->
                new IllegalArgumentException(
                        "Membership not found"
                )
        );

        if (!organizationId.equals(
                membership.getOrganizationId())) {
            throw new IllegalArgumentException(
                    "Membership belongs to another organization"
            );
        }

        if (!Boolean.TRUE.equals(membership.getActive())) {
            throw new IllegalArgumentException(
                    "Membership is inactive"
            );
        }

        String role = membership.getRole();

        if (!"FARMER".equals(role) && !"QC".equals(role)) {
            throw new IllegalArgumentException(
                    "Only FARMER or QC can be assigned"
            );
        }

        if (assignments
                .existsByOrganizationIdAndPlotIdAndMembershipIdAndEndedAtIsNull(
                        organizationId,
                        request.plotId(),
                        request.membershipId())) {
            throw new IllegalStateException(
                    "Active assignment already exists"
            );
        }

        Long adminUserId = Long.valueOf(jwt.getSubject());

        var saved = assignments.saveAndFlush(
                new PlotAssignment(
                        organizationId,
                        request.plotId(),
                        request.membershipId(),
                        adminUserId
                )
        );

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PlotAssignmentResponse> findByPlot(
            Jwt jwt,
            Long organizationId,
            Long plotId) {

        access.requireAdmin(jwt, organizationId);

        if (!plots.existsByOrganizationIdAndId(
                organizationId, plotId)) {
            throw new IllegalArgumentException(
                    "Plot does not belong to organization"
            );
        }

        return assignments
                .findByOrganizationIdAndPlotIdOrderByAssignedAtDesc(
                        organizationId, plotId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public PlotAssignmentResponse end(
            Jwt jwt,
            Long organizationId,
            Long assignmentId) {

        access.requireAdmin(jwt, organizationId);

        var assignment = assignments
                .findByIdAndOrganizationId(
                        assignmentId, organizationId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Assignment not found"
                        )
                );

        assignment.end(OffsetDateTime.now());

        return toResponse(
                assignments.saveAndFlush(assignment)
        );
    }

    private PlotAssignmentResponse toResponse(
            PlotAssignment assignment) {

        return new PlotAssignmentResponse(
                assignment.getId(),
                assignment.getOrganizationId(),
                assignment.getPlotId(),
                assignment.getMembershipId(),
                assignment.getAssignedBy(),
                assignment.getAssignedAt(),
                assignment.getEndedAt()
        );
    }
}
