package com.smat.backend.productioncycle.controller;

import com.smat.backend.productioncycle.dto.CreateProductionCycleRequest;
import com.smat.backend.productioncycle.dto.ProductionCycleResponse;
import com.smat.backend.productioncycle.service.ProductionCycleService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Profile("dev")
@RestController
@RequestMapping("/api/v1/dev/production-cycles")
public class DevProductionCycleController {
    private final ProductionCycleService service;
    public DevProductionCycleController(ProductionCycleService service) { this.service = service; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProductionCycleResponse create(@RequestParam @Positive Long organizationId,
                                          @Valid @RequestBody CreateProductionCycleRequest request) {
        return service.create(organizationId, request);
    }

    @GetMapping
    public List<ProductionCycleResponse> list(@RequestParam @Positive Long organizationId,
            @RequestParam @Positive Long plantingId) {
        return service.list(organizationId, plantingId);
    }
}
