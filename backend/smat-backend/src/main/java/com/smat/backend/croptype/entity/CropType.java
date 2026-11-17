
package com.smat.backend.croptype.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "crop_types")
public class CropType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "crop_code", nullable = false, length = 40)
    private String cropCode;

    @Column(name = "crop_name", nullable = false, length = 100)
    private String cropName;

    @Column(name = "life_cycle", nullable = false, length = 20)
    private String lifeCycle;

    protected CropType() {
        // Constructor cho JPA
    }

    public Long getId() {
        return id;
    }

    public String getCropCode() {
        return cropCode;
    }

    public String getCropName() {
        return cropName;
    }

    public String getLifeCycle() {
        return lifeCycle;
    }
}
