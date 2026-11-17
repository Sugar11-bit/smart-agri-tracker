
package com.smat.backend.plot.controller;

import com.smat.backend.plot.dto.*;
import com.smat.backend.plot.service.PlotService;

import jakarta.validation.Valid;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Profile("dev")
@RestController
@RequestMapping("/api/v1/dev/plots")
public class DevPlotController {

    private final PlotService service;

    public DevPlotController(PlotService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PlotResponse create(
            @RequestParam Long organizationId,
            @Valid @RequestBody CreatePlotRequest request) {
        return service.create(organizationId, request);
    }

    @GetMapping
    public List<PlotResponse> findByFarm(
            @RequestParam Long organizationId,
            @RequestParam Long farmId) {
        return service.findByFarm(organizationId, farmId);
    }
}
