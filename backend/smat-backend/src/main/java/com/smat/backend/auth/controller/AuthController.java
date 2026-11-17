
package com.smat.backend.auth.controller;

import com.smat.backend.auth.dto.*;
import com.smat.backend.auth.service.AuthMeService;
import com.smat.backend.auth.service.LoginService;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final LoginService loginService;
    private final AuthMeService authMeService;

    public AuthController(LoginService loginService, AuthMeService authMeService) {
        this.loginService = loginService;
        this.authMeService = authMeService;
    }

    @PostMapping("/login")
    public LoginResponse login(
            @Valid @RequestBody LoginRequest request) {

        return loginService.login(request);
    }

    @GetMapping("/me")
    public AuthMeResponse me(
            @AuthenticationPrincipal Jwt jwt) {
        return authMeService.getCurrentUser(jwt);
    }
}
