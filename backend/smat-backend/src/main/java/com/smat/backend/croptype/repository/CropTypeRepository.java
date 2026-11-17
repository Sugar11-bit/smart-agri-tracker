
package com.smat.backend.croptype.repository;

import com.smat.backend.croptype.entity.CropType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CropTypeRepository
        extends JpaRepository<CropType, Long> {

    List<CropType> findAllByOrderByCropNameAsc();
}
