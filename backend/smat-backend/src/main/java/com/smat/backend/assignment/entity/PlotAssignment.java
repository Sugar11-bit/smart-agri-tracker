
package com.smat.backend.assignment.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "plot_assignments")
public class PlotAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "plot_id", nullable = false)
    private Long plotId;

    @Column(name = "membership_id", nullable = false)
    private Long membershipId;

    @Column(name = "assigned_by", nullable = false)
    private Long assignedBy;

    @Column(name = "assigned_at", nullable = false)
    private OffsetDateTime assignedAt;

    @Column(name = "ended_at")
    private OffsetDateTime endedAt;

    protected PlotAssignment() {}

    public PlotAssignment(
            Long organizationId,
            Long plotId,
            Long membershipId,
            Long assignedBy) {

        this.organizationId = organizationId;
        this.plotId = plotId;
        this.membershipId = membershipId;
        this.assignedBy = assignedBy;
        this.assignedAt = OffsetDateTime.now();
    }

    public void end(OffsetDateTime time) {
        if (endedAt != null) {
            throw new IllegalStateException(
                    "Assignment already ended"
            );
        }
        if (time.isBefore(assignedAt)) {
            throw new IllegalArgumentException(
                    "End time cannot precede assignment"
            );
        }
        this.endedAt = time;
    }

    public Long getId() { return id; }
    public Long getOrganizationId() { return organizationId; }
    public Long getPlotId() { return plotId; }
    public Long getMembershipId() { return membershipId; }
    public Long getAssignedBy() { return assignedBy; }
    public OffsetDateTime getAssignedAt() { return assignedAt; }
    public OffsetDateTime getEndedAt() { return endedAt; }
}
