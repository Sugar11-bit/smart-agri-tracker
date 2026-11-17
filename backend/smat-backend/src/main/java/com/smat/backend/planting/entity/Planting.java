
package com.smat.backend.planting.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "plantings")
public class Planting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "plot_id", nullable = false)
    private Long plotId;

    @Column(name = "crop_type_id", nullable = false)
    private Long cropTypeId;

    @Column(name = "variety_id")
    private Long varietyId;

    @Column(name = "planting_code", nullable = false)
    private String plantingCode;

    @Column(name = "planted_at")
    private LocalDate plantedAt;

    @Column(name = "status", nullable = false)
    private String status;

    protected Planting() {}

    public Planting(
            Long organizationId,
            Long plotId,
            Long cropTypeId,
            Long varietyId,
            String plantingCode,
            LocalDate plantedAt) {
        this.organizationId = organizationId;
        this.plotId = plotId;
        this.cropTypeId = cropTypeId;
        this.varietyId = varietyId;
        this.plantingCode = plantingCode;
        this.plantedAt = plantedAt;
        this.status = "ACTIVE";
    }

    public Long getId() { return id; }
    public Long getOrganizationId() { return organizationId; }
    public Long getPlotId() { return plotId; }
    public Long getCropTypeId() { return cropTypeId; }
    public String getPlantingCode() { return plantingCode; }
    public String getStatus() { return status; }
}
