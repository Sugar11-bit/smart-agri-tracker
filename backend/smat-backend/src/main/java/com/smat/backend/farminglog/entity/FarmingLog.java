
package com.smat.backend.farminglog.entity;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "farming_logs")
public class FarmingLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "client_log_id", nullable = false, unique = true)
    private UUID clientLogId;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "farmer_user_id", nullable = false)
    private Long farmerUserId;

    @Column(name = "plot_id", nullable = false)
    private Long plotId;

    @Column(name = "planting_id", nullable = false)
    private Long plantingId;

    @Column(name = "production_cycle_id", nullable = false)
    private Long productionCycleId;

    @Column(name = "activity_type", nullable = false, length = 40)
    private String activityType;

    @Column(name = "activity_date", nullable = false)
    private LocalDate activityDate;

    @Column(name = "notes")
    private String notes;

    @Column(name = "client_created_at", nullable = false)
    private OffsetDateTime clientCreatedAt;

    @Column(name = "server_received_at",
            insertable = false, updatable = false)
    private OffsetDateTime serverReceivedAt;

    protected FarmingLog() {
    }

    public FarmingLog(
            UUID clientLogId,
            Long organizationId,
            Long farmerUserId,
            Long plotId,
            Long plantingId,
            Long productionCycleId,
            String activityType,
            LocalDate activityDate,
            String notes,
            OffsetDateTime clientCreatedAt
    ) {
        this.clientLogId = clientLogId;
        this.organizationId = organizationId;
        this.farmerUserId = farmerUserId;
        this.plotId = plotId;
        this.plantingId = plantingId;
        this.productionCycleId = productionCycleId;
        this.activityType = activityType;
        this.activityDate = activityDate;
        this.notes = notes;
        this.clientCreatedAt = clientCreatedAt;
    }

    public Long getId() { return id; }
    public UUID getClientLogId() { return clientLogId; }
    public Long getOrganizationId() { return organizationId; }
    public Long getFarmerUserId() { return farmerUserId; }
    public Long getPlotId() { return plotId; }
    public Long getPlantingId() { return plantingId; }
    public Long getProductionCycleId() { return productionCycleId; }
    public String getActivityType() { return activityType; }
    public LocalDate getActivityDate() { return activityDate; }
    public String getNotes() { return notes; }
    public OffsetDateTime getClientCreatedAt() { return clientCreatedAt; }
    public OffsetDateTime getServerReceivedAt() { return serverReceivedAt; }
}
