
package com.smat.backend.assignment.controller;

import com.smat.backend.assignment.dto.MyAssignedPlotResponse;
import com.smat.backend.assignment.service.MyPlotsService;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/me/plots")
public class MyPlotsController {

    private final MyPlotsService service;

    public MyPlotsController(MyPlotsService service) {
        this.service = service;
    }

    @GetMapping
    public List<MyAssignedPlotResponse> findMine(
            @AuthenticationPrincipal Jwt jwt) {

        return service.getMyPlots(jwt);
    }
}
