
package com.smat.backend.auth.service;

import com.smat.backend.auth.dto.*;
import com.smat.backend.user.entity.User;
import com.smat.backend.user.repository.UserRepository;
import com.smat.backend.membership.repository.OrganizationMembershipRepository;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Map;

@Service
public class LoginService {

    private final UserRepository userRepository;
    private final OrganizationMembershipRepository membershipRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;

    @Value("${smat.jwt.issuer}")
    private String issuer;

    @Value("${smat.jwt.access-token-minutes}")
    private long accessTokenMinutes;

    public LoginService(
            UserRepository userRepository,
            OrganizationMembershipRepository membershipRepository,
            PasswordEncoder passwordEncoder,
            JwtEncoder jwtEncoder) {

        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {

        User user = userRepository
                .findByUsername(request.username())
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.UNAUTHORIZED,
                                "Invalid username or password"
                        )
                );

        if (!Boolean.TRUE.equals(user.getActive())
                || !passwordEncoder.matches(
                request.password(),
                user.getPasswordHash()
        )) {

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid username or password"
            );
        }

        if (membershipRepository
                .findByUserIdAndActiveTrue(user.getId())
                .isEmpty()) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Account has no active membership"
            );
        }

        Instant now = Instant.now();
        Instant expiresAt =
                now.plusSeconds(accessTokenMinutes * 60);

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(String.valueOf(user.getId()))
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claims(c -> c.putAll(Map.of(
                        "username", user.getUsername()
                )))
                .build();

        JwsHeader header = JwsHeader
                .with(MacAlgorithm.HS256)
                .build();

        String token = jwtEncoder.encode(
                JwtEncoderParameters.from(header, claims)
        ).getTokenValue();

        return new LoginResponse(
                token,
                "Bearer",
                accessTokenMinutes * 60
        );
    }
}
