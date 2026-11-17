
package com.smat.backend.croptype.service;

import com.smat.backend.croptype.dto.CropTypeResponse;
import com.smat.backend.croptype.repository.CropTypeRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CropTypeService {

    private final CropTypeRepository repository;

    public CropTypeService(CropTypeRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CropTypeResponse> findAll() {
        return repository.findAllByOrderByCropNameAsc()
                .stream()
                .map(crop -> new CropTypeResponse(
                        crop.getId(),
                        crop.getCropCode(),
                        crop.getCropName(),
                        crop.getLifeCycle()
                ))
                .toList();
    }
}
