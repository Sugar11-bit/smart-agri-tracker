
package com.smat.backend.organization.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "organizations")
public class Organization {

    @Id
    private Long id;

    @Column(name = "org_code", nullable = false)
    private String orgCode;

    @Column(name = "org_name", nullable = false)
    private String orgName;

    @Column(nullable = false)
    private String status;

    protected Organization() {}

    public Long getId() {
        return id;
    }

    public String getStatus() {
        return status;
    }
}
