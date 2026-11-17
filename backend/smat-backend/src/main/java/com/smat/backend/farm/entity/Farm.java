
package com.smat.backend.farm.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "farms")
public class Farm {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "farm_code", nullable = false)
    private String farmCode;

    @Column(name = "farm_name", nullable = false)
    private String farmName;

    @Column(name = "address_text")
    private String addressText;

    @Column(nullable = false)
    private String status;

    protected Farm() {
        // Required by JPA
    }

    public Long getId() {
        return id;
    }

    public Long getOrganizationId() {
        return organizationId;
    }

    public String getFarmCode() {
        return farmCode;
    }

    public String getFarmName() {
        return farmName;
    }


    public Farm(Long organizationId, String farmCode, String farmName, String addressText) {
        this.organizationId = organizationId;
        this.farmCode = farmCode;
        this.farmName = farmName;
        this.addressText = addressText;
        this.status = "ACTIVE";
    }

}
