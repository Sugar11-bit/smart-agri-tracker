
package com.smat.backend.plot.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "plots")
public class Plot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "plot_code", nullable = false)
    private String plotCode;

    @Column(name = "plot_name", nullable = false)
    private String plotName;

    @Column(name = "area_hectares", nullable = false)
    private java.math.BigDecimal areaHectares;

    @Column(nullable = false)
    private String status = "ACTIVE";

    protected Plot() {}

    public Plot(Long organizationId, Long farmId,
                String plotCode, String plotName,
                java.math.BigDecimal areaHectares) {
        this.organizationId = organizationId;
        this.farmId = farmId;
        this.plotCode = plotCode;
        this.plotName = plotName;
        this.areaHectares = areaHectares;
    }

    public Long getId() { return id; }
    public Long getFarmId() { return farmId; }
    public String getPlotCode() { return plotCode; }
    public String getPlotName() { return plotName; }
    public java.math.BigDecimal getAreaHectares() {
        return areaHectares;
    }
}
