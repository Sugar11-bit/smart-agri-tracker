
package com.smat.backend.membership.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "organization_memberships")
public class OrganizationMembership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organization_id", nullable = false)
    private Long organizationId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "role", nullable = false, length = 20)
    private String role;

    @Column(name = "is_active", nullable = false)
    private Boolean active;

    protected OrganizationMembership() {
    }

    public Long getId() {
        return id;
    }

    public Long getOrganizationId() {
        return organizationId;
    }

    public Long getUserId() {
        return userId;
    }

    public String getRole() {
        return role;
    }

    public Boolean getActive() {
        return active;
    }
}
