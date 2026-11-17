
package com.smat.backend.planting.controller;

import com.smat.backend.planting.dto.*;
import com.smat.backend.planting.service.PlantingService;

import jakarta.validation.Valid;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Profile("dev")
@RestController
@RequestMapping("/api/v1/dev/plantings")
public class DevPlantingController {

    private final PlantingService service;

    public DevPlantingController(PlantingService service) {
        this.service = service;
    }
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PlantingResponse create(@RequestParam Long organizationId, @Valid @RequestBody CreatePlantingRequest request) {
        return service.create(organizationId, request);
    }

    @GetMapping
    public List<PlantingResponse> findByPlot(
            @RequestParam Long organizationId,
            @RequestParam Long plotId) {

        return service.findByPlot(organizationId, plotId);
    }
}
