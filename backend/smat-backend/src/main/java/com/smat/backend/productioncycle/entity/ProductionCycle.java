package com.smat.backend.productioncycle.entity;

import com.smat.backend.productioncycle.dto.CreateProductionCycleRequest;
import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "production_cycles")
public class ProductionCycle {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "organization_id", nullable = false)
    private Long organizationId;
    @Column(name = "planting_id", nullable = false)
    private Long plantingId;
    @Column(name = "cycle_code", nullable = false, length = 40)
    private String cycleCode;
    @Column(name = "cycle_year")
    private Integer cycleYear;
    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;
    @Column(name = "end_date")
    private LocalDate endDate;
    @Column(nullable = false, length = 20)
    private String status;

    protected ProductionCycle() {}

    public ProductionCycle(Long organizationId, CreateProductionCycleRequest request) {
        this.organizationId = organizationId;
        this.plantingId = request.plantingId();
        this.cycleCode = request.cycleCode().trim();
        this.cycleYear = request.cycleYear();
        this.startDate = request.startDate();
        this.endDate = request.endDate();
        this.status = "DRAFT";
    }

    public Long getId() { return id; }
    public Long getOrganizationId() { return organizationId; }
    public Long getPlantingId() { return plantingId; }
    public String getCycleCode() { return cycleCode; }
    public Integer getCycleYear() { return cycleYear; }
    public LocalDate getStartDate() { return startDate; }
    public LocalDate getEndDate() { return endDate; }
    public String getStatus() { return status; }
}
