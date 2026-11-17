package com.smat.backend.auth;

import com.smat.backend.membership.entity.OrganizationMembership;
import com.smat.backend.membership.repository.OrganizationMembershipRepository;
import com.smat.backend.organization.entity.Organization;
import com.smat.backend.organization.repository.OrganizationRepository;
import com.smat.backend.user.entity.User;
import com.smat.backend.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.net.URI;
import java.net.http.*;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.profiles.active=dev", "spring.flyway.enabled=false", "smat.bootstrap.enabled=false"})
class AuthSecurityTests {
    @LocalServerPort int port;
    @Autowired JwtEncoder encoder;
    @Autowired PasswordEncoder passwords;
    @MockitoBean UserRepository users;
    @MockitoBean OrganizationMembershipRepository memberships;
    @MockitoBean OrganizationRepository organizations;
    private final HttpClient client = HttpClient.newHttpClient();
    private User user;

    @DynamicPropertySource
    static void jwtSecret(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String secret = Base64.getEncoder().encodeToString(bytes);
        registry.add("smat.jwt.secret", () -> secret);
    }

    @BeforeEach void activeAdmin() {
        user = mock(User.class);
        when(user.getId()).thenReturn(42L);
        when(user.getUsername()).thenReturn("test-admin");
        when(user.getFullName()).thenReturn("Test Admin");
        when(user.getActive()).thenReturn(true);
        when(user.getPasswordHash()).thenReturn(passwords.encode("test-password-only"));
        when(users.findById(42L)).thenReturn(Optional.of(user));
        when(users.findByUsername("test-admin")).thenReturn(Optional.of(user));
        var membership = mock(OrganizationMembership.class);
        when(membership.getOrganizationId()).thenReturn(7L);
        when(membership.getRole()).thenReturn("ADMIN");
        when(memberships.findByUserIdAndActiveTrue(42L)).thenReturn(List.of(membership));
        when(memberships.existsByOrganizationIdAndUserIdAndRoleAndActiveTrue(7L,42L,"ADMIN")).thenReturn(true);
        var org = mock(Organization.class);
        when(org.getStatus()).thenReturn("ACTIVE");
        when(organizations.findById(7L)).thenReturn(Optional.of(org));
    }

    String token(String subject, String issuer, Instant expiry) {
        var claims = JwtClaimsSet.builder().issuer(issuer).issuedAt(Instant.now().minusSeconds(600))
                .expiresAt(expiry).claim("test", true);
        if (subject != null) claims.subject(subject);
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims.build())).getTokenValue();
    }
    String validToken() { return token("42", "smat-backend", Instant.now().plusSeconds(120)); }
    HttpResponse<String> get(String path, String token) throws Exception {
        var builder = HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path));
        if (token != null) builder.header("Authorization", "Bearer "+token);
        return client.send(builder.GET().build(), HttpResponse.BodyHandlers.ofString());
    }
    HttpResponse<String> login(String username, String password) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+"/api/v1/auth/login"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString("{\"username\":\""+username+"\",\"password\":\""+password+"\"}"))
                .build();
        return client.send(request, HttpResponse.BodyHandlers.ofString());
    }
    @Test void unknownCredentialsAreUnauthorized() throws Exception { assertEquals(401, login("missing","wrong").statusCode()); }
    @Test void wrongPasswordIsUnauthorized() throws Exception { assertEquals(401, login("test-admin","wrong").statusCode()); }
    @Test void inactiveUserCannotLogin() throws Exception {
        when(user.getActive()).thenReturn(false);
        assertEquals(401,login("test-admin","test-password-only").statusCode());
    }
    @Test void loginWithoutActiveMembershipIsForbidden() throws Exception {
        when(memberships.findByUserIdAndActiveTrue(42L)).thenReturn(List.of());
        assertEquals(403,login("test-admin","test-password-only").statusCode());
    }
    @Test void realBcryptAndJwtLoginWorks() throws Exception {
        var response = login("test-admin","test-password-only");
        assertEquals(200,response.statusCode());
        var matcher = java.util.regex.Pattern.compile("\"accessToken\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find(),"Login must return a token");
        assertEquals(200,get("/api/v1/auth/me",matcher.group(1)).statusCode());
    }
    @Test void meDoesNotExposePasswordHash() throws Exception {
        var response=get("/api/v1/auth/me",validToken());
        assertEquals(200,response.statusCode());
        assertFalse(response.body().contains("password"));
        assertFalse(response.body().contains("$2"));
        assertTrue(response.body().contains("test-admin"));
    }
    @Test void missingTokenIsUnauthorized() throws Exception { assertEquals(401,get("/api/v1/auth/me",null).statusCode()); }
    @Test void tokenWithoutSubjectIsUnauthorized() throws Exception {
        assertEquals(401,get("/api/v1/auth/me",token(null,"smat-backend",Instant.now().plusSeconds(120))).statusCode());
    }
    @Test void nonNumericSubjectIsUnauthorized() throws Exception {
        assertEquals(401,get("/api/v1/auth/me",token("bad","smat-backend",Instant.now().plusSeconds(120))).statusCode());
    }
    @Test void expiredTokenIsUnauthorized() throws Exception {
        assertEquals(401,get("/api/v1/auth/me",token("42","smat-backend",Instant.now().minusSeconds(300))).statusCode());
    }
    @Test void wrongIssuerIsUnauthorized() throws Exception {
        assertEquals(401,get("/api/v1/auth/me",token("42","other",Instant.now().plusSeconds(120))).statusCode());
    }
    @Test void tamperedSignatureIsUnauthorized() throws Exception {
        String token=validToken();
        int start=token.lastIndexOf('.')+1;
        char replacement=token.charAt(start)=='A'?'B':'A';
        String tampered=token.substring(0,start)+replacement+token.substring(start+1);
        assertEquals(401,get("/api/v1/auth/me",tampered).statusCode());
    }
    @Test void adminIsAllowedInOwnOrganization() throws Exception {
        assertEquals(200,get("/api/v1/admin/access-test?organizationId=7",validToken()).statusCode());
    }
    @Test void adminCannotAccessOtherOrganization() throws Exception {
        assertEquals(403,get("/api/v1/admin/access-test?organizationId=8",validToken()).statusCode());
    }
    @Test void suspendedOrganizationIsForbidden() throws Exception {
        var org=mock(Organization.class);
        when(org.getStatus()).thenReturn("SUSPENDED");
        when(organizations.findById(7L)).thenReturn(Optional.of(org));
        assertEquals(403,get("/api/v1/admin/access-test?organizationId=7",validToken()).statusCode());
    }
    @Test void inactiveUserTokenIsUnauthorized() throws Exception {
        when(user.getActive()).thenReturn(false);
        assertEquals(401,get("/api/v1/auth/me",validToken()).statusCode());
    }
    @Test void devAdminPageLoads() throws Exception { assertEquals(200,get("/admin-smat.html",null).statusCode()); }
    @Test void malformedLoginJsonIsBadRequest() throws Exception {
        var request=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+"/api/v1/auth/login"))
                .header("Content-Type","application/json").POST(HttpRequest.BodyPublishers.ofString("{bad")).build();
        assertEquals(400,client.send(request,HttpResponse.BodyHandlers.discarding()).statusCode());
    }
    @Test void malformedDevJsonIsBadRequest() throws Exception {
        var request=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+"/api/v1/dev/farms?organizationId=7"))
                .header("Content-Type","application/json").POST(HttpRequest.BodyPublishers.ofString("{bad")).build();
        assertEquals(400,client.send(request,HttpResponse.BodyHandlers.discarding()).statusCode());
    }
    @Test void directErrorPathStillRequiresAuthentication() throws Exception {
        assertEquals(401,get("/error",null).statusCode());
    }
    @Test void revokedAdminMembershipIsForbidden() throws Exception {
        when(memberships.existsByOrganizationIdAndUserIdAndRoleAndActiveTrue(7L,42L,"ADMIN")).thenReturn(false);
        assertEquals(403,get("/api/v1/admin/access-test?organizationId=7",validToken()).statusCode());
    }
}
