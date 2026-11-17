
package com.smat.backend.farm.controller;

import com.smat.backend.farm.dto.FarmResponse;
import com.smat.backend.farm.service.FarmService;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

//
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import com.smat.backend.farm.dto.CreateFarmRequest;
import java.util.List;

@Profile("dev")
@RestController
@RequestMapping("/api/v1/dev/farms")
public class DevFarmController {

    private final FarmService service;

    public DevFarmController(FarmService service) {
        this.service = service;
    }

    @GetMapping
    public List<FarmResponse> list(
            @RequestParam Long organizationId
    ) {
        return service.findByOrganization(organizationId);
    }

    //Thêm sau
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FarmResponse create(
            @RequestParam Long organizationId,
            @Valid @RequestBody CreateFarmRequest request
    ) {
        return service.create(organizationId, request);
    }
}
