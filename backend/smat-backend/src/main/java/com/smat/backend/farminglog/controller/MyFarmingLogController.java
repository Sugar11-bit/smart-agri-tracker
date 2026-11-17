
package com.smat.backend.farminglog.controller;

import com.smat.backend.farminglog.dto.CreateFarmingLogRequest;
import com.smat.backend.farminglog.dto.FarmingLogResponse;
import com.smat.backend.farminglog.service.FarmingLogService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/me/farming-logs")
public class MyFarmingLogController {

    private final FarmingLogService service;

    public MyFarmingLogController(FarmingLogService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<FarmingLogResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateFarmingLogRequest request
    ) {
        var result = service.create(jwt, request);

        return ResponseEntity
                .status(
                        result.created()
                                ? HttpStatus.CREATED
                                : HttpStatus.OK
                )
                .body(result.log());
    }
}
