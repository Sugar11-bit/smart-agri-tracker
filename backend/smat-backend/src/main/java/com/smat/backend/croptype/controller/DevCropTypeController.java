
package com.smat.backend.croptype.controller;

import com.smat.backend.croptype.dto.CropTypeResponse;
import com.smat.backend.croptype.service.CropTypeService;

import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Profile("dev")
@RestController
@RequestMapping("/api/v1/dev/crop-types")
public class DevCropTypeController {

    private final CropTypeService service;

    public DevCropTypeController(CropTypeService service) {
        this.service = service;
    }

    @GetMapping
    public List<CropTypeResponse> findAll() {
        return service.findAll();
    }
}
